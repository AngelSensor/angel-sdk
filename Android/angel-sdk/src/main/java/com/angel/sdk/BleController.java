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

import android.app.Service;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;


/**
 * Android service that handles all the low level GATT access.
 * <p>
 * Access to this class is completely encapsulated by more high level classes,
 * so usually there is no need to access this class directly form the outside of
 * the library.
 */
public class BleController extends Service {

    // Outgoing intent actions
    public final static String ACTION_GATT_CONNECTED = "com.angel.sdk.ACTION_GATT_CONNECTED";
    public final static String ACTION_GATT_DISCONNECTED = "com.angel.sdk.ACTION_GATT_DISCONNECTED";
    public final static String ACTION_GATT_SERVICES_DISCOVERED = "com.angel.sdk.ACTION_GATT_SERVICES_DISCOVERED";
    public final static String ACTION_DATA_READ_AVAILABLE = "com.angel.sdk.ACTION_DATA_READ_AVAILABLE";
    public final static String ACTION_DATA_CHANGED_AVAILABLE = "com.angel.sdk.ACTION_DATA_CHANGED_AVAILABLE";

    // Intent data fields
    public final static String SERVICE_UUID = "com.angel.sdk.SERVICE_UUID";
    public final static String CHARACTERISTIC_UUID = "com.angel.sdk.CHARACTERISTIC_UUID";
    public final static String DEVICE_ADDRESS = "com.angel.sdk.DEVICE_ADDRESS";

    public final static String CLIENT_CHARACTERISTIC_CONFIG = "00002902-0000-1000-8000-00805f9b34fb";


    /**
     * Used to retrieve the {@code BleController} instance from the client code.
     */
    public class LocalBinder extends Binder {
        public BleController getService() {
            return BleController.this;
        }
    }


    /**
     * @see android.app.Service#onBind(android.content.Intent)
     */
    @Override
    public IBinder onBind(Intent intent) {
        return mBinder;
    }


    /**
     * @see android.app.Service#onUnbind(android.content.Intent)
     */
    @Override
    public boolean onUnbind(Intent intent) {
        return super.onUnbind(intent);
    }


    public boolean initialize() {
        if (mBluetoothManager == null) {
            mBluetoothManager = (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
            if (mBluetoothManager == null) {
                return false;
            }
        }

        mBluetoothAdapter = mBluetoothManager.getAdapter();
        if (mBluetoothAdapter == null) {
            return false;
        }

        return true;
    }


    public BluetoothDevice getRemoteDevice(final String address) {
        return mBluetoothAdapter.getRemoteDevice(address);
    }


    private BluetoothManager mBluetoothManager;
    private BluetoothAdapter mBluetoothAdapter;

    private final IBinder mBinder = new LocalBinder();
}
