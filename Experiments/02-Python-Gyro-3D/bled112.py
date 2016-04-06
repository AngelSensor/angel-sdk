#!/usr/bin/python

#
# Copyright (c) 2016, Seraphim Sense Ltd.
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
import json
import os

# Set to 1 to enable debug prints of raw UART messages
DEBUG = 0

GATT_FILE = 'gatt.tmp'

class GattType:
    SERVICE        = 0x2800
    CHARACTERISTIC = 0x2803

    class Str:
        SERVICE        = '2800'
        CHARACTERISTIC = '2803'

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

def makeStringFromArray(uint8array):
    s = ''
    # print uint8array
    for i in uint8array:
        if i == 0: break
        else: s += unichr(i)
    return s


class Uint16:
    def __init__(self, value=0):
        self.value = value
    
    def serialize(self):
        return struct.unpack('2B', struct.pack('H', self.value))
        
    def deserialize(self, packed):
        # self.value = struct.pack('H', struct.unpack('2B', *packed))
        self.value = packed[0] + (packed[1] << 8)
        return self.value

class Uint32:
    def __init__(self, value=0):
        self.value = value
    
    def serialize(self):
        return struct.unpack('4B', struct.pack('H', self.value))
        
    def deserialize(self, packed):
        # self.value = struct.pack('H', struct.unpack('2B', *packed))
        self.value = packed[0] + (packed[1] << 8) + (packed[2] << 16) + (packed[3] << 24)
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
        BleMessage.__init__(self, (0x00, 0x00, 0x00, 0x06), payload)
        
class GetConnectionsEvent(BleEvent):
    def __init__(self, payload=[]):
        if len(payload) >= 16:
            self.connection    = self.payload[0]
            self.flags         = self.payload[1]
            self.bd_addr       = makeHexFromArray(self.payload[2:8])[::-1]
            self.address_type  = self.payload[8]
            self.conn_interval = makeHexFromArray(self.payload[9:11])[::-1]
            self.timeout       = makeHexFromArray(self.payload[11:13])[::-1]
            self.latency       = makeHexFromArray(self.payload[13:15])[::-1]
            self.bonding       = self.payload[15]
        BleMessage.__init__(self, (0x80, 0x00, 0x03, 0x00), payload)
        
class GetRssiCommand(BleCommand):
    def __init__(self, connection):
        BleCommand.__init__(self, (0x00, 0x00, 0x03, 0x01), [connection])

class GetRssiResponse(BleResponse):
    def __init__(self, payload=[]):
        BleMessage.__init__(self, (0x00, 0x00, 0x03, 0x01), payload)
        if payload:
            self.connection = self.payload[0]
            self.rssi       = self.payload[1]

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
        payload.extend(Uint8Array(Uint16(uuid).serialize()).serialize())
        BleCommand.__init__(self, (0x00, 0x00, 0x04, 0x01), payload)

class ReadByGroupTypeResponse(BleResponse):
    def __init__(self, payload=[]):
        BleResponse.__init__(self, (0x00, 0x00, 0x04, 0x01), payload)

class ReadByTypeCommand(BleCommand):
    def __init__(self, connection, start, end, uuid):
        payload = [connection]
        payload.extend(Uint16(start).serialize())
        payload.extend(Uint16(end).serialize())
        payload.extend(Uint8Array(Uint16(uuid).serialize()).serialize())
        BleCommand.__init__(self, (0x00, 0x00, 0x04, 0x02), payload)

class ReadByTypeResponse(BleResponse):
    def __init__(self, payload=[]):
        BleResponse.__init__(self, (0x00, 0x00, 0x04, 0x02), payload)
        
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
            self.payload.extend(Uint16(handle).serialize())
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
        GetRssiResponse().header : GetRssiResponse,
        ReadByGroupTypeResponse().header : ReadByGroupTypeResponse,
        ReadByTypeResponse().header : ReadByTypeResponse,
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
                                          timeout=0.1,
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
        logging.debug(s)
        return
        
    def send(self, message):
        hdr = message.header
        # Update payload length to the actual size
        message.header = [hdr[0], len(message.payload), hdr[2], hdr[3]]
        if DEBUG:
            self.echoMessage(message, 'TX:')
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
                print '\r\n*** BLED112 thread stopped ***\r\n'
                exit()
        return
        
    def close(self): self.terminate = True
 
