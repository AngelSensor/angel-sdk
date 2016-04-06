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

import argparse
import math
from bled112 import *
from cube import *
import traceback

class Sint16:
    def __init__(self, value=0):
        self.value = value
    
    def serialize(self):
        return struct.unpack('2B', struct.pack('H', self.value))
        
    def deserialize(self, packed):
        ba = bytearray(2)
        ba[0] = packed[0]
        ba[1] = packed[1]
        self.value = struct.unpack("<h", str(ba))[0]
        return self.value

class Mpu():
    WAVEFORM_SERVICE_UUID = '481d178c10dd11e4b514b2227cce2b54'
    ACCEL_WAVEFORM_UUID = '4e92f4abc01b4b5ab328699856a7c2ee'
    GYRO_WAVEFORM_UUID = '5df14ec3fed1442883bf28ade00b0d98'
    
    def __init__(self, mac_address):
        try:
            self.com = Bled112Com()
            self.com.start()
            self.ble = BleManager(self.com, mac_address)
            self.ble.connect()
            self.ble.prepGatt()
            self.ACCEL_WAVEFORM_HANDLE = self.ble.gatt.getHandle(self.WAVEFORM_SERVICE_UUID, self.ACCEL_WAVEFORM_UUID)
            self.GYRO_WAVEFORM_HANDLE = self.ble.gatt.getHandle(self.WAVEFORM_SERVICE_UUID, self.GYRO_WAVEFORM_UUID)
        except:
            if hasattr(self, 'com'): self.com.close()
            raise

    def terminate(self):
        try:
            self.com.reset()
        finally:
            self.com.close()
                     
    def readCharacteristicValue(self, service, uuid, valueType, **kwargs):
        handle = self.ble.gatt.getHandle(service, uuid)

        if 'connectionType' not in kwargs or kwargs['connectionType'] == 'read':
            value = self.ble.readAttribute(handle)
        else:
            value = self.ble.waitValue(handle)
            assert value.attHandle == handle
            
        if valueType == 'string':
            return makeStringFromArray(value.data)
        elif valueType == 'raw':
            return value.data
        elif valueType == 'hex':
            return makeHexFromArray(value.data)
        else:
            raise Exception("unsupported format")

    def listen(self):
        self.ble.configClientCharacteristic(self.WAVEFORM_SERVICE_UUID, self.ACCEL_WAVEFORM_UUID, notify=True)
        self.ble.configClientCharacteristic(self.WAVEFORM_SERVICE_UUID, self.GYRO_WAVEFORM_UUID, notify=True)
        
def handleEvent(event, gfx, ble):
    if event.attHandle == ble.ACCEL_WAVEFORM_HANDLE: handleAccelEvent(event, gfx)
    elif event.attHandle == ble.GYRO_WAVEFORM_HANDLE: handleGyroEvent(event, gfx)
    
def handleAccelEvent(event, gfx):
    d = event.data
    while len(d) >= 3:
        mag = d[0] + (d[1] << 8) + (d[2] << 16)
        del d[0:3]
        gfx.addAccel(mag)
    
def convertGyro(gyro):
    '''Convert gyro output to angle change in degrees based on sampling rate and sensitivity'''
    sampling_rate = 100.0   # Hz
    sensitivity   = 500.0   # deg/sec
    half_range    = 2 << 15 # 16-bit signed value
    return gyro * sensitivity / half_range / sampling_rate
    
def handleGyroEvent(event, gfx):
    d = event.data
    while len(d) >= 6:
        x = Sint16().deserialize(d[0:2])
        y = Sint16().deserialize(d[2:4])
        z = Sint16().deserialize(d[4:6])
        del d[0:6]
        gfx.rotateX(convertGyro(x))
        gfx.rotateY(convertGyro(z))
        gfx.rotateZ(convertGyro(y))
    
def loopEvents(gfxThread, ble):
    stop = False
    while not stop:
        for event in pygame.event.get():
            if event.type == pygame.QUIT or \
               (event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE):
                print "PyGame quit"
                gfxThread.terminate()
                stop = True
                break
        ev = ble.ble.getEvent()
        if ev and AttClientAttributeValueEvent().equalsByHeader(ev):
            handleEvent(ev, gfxThread, ble)
        #pygame.time.wait(50)
    gfxThread.join()
    pygame.quit()
    

def main():    
    parser = argparse.ArgumentParser()
    parser.add_argument('-a', '--address', required=True, help='MAC address of your Angel Sensor, e.g. 00:07:80:02:F2:F2')
    args = parser.parse_args()
    mac = [int(octet,16) for octet in args.address.split(':')]
    mac.reverse()
    print 'Press ESC or Ctrl-C to exit'
    
    try:
        mpu = Mpu(mac)
        gfx = Graphics()
        print 'Connected'
        mpu.listen()
        gfx.start()        
        loopEvents(gfx, mpu)
        
    except Exception as e:
        print e
        traceback.print_exc()
        
    finally:
        if mpu: mpu.terminate()
    
if __name__ == "__main__":
    main()
