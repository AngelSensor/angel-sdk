/*
 * Copyright (c) 2015, Seraphim Sense Ltd.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions
 *    and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of
 *    conditions and the following disclaimer in the documentation and/or other materials provided
 *    with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to
 *    endorse or promote products derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package com.angel.sdk;

import android.bluetooth.BluetoothGattCharacteristic;

import com.angel.sdk.ChAccelerationWaveform.AccelerationWaveformValue;

import java.util.ArrayList;
import java.util.UUID;

public class ChAccelerationWaveform extends BleCharacteristic<AccelerationWaveformValue> {
    public final static UUID CHARACTERISTIC_UUID = UUID.fromString("4e92f4ab-c01b-4b5a-b328-699856a7c2ee");


    public ChAccelerationWaveform(BluetoothGattCharacteristic gattCharacteristic,
                             BleDevice bleDevice) {
        super(CHARACTERISTIC_UUID, gattCharacteristic, bleDevice);
    }


    public ChAccelerationWaveform() {
        super(CHARACTERISTIC_UUID);
    }
    
    
    @Override
    protected AccelerationWaveformValue processCharacteristicValue() {
        AccelerationWaveformValue result = new AccelerationWaveformValue();
        
        BluetoothGattCharacteristic ch = getBaseGattCharacteristic();
        byte[] buffer = ch.getValue();
        
        final int SAMPLE_SIZE = 3;
        for (int i=SAMPLE_SIZE-1; i<buffer.length; i+=SAMPLE_SIZE) {
            
            int wave = unsignedByte(buffer[i-2]) + 
                       unsignedByte(buffer[i-1])*256 +
                       unsignedByte(buffer[i])*256*256;
            
            result.wave.add(wave);
        }
        
        return result;
    }
    
    
    public class AccelerationWaveformValue {
        public ArrayList<Integer> wave = new ArrayList<Integer>();
    }

    
    private static int unsignedByte(byte x) {
        return x & 0xFF;
    }
}