class BleManager:
    errors = {
        0x83: 'Client Configuration Descriptor not configured'
    }

    def __init__(self, com, mac):
        self.reactions = {
            AttClientAttributeValueEvent : self.onProcedureEvent,
            AttClientFindInformationFoundEvent: self.onProcedureEvent,
            AttClientGroupFoundEvent : self.onProcedureEvent,
            ConnectionDisconnectedEvent : self.onConnectionDisconnectedEvent,
            ConnectionStatusEvent : self.onConnectionStatusEvent,
        }
        self.connection = BleConnection(mac)
        self.com = com
        self.expectedMessage = None
        com.listener = self
        self.localTimeout = 1
        self.remoteTimeout = 10
        self.gatt = Gatt()
        self.procedureEvents = []

    def prepGatt(self):
        if os.path.exists(GATT_FILE):
            self.gatt.load(GATT_FILE)
        else:
            self.enumerateGatt()
            self.gatt.save(GATT_FILE)
        
    # Called by BLED112 thread
    def onMessage(self, message):
        if self.expectedMessage and message.__class__ == self.expectedMessage.__class__:
            self.actualMessage = message
            # Keep this last since various waitXXX methods loop on this variable
            self.expectedMessage = None
        else:
            reaction = self.reactions.get(message.__class__)
            if reaction: reaction(message)
        
    def onConnectionDisconnectedEvent(self, message):
        logging.info('Disconnected')
        self.connection.id = None
        
    def onConnectionStatusEvent(self, message):
        self.connection.id = message.connection
    
    def waitForMessage(self, message, timeout):
        assert message
        t = Timeout(timeout)
        self.expectedMessage = message
        self.actualMessage = None
        while self.expectedMessage and not t.isExpired(): pass
        return self.actualMessage
        
    def waitLocal(self, message):
        msg = self.waitForMessage(message, self.localTimeout)
        if not msg: raise BleLocalTimeout()
        return msg
        
    def waitRemote(self, message, customTimeout=None):
        timeout = customTimeout if customTimeout else self.remoteTimeout
        msg = self.waitForMessage(message, timeout)
        if not msg: raise BleRemoteTimeout()
        return msg
        
    def connect(self):
        logging.info('Connecting to %s' % macString(self.connection.address))
        self.com.send(ConnectDirectCommand(self.connection.address))
        self.waitLocal(ConnectDirectResponse())
        try:
            msg = self.waitRemote(ConnectionStatusEvent())
        except BleRemoteTimeout:
            logging.error('Failed connecting to %s' % macString(self.connection.address))
            raise
        self.connection.id = msg.connection
        
    def writeAttribute(self, uuid, data):
        logging.debug('Write attribute %s = %s' % (uuid, str(data)))
        handle = gattHandles[uuid]
        return self.writeAttributeByHandle(handle, data)
        
    def writeAttributeByHandle(self, handle, data):
        self.com.send(\
            AttClientAttributeWriteCommand(self.connection.id,
                                           handle,
                                           data))
        reply = self.waitLocal(AttClientAttributeWriteResponse())
        if not self.completeProcedure():
            raise BleProcedureFailure('Write attribute by handle failed')
        return reply
        
    def completeProcedure(self):
        msg = self.waitRemote(AttClientProcedureCompleted())
        self.parseError(msg.result & 0xFF, 'Procedure completed')
        return msg.result == 0
    
    def configClientCharacteristic(self, service, characteristic, notify=False, indicate=False):
        NOTIFY_ENABLE = 1
        INDICATE_ENABLE = 2
        flags = 0
        if notify: flags = flags | NOTIFY_ENABLE
        if indicate: flags = flags | INDICATE_ENABLE
        handle = self.gatt.getHandle(service, characteristic, '2902') # CCCD
        logging.info('Set CCCD [%s, %s] for %s / %s' % (notify, indicate, service, characteristic))
        return self.writeAttributeByHandle(handle, [flags])
        
    def isConnected(self): return self.connection.id is not None
    
    def send(self, message): self.com.send(message)
    
    def restartProcedure(self):
        self.procedureEvents = []
        
    def waitValue(self, handle):
        t = Timeout(self.remoteTimeout)
        event = None
        while True:
            event = self.waitRemote(AttClientAttributeValueEvent())
            if event and event.attHandle == handle: break
            if t.isExpired():
                raise BleRemoteTimeout()
        return event
        
    def prepareWrite(self, uuid, chunks):
        logging.debug('Prepare write %s' % uuid)
        handle = self.connection.handleByUuid(uuid)
        offset = 0
        for chunk in chunks:
            self.com.send(\
                AttClientAttributePrepareWriteCommand( \
                    self.connection.id,
                    handle,
                    offset,
                    chunk))
            self.waitLocal(AttClientAttributePrepareWriteResponse())
            self.completeProcedure()
            offset += len(chunk)
        
    def executeWrite(self):
        logging.debug('Execute write')
        self.com.send(AttClientExecuteWriteCommand(self.connection.id))
        self.waitLocal(AttClientExecuteWriteCommandResponse())
        self.completeProcedure()

    def readAttribute(self, handle):
        logging.info('Reading attribute %u' % handle)
        self.com.send(AttClientReadByHandleCommand(self.connection.id, handle))
        self.waitLocal(AttClientReadByHandleResponse())
        return self.waitValue(handle)
        
    def readByGroupType(self, start, end, uuid):
        self.restartProcedure()
        self.com.send(ReadByGroupTypeCommand(self.connection.id, start, end, uuid))
        self.waitLocal(ReadByGroupTypeResponse())
        self.completeProcedure()
        return self.procedureEvents

    def readByType(self, start, end, uuid):
        self.restartProcedure()
        self.com.send(ReadByTypeCommand(self.connection.id, start, end, uuid))
        self.waitLocal(ReadByTypeResponse())
        self.completeProcedure()
        return self.procedureEvents
        
    def onAttClientGroupFoundEvent(self, message):
        self.groups[message.uuid] = AttributeGroup(message.uuid, message.start, message.end)
        
    def findInformation(self, start, end):
        self.restartProcedure()
        self.com.send(AttClientFindInformationCommand(self.connection.id, start, end))
        self.waitLocal(AttClientFindInformationResponse())
        self.completeProcedure()
        return self.procedureEvents

    def onProcedureEvent(self, message):
        self.procedureEvents.append(message)

    def addReaction(self, msgClass, reaction):
        self.reactions[msgClass] = reaction
        
    def enumerateGatt(self):
        def extractCharacteristics(allHandles, uuidByHandle):
            characteristics = []
            descriptors = []
            # Traverse handle numbers bottom up to split the list of all handles
            # into descriptor groups by characteristic
            for handle in reversed(sorted(allHandles)):
                descriptors.append(GattDescriptor(handle, uuidByHandle[handle]))
                # Declaration descriptor 2803 always starts a new characteristic
                if uuidByHandle[handle] == GattType.Str.CHARACTERISTIC:
                    characteristics.append(GattCharacteristic(descriptors))
                    descriptors = []
            return characteristics
        
        # Find service groups first
        for event in self.readByGroupType(0x0001, 0xFFFF, GattType.SERVICE):
            # Expecting AttClientGroupFoundEvent
            self.gatt.addService(GattService(event.uuid, event.start, event.end))
            
        # Find characteristics for each service
        for service in self.gatt.services.itervalues():
            # Request all existing descriptors in this service
            allHandles = []
            uuidByHandle = {}
            for event in self.findInformation(service.start, service.end):
                # Expecting AttClientFindInformationFoundEvent
                allHandles.append(event.chrHandle)
                uuidByHandle[event.chrHandle] = event.uuid
                
            for ch in extractCharacteristics(allHandles, uuidByHandle):
                service.addCharacteristic(ch)
                
    def parseError(self, errorCode, prefix=''):
        if errorCode == 0:
            if prefix: logging.debug(prefix)
        else:
            suffix = self.errors[errorCode] if errorCode in self.errors else 'Unknown error code % u' % errorCode
            if prefix:
                logging.error('%s, %s' % (prefix, suffix))
            else:
                logging.error(suffix)
                
    def getEvent(self):
        if len(self.procedureEvents) > 0:
            ev = self.procedureEvents[0]
            del self.procedureEvents[0]
            return ev
            
