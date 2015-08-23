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

import android.bluetooth.BluetoothGattService;

import java.lang.reflect.InvocationTargetException;
import java.util.UUID;


/** GATT Battery Service */
public class SrvActivityMonitoring extends BleService {
    public final static UUID SERVICE_UUID = UUID.fromString("68b52738-4a04-40e1-8f83-337a29c3284d");


    public SrvActivityMonitoring(BluetoothGattService gattService, BleDevice bleDevice) {
        super(SERVICE_UUID, gattService, bleDevice);

        try {

            // Register the concrete characteristic classes. Failing one of the
            // assertions bellow would indicate incorrect definition of one of
            // the characteristics.
            mChStepCount = createAndRegisterCharacteristic(ChStepCount.class);
            mChAccelerationEnergyMagnitude = createAndRegisterCharacteristic(ChAccelerationEnergyMagnitude.class);

        } catch (InstantiationException e) {
            throw new AssertionError();
        } catch (IllegalAccessException e) {
            throw new AssertionError();
        } catch (NoSuchMethodException e) {
            throw new AssertionError();
        } catch (IllegalArgumentException e) {
            throw new AssertionError();
        } catch (InvocationTargetException e) {
            throw new AssertionError();
        }
    }

    public SrvActivityMonitoring() {
        super(SERVICE_UUID);
    }

    public ChStepCount getStepCount() {
        return mChStepCount;
    }

    public ChAccelerationEnergyMagnitude getChAccelerationEnergyMagnitude() {
        return mChAccelerationEnergyMagnitude;
    }

    private ChStepCount mChStepCount;
    private ChAccelerationEnergyMagnitude mChAccelerationEnergyMagnitude;
}