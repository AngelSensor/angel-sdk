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

import com.angel.sdk.ChAccelerationEnergyMagnitude.AccelerationEnergyMagnitudeValue;

import java.util.UUID;


public class ChAccelerationEnergyMagnitude extends BleCharacteristic<AccelerationEnergyMagnitudeValue> {
    public final static UUID CHARACTERISTIC_UUID = UUID.fromString("9e3bd0d7-bdd8-41fd-af1f-5e99679183ff");

    public ChAccelerationEnergyMagnitude(BluetoothGattCharacteristic gattCharacteristic,
                                         BleDevice bleDevice) {
        super(CHARACTERISTIC_UUID, gattCharacteristic, bleDevice);
    }

    public ChAccelerationEnergyMagnitude() {
        super(CHARACTERISTIC_UUID);
    }

    @Override
    protected AccelerationEnergyMagnitudeValue processCharacteristicValue() {
        AccelerationEnergyMagnitudeValue value = new AccelerationEnergyMagnitudeValue();
        BluetoothGattCharacteristic c = getBaseGattCharacteristic();
        value.value = c.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT32, 0);
        return value;
    }

    /**
     * Acceleration Energy Magnitude is too simple for this abstraction but
     * {@code BleCharacteristic} requires a class to encapsulate the
     * characteristic fields.
     */
    public class AccelerationEnergyMagnitudeValue {
        public int value;
    }
}
