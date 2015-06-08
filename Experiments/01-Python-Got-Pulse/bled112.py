#!/usr/bin/python

# 
# Copyright (c) 2015, Seraphim Sense Ltd.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions
#    and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of
#    conditions and the following disclaimer in the documentation and/or other materials provided
#    with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to
#    endorse or promote products derived from this software without specific prior written
#    permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 

import threading
import serial.tools.list_ports
import argparse
import array
import time
import serial
import struct
import logging

# Set to 1 to enable debug prints of raw UART messages
DEBUG = 0

def makeUuidFromArray(uint8array):
    uuid = ''
    for i in reversed(uint8array):
        uuid += '%02X' % (i)
    return uuid

def makeHexFromArray(uint8array):
    h = ''
    for i in uint8array:
        if i < 256:
            h += '%02X' % (i)
        else:
            ht = ('%04X' % (i))
            h += ''.join([ht[2:], ht[0:2]])
    return h

class Uint16:
    def __init__(self, value=0):
        self.value = value
    
    def serialize(self):
        return struct.unpack('2B', struct.pack('H', self.value))
        
    def deserialize(self, packed):
        # self.value = struct.pack('H', struct.unpack('2B', *packed))
        self.value = packed[0] + packed[1] * 256
        return self.value

class Uint8Array:
    def __init__(self, theArray=[]):
        self.array = theArray
        
    def serialize(self):
        return [len(self.array)] + list(self.array)
        
    def deserialize(self, packed):
        length = packed[0]
        self.array = []
        if length:
            self.array = packed[1:]
            if length != len(self.array):
                raise BleValueError()
        return self.array
        
class BleMessage:
    """Encapsulate low level BGAPI message containing header and payload."""
    def __init__(self, header, payload):
        assert(len(header) == 4)
        self.header = header
        self.payload = payload
        
    def __str__(self):
        s = ''
        for b in self.header: s += '%02X' % (b) + ' '
        s += ' : '
        for b in self.payload: s += '%02X' % (b) + ' '
        return s
        
    def equalsByHeader(self, other):
        """Compare messages using only the header bytes, excluding byte 1
        (payload length).
        """
        h1 = self.header
        h2 = other.header
        return h1[0] == h2[0] and h1[2] == h2[2] and h1[3] == h2[3]

class BleCommand(BleMessage):
    def __init__(self, header, payload=[]):
        BleMessage.__init__(self, header, payload)

class BleEvent(BleMessage):
    def __init__(self, header, payload=[]):
        BleMessage.__init__(self, header, payload)
        
class BleResponse(BleMessage):
    def __init__(self, header, payload=[]):
        BleMessage.__init__(self, header, payload)

class HelloResponse(BleResponse):
    def __init__(self, payload=[]):
        BleResponse.__init__(self, (0x00, 0x00, 0x00, 0x01), payload)

class GetInfoCommand(BleCommand):
    def __init__(self):
        BleCommand.__init__(self, (0x00, 0x00, 0x00, 0x08))

class HelloCommand(BleCommand):
    def __init__(self):
        BleCommand.__init__(self, (0, 0, 0, 1))

class SystemResetCommand(BleCommand):
    def __init__(self):
        BleCommand.__init__(self, (0, 1, 0, 0), [0])

class SystemBootEvent(BleEvent):
    def __init__(self, payload=[]):
        BleEvent.__init__(self, (0x80, 0x0C, 0x00, 0x00), payload)

class SmBondingFailEvent(BleEvent):
    def __init__(self, payload=[]):
        BleEvent.__init__(self, (0x80, 0x03, 0x05, 0x01), payload)

class AttClientIndicated(BleEvent):
    def __init__(self, payload=[]):
        BleEvent.__init__(self, (0x80, 0x03, 0x04, 0x00), payload)

class AttClientProcedureCompleted(BleEvent):
    def __init__(self, payload=[]):
        BleEvent.__init__(self, (0x80, 0x00, 0x04, 0x01), payload)
        if payload:
            self.connection = payload[0]
            self.result = Uint16().deserialize(payload[1:3])
            self.chrHandle = Uint16().deserialize(payload[3:5])
        
class ConnectionDisconnectCommand(BleCommand):
    def __init__(self, connection):
        BleCommand.__init__(self, (0x00, 0x01, 0x03, 0x00), [connection])

class ConnectionDisconnectResponse(BleResponse):
    def __init__(self, payload=[]):
        BleMessage.__init__(self, (0x00, 0x03, 0x03, 0x00), payload)