class Timeout:
    """Simplify timeout interval management"""
    def __init__(self, interval):
        self.end = time.time() + interval
        
    def isExpired(self): 
        return time.time() >= self.end
        
# Custom BLED112 exceptions
class BleException(Exception): pass
class BleProcedureFailure(BleException): pass
class BleLocalTimeout(BleException): pass
class BleRemoteTimeout(BleException): pass
class BleValueError(BleException): pass

class BleConnection:
    def __init__(self, mac=None):
        self.id = None
        self.address = mac
        self.groups = {}
        self.uuidsByHandle = {}
        
    def addCharacteristic(self, uuid, handle):
        self.descriptors[uuid] = handle
        self.uuidsByHandle[handle] = uuid

class AttributeGroup:
    """Encapsulate a group of GATT attribute/descriptor handles.
    uuid -- UUID of the containing characteristic for the group
    start -- first handle in the group
    end -- last handle in the group
    """
    def __init__(self, uuid=None, start=None, end=None):
        self.uuid = uuid
        self.start = start
        self.end = end
        self.cccd = None

def macString(mac):
    return '%02X:%02X:%02X:%02X:%02X:%02X' % (mac[0], mac[1], mac[2], mac[3], mac[4], mac[5])

class GattDescriptor:
    def __init__(self, handle, uuid):
        self.handle = handle
        self.uuid = uuid
        
