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

import com.angel.sdk.ChTemperatureMeasurement.TemperatureMeasurementValue;

import java.util.Arrays;
import java.util.GregorianCalendar;
import java.util.UUID;


public class ChTemperatureMeasurement extends BleCharacteristic<TemperatureMeasurementValue> {
    public final static UUID CHARACTERISTIC_UUID = UUID.fromString("00002a1c-0000-1000-8000-00805f9b34fb");

    public final static int CELSIUS = 0;
    public final static int FAHRENHEIT = 1;


    public ChTemperatureMeasurement(BluetoothGattCharacteristic gattharacteristic,
                                    BleDevice bleDevice) {
        super(CHARACTERISTIC_UUID, gattharacteristic, bleDevice);
    }


    public ChTemperatureMeasurement() {
        super(CHARACTERISTIC_UUID);
    }


    protected ChTemperatureMeasurement(UUID uuid,
                                       BluetoothGattCharacteristic gattharacteristic,
                                       BleDevice bleDevice) {
        super(uuid, gattharacteristic, bleDevice);
    }


    protected ChTemperatureMeasurement(UUID uuid) {
        super(uuid);
    }


    @Override
    protected TemperatureMeasurementValue processCharacteristicValue() {
        TemperatureMeasurementValue tv = new TemperatureMeasurementValue();
        BluetoothGattCharacteristic c = getBaseGattCharacteristic();
        int nextOffset = 0;
        int flags = c.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT8, nextOffset);
        nextOffset += 1;

        tv.mTemperatureUnits = flags & 0x1;
        tv.mTemperatureMeasurement = c.getFloatValue(BluetoothGattCharacteristic.FORMAT_FLOAT,
                                                     nextOffset);
        nextOffset += 4;

        if ((flags & 0x2) != 0) {
            byte[] dateArray = Arrays.copyOfRange(c.getValue(), nextOffset,
                                                  nextOffset + BleDayDateTime.DATE_SERIALIZED_SIZE);
            tv.mTimeStamp = BleDayDateTime.Deserialize(dateArray);
            nextOffset += BleDayDateTime.DATE_SERIALIZED_SIZE;
        }

        if ((flags & 0x4) != 0) {
            tv.mTemperatureType = c.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT8,
                                                nextOffset);
        }
        return tv;
    }


    public class TemperatureMeasurementValue {
        int mTemperatureUnits;
        Float mTemperatureMeasurement;
        GregorianCalendar mTimeStamp;
        int mTemperatureType;


        public int getTemperatureUnits() {
            return mTemperatureUnits;
        }


        public Float getTemperatureMeasurement() {
            return mTemperatureMeasurement;
        }


        public GregorianCalendar getTimeStamp() {
            return mTimeStamp;
        }


        public int getTemperatureType() {
            return mTemperatureType;
        }
    }
}