class ConnectionDisconnectedEvent(BleEvent):
    def __init__(self, payload=[]):
        BleEvent.__init__(self, (0x80, 0x00, 0x03, 0x04), payload)
        
class ConnectDirectCommand(BleCommand):
    def __init__(self, address):
        addr_type = [0]
        conn_interval_min = Uint16(16).serialize() # Units of 1.25ms
        conn_interval_max = Uint16(32).serialize() # Units of 1.25ms
        timeout = Uint16(100).serialize() # Units of 10ms - was 10
        latency = Uint16(0).serialize()
        payload = list(address)
        payload.extend(addr_type)
        payload.extend(conn_interval_min)
        payload.extend(conn_interval_max)
        payload.extend(timeout)
        payload.extend(latency)
        BleCommand.__init__(self, (0x00, 0x00, 0x06, 0x03), payload)

class ConnectDirectResponse(BleResponse):
    def __init__(self, payload=[]):
        BleMessage.__init__(self, (0x00, 0x00, 0x06, 0x03), payload)

class ConnectionStatusEvent(BleEvent):
    def __init__(self,  payload=[]):
        BleEvent.__init__(self, (0x80, 0x00, 0x03, 0x00), payload)
        if payload:
            assert(len(payload) == 16)
            self.connection = payload[0]
            self.flags = payload[1]
            self.address = payload[2:8]
            self.bonding = payload[15]

class GetConnectionsCommand(BleCommand):
    def __init__(self):
        BleCommand.__init__(self, (0x00, 0x00, 0x00, 0x06))
        
class GetConnectionsResponse(BleResponse):
    def __init__(self, payload=[]):
        BleMessage.__init__(self, (0x00, 0x01, 0x00, 0x06), payload)
        
class GetConnectionsEvent(BleEvent):
    def __init__(self, payload=[]):
        if len(payload) >= 16:
            self.connection    = self._payload[0]
            self.flags         = self._payload[1]
            self.bd_addr       = makeHexFromArray(self._payload[2:8])[::-1]
            self.address_type  = self._payload[8]
            self.conn_interval = makeHexFromArray(self._payload[9:11])[::-1]
            self.timeout       = makeHexFromArray(self._payload[11:13])[::-1]
            self.latency       = makeHexFromArray(self._payload[13:15])[::-1]
            self.bonding       = self._payload[15]
        BleMessage.__init__(self, (0x80, 0x10, 0x03, 0x00), payload)
        
class GetRssiCommand(BleCommand):
    def __init__(self, connection):
        BleCommand.__init__(self, (0x00, 0x01, 0x03, 0x01), [connection])

class GetRssiResponse(BleResponse):
    def __init__(self, payload=[]):
        BleMessage.__init__(self, (0x00, 0x02, 0x03, 0x01), payload)
        if payload:
            self.connection = self._payload[0]
            self.signalStr = self._payload[1]

class AttClientFindInformationCommand(BleCommand):
    def __init__(self, connection, start, end):
        payload = [connection]
        payload.extend(Uint16(start).serialize())
        payload.extend(Uint16(end).serialize())
        BleCommand.__init__(self, [0x00, 0x00, 0x04, 0x03], payload)

class AttClientFindInformationResponse(BleResponse):
    def __init__(self, payload=[]):
        BleResponse.__init__(self, (0x00, 0x00, 0x04, 0x03), payload)

class AttClientFindInformationFoundEvent(BleResponse):
    def __init__(self, payload=[]):
        BleResponse.__init__(self, (0x80, 0x00, 0x04, 0x04), payload)
        if len(payload) >= 4:
            self.connection = payload[0]
            self.chrHandle = Uint16().deserialize(payload[1:3])
            self.uuid = makeUuidFromArray(Uint8Array().deserialize(payload[3:]))
                
class AttClientReadByHandleCommand(BleCommand):
    def __init__(self, connection, handle):
        payload = [connection]
        payload.extend(Uint16(handle).serialize())
        BleCommand.__init__(self, (0x00, 0x00, 0x04, 0x04), payload)

class AttClientReadByHandleResponse(BleResponse):
    def __init__(self, payload=[]):
        BleResponse.__init__(self, (0x00, 0x00, 0x04, 0x04), payload)

