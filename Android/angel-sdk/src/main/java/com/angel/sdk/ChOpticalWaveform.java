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

import com.angel.sdk.ChOpticalWaveform.OpticalWaveformValue;

import java.util.ArrayList;
import java.util.UUID;


public class ChOpticalWaveform extends BleCharacteristic<OpticalWaveformValue> {
    public final static UUID CHARACTERISTIC_UUID = UUID.fromString("334c0be8-76f9-458b-bb2e-7df2b486b4d7");


    public ChOpticalWaveform(BluetoothGattCharacteristic gattharacteristic,
                             BleDevice bleDevice) {
        super(CHARACTERISTIC_UUID, gattharacteristic, bleDevice);
    }


    public ChOpticalWaveform() {
        super(CHARACTERISTIC_UUID);
    }
    
    
    @Override
    protected OpticalWaveformValue processCharacteristicValue() {
        OpticalWaveformValue result = new OpticalWaveformValue();
        
        BluetoothGattCharacteristic ch = getBaseGattCharacteristic();
        byte[] buffer = ch.getValue();
        
        final int TWO_SAMPLES_SIZE = 6;
        for (int i=TWO_SAMPLES_SIZE-1; i<buffer.length; i+=TWO_SAMPLES_SIZE) {
            
            int green = unsignedByte(buffer[i-5]) + 
                        unsignedByte(buffer[i-4])*256 + 
                        unsignedByte(buffer[i-3])*256*256;
            
            int blue  = unsignedByte(buffer[i-2]) + 
                        unsignedByte(buffer[i-1])*256 + 
                        unsignedByte(buffer[i])*256*256;
        
            OpticalSample sample = new OpticalSample();
            sample.green = TwosComplement(green);
            sample.blue = TwosComplement(blue);
            result.wave.add(sample);
        }
        
        return result;
    }
    
    
    public class OpticalSample {
        public int green;
        public int blue;
    }
    
    public class OpticalWaveformValue {
        public ArrayList<OpticalSample> wave = new ArrayList<OpticalSample>();
    }

    private static int unsignedByte(byte x) {
        return x & 0xFF;
    }

    int TwosComplement(int raw) {
        final int BITS = 24;
        final int NEGATIVE_BITMASK = 1 << (BITS - 1);
        final int FULL_RANGE = 1 << BITS;

        int value = raw;
        if ((value & NEGATIVE_BITMASK) != 0) {
            value -= FULL_RANGE;
        }
        
        return value;
    }
}
