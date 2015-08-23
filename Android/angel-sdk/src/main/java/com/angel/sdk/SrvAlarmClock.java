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

import com.angel.sdk.BleCharacteristic.ValueReadyCallback;

import java.util.ArrayList;
import java.util.GregorianCalendar;
import java.util.UUID;


/**
 * 
 * 
 */
class SrvAlarmClock extends BleService {
    public final static UUID SERVICE_UUID = UUID.fromString("7cd50edd-8bab-44ff-a8e8-82e19393af10");


    public SrvAlarmClock(BluetoothGattService vanillaGattService, BleDevice bleDevice) {
        super(SERVICE_UUID, vanillaGattService, bleDevice);
    }


    /**
     * Creates a non-operation instance used to investigate static properties in
     * contexts where these properties are accessible only via a class instance.
     * Calling most methods of such an object will cause an undefined behavior.
     */
    public SrvAlarmClock() {
        super(SERVICE_UUID);
    }


    /**
     * Get the characteristic that allows to control the behavior of the alarm
     * clock.
     */
    public ChAlarmClockControlPoint getControlPointCharacteristic() {
        return null;
    }


    /**
     * Requests a list of the currently scheduled alarms on the device. The
     * result is returned asynchronously via the callback object.
     */
    public void getActiveAlarms(ValueReadyCallback<ArrayList<GregorianCalendar>> callback) {
    }


    /**
     * Requests the current date and time of the alarm device. The result is
     * returned asynchronously via the callback object.
     */
    public void readCurrentDateTime(ValueReadyCallback<GregorianCalendar> callback) {
    }
}
