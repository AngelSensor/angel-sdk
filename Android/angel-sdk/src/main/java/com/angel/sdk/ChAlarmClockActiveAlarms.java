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

import com.angel.sdk.ChAlarmClockActiveAlarms.ActiveAlarms;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.UUID;


public class ChAlarmClockActiveAlarms extends BleCharacteristic<ActiveAlarms> {
    public final static UUID CHARACTERISTIC_UUID = UUID.fromString("5265e9d9-595e-4076-bcad-e9827e00b146");


    public ChAlarmClockActiveAlarms(BluetoothGattCharacteristic gattCharacteristic,
                                      BleDevice bleDevice) {
        super(CHARACTERISTIC_UUID, gattCharacteristic, bleDevice);
    }


    public ChAlarmClockActiveAlarms() {
        super(CHARACTERISTIC_UUID);
    }


    @Override
    protected ActiveAlarms processCharacteristicValue() {
        ActiveAlarms activeAlarms = new ActiveAlarms();
        BluetoothGattCharacteristic c = getBaseGattCharacteristic();
        int alarmsCount = c.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT8, 0);

        int nextOffset = 1;

        for (int i = 0; i < alarmsCount; i++) {
            byte[] dateArray = Arrays.copyOfRange(c.getValue(), nextOffset,
                                                  nextOffset + BleDayDateTime.DATE_SERIALIZED_SIZE);
            nextOffset += BleDayDateTime.DATE_SERIALIZED_SIZE;
            GregorianCalendar cal = BleDayDateTime.Deserialize(dateArray);
            activeAlarms.mActiveAlarms.add(cal);
        }

        return activeAlarms;
    }


    public class ActiveAlarms {
        List<GregorianCalendar> mActiveAlarms = new ArrayList<GregorianCalendar>();


        public List<GregorianCalendar> getActiveAlarms() {
            return mActiveAlarms;
        }

    }
}