class GattCharacteristic:
    def __init__(self, descriptors):
        self.descriptors = {}
        for d in descriptors:
            self.addDescriptor(d)
            
        # Find the actual characteristic value
        for d in descriptors:
            if d.uuid == GattType.Str.CHARACTERISTIC:
                declarationHandle = d.handle
                break
        assert declarationHandle
        
        for d in descriptors:
            if d.handle == declarationHandle + 1:
                self.uuid = d.uuid
                self.handle = d.handle
                break
        
    def addDescriptor(self, descriptor):
        self.descriptors[descriptor.uuid] = descriptor
        
class GattService(AttributeGroup):
    def __init__(self, uuid, start, end):
        AttributeGroup.__init__(self, uuid, start, end)
        self.characteristics = {}
        
    def addCharacteristic(self, ch):
        self.characteristics[ch.uuid] = ch
        
class Gatt:
    def __init__(self):
        self.services = {}

    def addService(self, service):
        self.services[service.uuid] = service
        
    def getHandle(self, service, characteristic, descriptor=None):
        service = service.upper()
        characteristic = characteristic.upper()
        ch = self.services[service].characteristics[characteristic]
        if not descriptor:
            return ch.handle
        else:
            return ch.descriptors[descriptor].handle
    
    def assertUuidExists(self, service, characteristic=None, descriptor=None):
        """
        Confirm the specified service, characteristic or descriptor UUID was 
        found during GATT enumeration.
        :param service: desired service UUID.
        :param characteristic: UUID. Service must also be specified.
        :param descriptor: UUID. Service and characteristic must also be specified.
        :return: None
        """
        service = service.upper()
        assert service in self.services
        if characteristic:
            characteristic = characteristic.upper()
            assert characteristic.upper() in self.services[service].characteristics
        if descriptor:
            assert characteristic # Must specify characteristic to check descriptor
            assert descriptor.upper() in self.services[service].characteristics[characteristic].descriptors
            
    def __str__(self):
        endl = '\n'
        tab = '    '
        sub = ''
        s = ''
        for uuid, service in self.services.iteritems():
            s += 'service uuid %s start %u end %u' % (uuid, service.start, service.end)
            s += endl
            for uuid, ch in service.characteristics.iteritems():
                s += tab + sub + 'char ' + uuid + endl
                for descriptor in ch.descriptors.itervalues():
                    s += tab + tab + sub + 'desc ' + descriptor.uuid + \
                         tab + str(descriptor.handle) + endl
        return s

    def save(self, filename):
        with open(filename, 'w') as outfile:
            outfile.write('%s' % self)
        
    def load(self, filename):
        # TODO: refactor save/load
        with open(filename, 'r') as infile:
            for line in infile:
                tokens = line.strip().split()
                if tokens[0] == 'service':
                    assert(len(tokens) == 7)
                    # Close the previous descriptor group
                    if 'descriptors' in locals() and descriptors:
                        service.addCharacteristic(GattCharacteristic(descriptors))
                    service = GattService(tokens[2], int(tokens[4]), int(tokens[6]))
                    self.addService(service)
                elif tokens[0] == 'char':
                    assert service
                    # Close the previous descriptor group
                    if 'descriptors' in locals() and descriptors:
                        service.addCharacteristic(GattCharacteristic(descriptors))
                    descriptors = []
                elif tokens[0] == 'desc':
                    assert 'descriptors' in locals()
                    descriptors.append(GattDescriptor(int(tokens[2]), tokens[1]))
            # Close the last descriptor group
            if service and 'descriptors' in locals() and descriptors:
                service.addCharacteristic(GattCharacteristic(descriptors))