class FindByTypeValueCommand(BleCommand):
    def __init__(self, connection, start, end, uuid, value):
        payload = [connection]
        payload.extend(Uint16(start).serialize())
        payload.extend(Uint16(end).serialize())
        payload.extend(Uint16(uuid).serialize())
        payload.extend(Uint8Array(value).serialize())
        BleCommand.__init__(self, (0x00, 0x08, 0x04, 0x00), payload)

class FindByTypeValueResponse(BleResponse):
    def __init__(self, payload=[]):
        BleResponse.__init__(self, (0x00, 0x00, 0x04, 0x00), payload)

class ReadByGroupTypeCommand(BleCommand):
    def __init__(self, connection, start, end, uuid):
        payload = [connection]
        payload.extend(Uint16(start).serialize())
        payload.extend(Uint16(end).serialize())
        payload.extend(Uint8Array(uuid).serialize())
        BleCommand.__init__(self, (0x00, 0x00, 0x04, 0x01), payload)

class ReadByGroupTypeResponse(BleResponse):
    def __init__(self, payload=[]):
        BleResponse.__init__(self, (0x00, 0x00, 0x04, 0x01), payload)
        
class AttClientGroupFoundEvent(BleEvent):
    def __init__(self, payload=[]):
        BleEvent.__init__(self, (0x80, 0x00, 0x04, 0x02), payload)
        if len(payload) > 5:
            self.connection = payload[0]
            self.start = Uint16().deserialize(payload[1:3])
            self.end = Uint16().deserialize(payload[3:5])
            self.uuid = makeUuidFromArray(Uint8Array().deserialize(payload[5:]))

class AttClientReadMultipleCommand(BleCommand):
    def __init__(self, connection, handles):
        payload = [connection]
        for handle in handles:
            self._payload.extend(Uint16(handle).serialize())
        BleCommand.__init__(self, (0x00, 0x02, 0x04, 0x0B), payload)

class AttClientReadMultipleResponse(BleResponse):
    def __init__(self, payload=[]):
        if payload:
            self.connection = payload[0]
            self.attHandles = payload[1:]
        BleResponse.__init__(self, (0x00, 0x03, 0x04, 0x0B), payload)

class AttClientAttributeWriteCommand(BleCommand):
    def __init__(self, connection, handle, data):
        payload = [connection]
        payload.extend(Uint16(handle).serialize())
        payload.extend(Uint8Array(data).serialize())
        BleCommand.__init__(self, (0x00, 0x00, 0x04, 0x05), payload)

class AttClientAttributeWriteResponse(BleResponse):
    def __init__(self, payload=[]):
        BleResponse.__init__(self, (0x00, 0x00, 0x04, 0x05), payload)
        
class AttClientAttributePrepareWriteCommand(BleCommand):
    def __init__(self, connection, handle, offset, data):
        payload = [connection]
        payload.extend(Uint16(handle).serialize())
        payload.extend(Uint16(offset).serialize())
        payload.extend(Uint8Array(data).serialize())
        BleCommand.__init__(self, (0x00, 0x00, 0x04 , 0x09), payload)

class AttClientAttributePrepareWriteResponse(BleResponse):
    def __init__(self, payload=[]):
        BleResponse.__init__(self, (0x00, 0x00, 0x04, 0x09), payload)

class AttClientExecuteWriteCommand(BleCommand):
    def __init__(self, connection):
        BleCommand.__init__(self, (0x00, 0x02, 0x04, 0x0A), [connection, 1])

class AttClientExecuteWriteCommandResponse(BleResponse):
    def __init__(self, payload=[]):
        BleResponse.__init__(self, (0x00, 0x00, 0x04, 0x0A), payload)
        if payload:
            self.connection = payload[0]
            self.result = payload[0] + payload[1] * 256

class AttClientAttributeValueEvent(BleEvent):
    def __init__(self, payload=[]):
        BleEvent.__init__(self, (0x80, 0x00, 0x04, 0x05), payload)
        if payload:
            self.connection = payload[0]
            self.attHandle = Uint16().deserialize(payload[1:3])
            self.type = payload[3]
            self.data = payload[5:]

class AttClientReadMultipleResponseEvent(BleEvent):
    def __init__(self, payload=[]):
        BleEvent.__init__(self, (0x80, 0x02, 0x04, 0x06), [])
        if payload:
            self.attValue = self.payload[5:]
            self.attHandle = Uint16().deserialize(self.payload[1:3])

class ProtocolErrorEvent(BleEvent):
    def __init__(self, payload=[]):
        BleEvent.__init__(self, (0x80, 0x02, 0x00, 0x06), payload)
        if payload:
            self.reason = Uint16().deserialize(payload[0:2])

