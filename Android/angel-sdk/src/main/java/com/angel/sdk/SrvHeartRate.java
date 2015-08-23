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


/** GATT Heart Rate Service */
public class SrvHeartRate extends BleService {
    public final static UUID SERVICE_UUID = UUID.fromString("0000180d-0000-1000-8000-00805f9b34fb");


    public SrvHeartRate(BluetoothGattService gattService, BleDevice bleDevice) {
        super(SERVICE_UUID, gattService, bleDevice);

        try {

            // Register all the concrete classes for all the characteristics 
            // of Heart Rate Service. Failing one of the assertions bellow means
            // we have mistakes with the definition of one of the characteristics
            mHeartRateMeasurement = createAndRegisterCharacteristic(ChHeartRateMeasurement.class);
            mBodySensorLocation = createAndRegisterCharacteristic(ChBodySensorLocation.class);
            mHeartRateControlPoint = createAndRegisterCharacteristic(ChHeartRateControlPoint.class);

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


    public SrvHeartRate() {
        super(SERVICE_UUID);
    }


    /** Get access to Heart Rate Measurement characteristic */
    public ChHeartRateMeasurement getHeartRateMeasurement() {
        return mHeartRateMeasurement;
    }


    /** Get access to Body Sensor Location characteristic */
    public ChBodySensorLocation getBodySensorLocation() {
        return mBodySensorLocation;
    }


    /** Get access to Heart Rate Control Point characteristic */
    public ChHeartRateControlPoint getHeartRateControlPoint() {
        return mHeartRateControlPoint;
    }

    private ChHeartRateMeasurement mHeartRateMeasurement;
    private ChBodySensorLocation mBodySensorLocation;
    private ChHeartRateControlPoint mHeartRateControlPoint;
}