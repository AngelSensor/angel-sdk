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

from bled112 import *
from struct import *
import logging
import argparse

GATT_PRIMARY_SERVICE = '2800'
GATT_CCCD = '2902'
GATT_HEART_RATE_SERVICE = '180D'
GATT_HEART_RATE_MEASUREMENT = '2A37'

DEBUG = True
INFO = True

def macString(mac):
    return '%02X:%02X:%02X:%02X:%02X:%02X' % (mac[0], mac[1], mac[2], mac[3], mac[4], mac[5])

class Timeout:
    """Simplify timeout interval management"""
    def __init__(self, interval):
        self.start = time.time()
        self.interval = interval
        
    def isExpired(self): 
        return time.time() - self.start >= self.interval
        
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
        
class BleManager:
    def __init__(self, com, mac):
        self.reactions = {
            AttClientFindInformationFoundEvent: self.onAttClientFindInformationFoundEvent,
            AttClientGroupFoundEvent : self.onAttClientGroupFoundEvent,
            ConnectionDisconnectedEvent : self.onConnectionDisconnectedEvent,
            ConnectionStatusEvent : self.onConnectionStatusEvent,
        }
        self.connection = BleConnection(mac)
        self.com = com
        self.expectedMessage = None
        com.listener = self
        self.localTimeout = 1
        self.remoteTimeout = 2
        
    # Called by BLED112 thread
    def onMessage(self, message):
        if self.expectedMessage and message.__class__ == self.expectedMessage.__class__:
            self.actualMessage = message
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
        t = Timeout(timeout)
        self.expectedMessage = message
        self.actualMessage = None
        while self.expectedMessage and not t.isExpired(): pass
        return self.actualMessage
        
    def waitLocal(self, message):
        msg = self.waitForMessage(message, self.localTimeout)
        if not msg: raise BleLocalTimeout()
        return msg
        
    def waitRemote(self, message, timeout=None):
        msg = self.waitForMessage(message, timeout if timeout is not None else self.remoteTimeout)
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
        handle = self.connection.handleByUuid(uuid)
        self.writeAttributeByHandle(handle, data)
        
    def writeAttributeByHandle(self, handle, data):
        self.com.send(\
            AttClientAttributeWriteCommand(self.connection.id,
                                           handle,
                                           data))
        self.waitLocal(AttClientAttributeWriteResponse())
        self.completeProcedure()
        
    def completeProcedure(self):
        msg = self.waitRemote(AttClientProcedureCompleted())
        logging.debug('Procedure completed')
        return msg.result == 0
    
    def configClientCharacteristic(self, handle, notify=False, indicate=False):
        NOTIFY_ENABLE = 1
        INDICATE_ENABLE = 2
        flags = 0
        if notify: flags = flags | NOTIFY_ENABLE
        if indicate: flags = flags | INDICATE_ENABLE
        self.writeAttributeByHandle(handle, [flags])
        
    def isConnected(self): return self.connection.id is not None
    
    def waitValue(self, uuid): 
        handle = self.connection.handleByUuid(uuid)
        return self.waitRemote(AttClientAttributeValueEvent()).data

    def readAttribute(self, uuid):
        logging.info('Reading attribute %s' % uuid)
        handle = self.connection.handleByUuid(uuid)
        self.com.send(AttClientReadByHandleCommand(self.connection.id,
                                                           handle))
        self.waitLocal(AttClientReadByHandleResponse())
        return self.waitValue(uuid)
        
    def readByGroupType(self, start, end, uuid):
        self.groups = {}
        self.com.send(ReadByGroupTypeCommand(self.connection.id, start, end, uuid))
        self.waitLocal(ReadByGroupTypeResponse())
        self.completeProcedure()
        return self.groups
        
    def onAttClientGroupFoundEvent(self, message):
        self.groups[message.uuid] = AttributeGroup(message.uuid, message.start, message.end)
        
    def findInformation(self, start, end):
        self.handles = {}
        self.com.send(AttClientFindInformationCommand(self.connection.id, start, end))
        self.waitLocal(AttClientFindInformationResponse())
        self.completeProcedure()
        return self.handles

    def onAttClientFindInformationFoundEvent(self, message):
        self.handles[message.uuid] = message.chrHandle
        
class SubscribeToHeartRateProcedure:
    def __init__(self, ble):
        self.ble = ble
        
    def run(self):
        logging.info('Enumerating Heart Rate Service')
        groups = self.ble.readByGroupType(1, 0xFFFF, Uint16(int(GATT_PRIMARY_SERVICE,16)).serialize())
        if GATT_HEART_RATE_SERVICE not in groups:
            raise RuntimeError('Heart Rate Service not supported by the device')
        hrGroup = groups[GATT_HEART_RATE_SERVICE]
        handles = self.ble.findInformation(hrGroup.start, hrGroup.end)
        if GATT_CCCD not in handles:
            raise RuntimeError('Client Characteristic Configuration Descriptor not found')
        self.ble.configClientCharacteristic(handles[GATT_CCCD], notify=True)
        if GATT_HEART_RATE_MEASUREMENT not in handles:
            raise RuntimeError('Heart Rate Measurement Characteristic not found')
        return handles[GATT_HEART_RATE_MEASUREMENT]
        
class ListenToHeartRateProcedure:
    def __init__(self, ble, heartRateHandle):
        self.ble = ble
        self.heartRateHandle = heartRateHandle
        
    def run(self):
        logging.info('Listening to heart rate notifications. Press Ctrl-C to quit.')
        try:
            while True:
                evt = self.ble.waitRemote(AttClientAttributeValueEvent(), 30)
                if evt.attHandle == self.heartRateHandle:
                    # Assume format as reported by Angel Sensor, ignore flags
                    logging.info('Heart rate = %u' % evt.data[1])
                    
        except KeyboardInterrupt:
            logging.info('Terminated by key stroke')
            return
            
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-a', '--address', help='MAC address for the device to program, e.g. 00:07:80:AB:CD:EF')
    parser.add_argument('-s', '--serial', help='Serial port used by BLED112, e.g. COM3')
    args = parser.parse_args()
    
    mac = [int(i, 16) for i in reversed(args.address.split(':'))]

    # See: https://docs.python.org/2/howto/logging-cookbook.html
    logging.basicConfig(level=logging.INFO,
                        format='%(message)s')
    
    logging.info('Reset BLED112')
    bled112 = Bled112Com(args.serial)
    
    try:
        bled112.start()
        ble = BleManager(bled112, mac)
        ble.connect()
        hrHandle = SubscribeToHeartRateProcedure(ble).run()
        ListenToHeartRateProcedure(ble, hrHandle).run()
        bled112.close()
        
    finally:
        bled112.reset()
        bled112.close()
    return
    
if __name__ == "__main__":
    main()