def makeBleMessage(header, payload):
    """Factory method for identifying incoming BLE messages and creating the
    correct message subclass instance.
    """
    
    # All the supported messages are listed here. Keep ABC-sorted for neatness.
    lookup = {
        AttClientAttributePrepareWriteResponse().header : AttClientAttributePrepareWriteResponse,
        AttClientAttributeValueEvent().header : AttClientAttributeValueEvent,
        AttClientAttributeWriteResponse().header : AttClientAttributeWriteResponse,
        AttClientExecuteWriteCommandResponse().header : AttClientExecuteWriteCommandResponse,
        AttClientFindInformationFoundEvent().header : AttClientFindInformationFoundEvent,
        AttClientFindInformationResponse().header : AttClientFindInformationResponse,
        AttClientGroupFoundEvent().header : AttClientGroupFoundEvent,
        AttClientProcedureCompleted().header : AttClientProcedureCompleted,
        AttClientReadByHandleResponse().header : AttClientReadByHandleResponse,
        ConnectDirectResponse().header : ConnectDirectResponse,
        ConnectionDisconnectedEvent().header : ConnectionDisconnectedEvent,
        ConnectionStatusEvent().header : ConnectionStatusEvent,
        FindByTypeValueResponse().header : FindByTypeValueResponse,
        ReadByGroupTypeResponse().header : ReadByGroupTypeResponse,
    }
    # Clear payload length to allow identification by header
    cleanHeader = tuple([header[0], 0, header[2], header[3]])
    ctor = lookup.get(cleanHeader)
    if ctor:
        return ctor(payload)
    else:
        msg = BleMessage(header, payload)
        print 'Unknown message %s' % str(msg)
        return msg

class Bled112Com(threading.Thread):
    HEADER_SIZE = 4
    PAYLOAD_LENGTH_OFFSET = 1
    WAIT_TIMEOUT = 2
    
    def findPort(self):
        ports = list(serial.tools.list_ports.grep('Bluegiga Bluetooth Low Energy'))
        if not ports or not ports[0]:
            raise RuntimeError('BLED112 serial port not found')
        return ports[0][0]
        
    def __init__(self, serialPort=None):
        comName = serialPort or self.findPort()
        self.serialDevice = serial.Serial(port=comName,
                                          baudrate=115200,
                                          timeout=0.001,
                                          stopbits=serial.STOPBITS_TWO,
                                          rtscts=True)
        threading.Thread.__init__(self)
        self.incoming = []
        self.isTerminated = False
        self.listener = None
        self.terminate = False
        return
        
    @staticmethod
    def echoMessage(message, prefix=''):
        s = str(time.time()) + ' ' + prefix
        for b in message.header: s += '%02X' % (b) + ' '
        if message.payload:
            s += ' : '
            for b in message.payload: s += '%02X' % (b) + ' '
        print s
        return
        
    def send(self, message):
        hdr = message.header
        # Update payload length to the actual size
        message.header = [hdr[0], len(message.payload), hdr[2], hdr[3]]
        if DEBUG: self.echoMessage(message, 'TX:')
        self.serialDevice.write(array.array('B', message.header).tostring())
        if len(message.payload):
            self.serialDevice.write(array.array('B', message.payload).tostring())
        self.serialDevice.flush()
        return

    def readMessage(self):
        self.incoming.extend(self.serialDevice.read())
        if len(self.incoming) < self.HEADER_SIZE: return
        payloadLength = ord(self.incoming[self.PAYLOAD_LENGTH_OFFSET])
        if self.HEADER_SIZE + payloadLength > len(self.incoming): return
        header = map(ord, self.incoming[0:self.HEADER_SIZE])
        del self.incoming[0:self.HEADER_SIZE]
        payload = []
        if payloadLength:
            payload = map(ord, self.incoming[0:payloadLength])
            del self.incoming[0:payloadLength]
        msg = makeBleMessage(header, payload)
        if DEBUG: self.echoMessage(msg, 'RX:')
        return msg

    def reset(self):
        self.send(SystemResetCommand())
        return
        
    def run(self):
        logging.info('BLED112 thread started')
        while True:
            m = self.readMessage()
            if m and self.listener:
                self.listener.onMessage(m)
            if self.terminate:
                print 'BLED112 thread stopped'
                exit()
        return
        
    def close(self): self.terminate = True
 