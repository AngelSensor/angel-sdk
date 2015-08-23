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

import com.angel.sdk.ChHeartRateMeasurement.HeartRateMeasurementValue;

import java.util.UUID;


/** org.bluetooth.characteristic.heart_rate_measurement */
public class ChHeartRateMeasurement extends BleCharacteristic<HeartRateMeasurementValue> {
    public final static UUID CHARACTERISTIC_UUID = UUID.fromString("00002a37-0000-1000-8000-00805f9b34fb");

    public ChHeartRateMeasurement(BluetoothGattCharacteristic gattCharacteristic,
                                  BleDevice bleDevice) {
        super(CHARACTERISTIC_UUID, gattCharacteristic, bleDevice);
    }

    public ChHeartRateMeasurement() {
        super(CHARACTERISTIC_UUID);
    }

    @Override
    protected HeartRateMeasurementValue processCharacteristicValue() {
        HeartRateMeasurementValue heartRateMeasurementValue = new HeartRateMeasurementValue();
        BluetoothGattCharacteristic c = getBaseGattCharacteristic();
        int flags = c.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT8, 0);
        int nextOffset = 1;
        int format = -1;
        if ((flags & 0x01) != 0) {
            format = BluetoothGattCharacteristic.FORMAT_UINT16;
            nextOffset += 2;
        } else {
            format = BluetoothGattCharacteristic.FORMAT_UINT8;
            nextOffset += 1;
        }
        heartRateMeasurementValue.mHeartRateMeasurement = c.getIntValue(format, 1);
        if ((flags & 0x08) != 0) {

            heartRateMeasurementValue.mEnergyExpended = c.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT16,
                                                                      nextOffset);
            nextOffset += 2;
        }

        if ((flags & 0x10) != 0) {

            int rrCount = (c.getValue().length - nextOffset) / 2;
            heartRateMeasurementValue.mRRIntervals = new int[rrCount];
            for (int i = 0; i < rrCount; i++) {
                heartRateMeasurementValue.mRRIntervals[i] = c.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT16,
                                                                          nextOffset);
                nextOffset += 2;
            }
        }
        return heartRateMeasurementValue;
    }


    public class HeartRateMeasurementValue {
        int mHeartRateMeasurement;
        int mEnergyExpended;
        int[] mRRIntervals;


        public int getHeartRateMeasurement() {
            return mHeartRateMeasurement;
        }


        public int getEnergyExpended() {
            return mEnergyExpended;
        }


        public int[] getRRIntervals() {
            return mRRIntervals;
        }
    }
}
