/*
 * Copyright (c) 2014, Seraphim Sense Ltd.
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

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Modifier;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;

import android.app.Activity;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.util.Log;


/**
 * Bluetooth device object. Manages the life cycle and gives access to the GATT
 * services.
 * <p>
 * The client is expected to initialize a BleDevice object in three steps:
 * create an instance of BleDevice or an inherited class, register all the
 * required services by calling {@link #registerServiceClass(Class)}, call
 * {@link #connect(String)}.
 */
public class BleDevice {

    public BleDevice(Context context, LifecycleCallback lifecycleCallback) {
        mLifecycleCallback = lifecycleCallback;
        mActivity = (Activity) context;
        context.registerReceiver(mGattUpdateReceiver, makeGattUpdateIntentFilter());
    }


    /**
     * Interface for notifications on BLE device life cycle events
     */
    public interface LifecycleCallback {

        /** Called after the device discovers new supported services */
        public void onBluetoothServicesDiscovered();


        /** Called on device disconnection */
        public void onBluetoothDeviceDisconnected();
    }


    public void connect(String deviceAddress) {

        mDeviceAddress = deviceAddress;
        if (mBleController == null) {
            mAction = Action.CONNECT;
            Intent gattServiceIntent = new Intent(mActivity.getApplicationContext(),
                                                  BleController.class);
            boolean gotBinded = mActivity.getApplicationContext().bindService(gattServiceIntent,
                                                                              mServiceConnection,
                                                                              Context.BIND_AUTO_CREATE);
            if (!gotBinded) throw new RuntimeException("Failed to bind to BleController");
        } else {
            mBleController.connect(mDeviceAddress);
        }
    }


    public void disconnect() {
        mDeviceAddress = "";
        if (mBleController == null) {
            mAction = Action.DISCONNECT;
            Intent gattServiceIntent = new Intent(mActivity.getApplicationContext(),
                                                  BleController.class);
            boolean gotBinded = mActivity.getApplicationContext().bindService(gattServiceIntent,
                                                                              mServiceConnection,
                                                                              Context.BIND_AUTO_CREATE);
            if (!gotBinded) {
            }
        } else {
            mBleController.disconnect();
        }
    }


    /**
     * Get a concrete service object of the specified type as was previously
     * registered using {@link BleDevice#registerServiceClass(UUID, Class)}.
     * Throws ClassCastException if for a specific service UUID was registered
     * one class but then getService was called with another.
     * 
     * Usage example:
     * <code> SrvHeartRate hr = device.getService(SrvHeartRate.class); </code>
     * 
     * @return null if the service wasn't found
     */
    public <T extends BleService> T getService(Class<T> serviceClass) {
        try {
            BleService service = serviceClass.newInstance();

            @SuppressWarnings("unchecked")
            T concreteService = (T) mBleServices.get(service.getUuid());
            return concreteService;
        } catch (InstantiationException e) {
            throw new AssertionError(); // Should have been verified in registerServiceClass
        } catch (IllegalAccessException e) {
            throw new AssertionError(); // Should have been verified in registerServiceClass
        }
    }


    /**
     * Registers a service. If a service class is not registered, it won't be
     * accessible via {@link #getService(Class)}. Note that a service class can
     * be registered even if the actual device eventually doesn't support the
     * service. This method exists to allows definition of new services outside
     * of the SDK.
     */
    public void registerServiceClass(Class<? extends BleService> serviceClass)
            throws NoSuchMethodException,
                IllegalAccessException,
                InstantiationException {
        // Create a non-operational dummy instance only to access the UUID
        BleService service = serviceClass.newInstance();

        // Check that the class has the required public constructor
        Constructor<? extends BleService> ctor = serviceClass.getConstructor(BluetoothGattService.class,
                                                                             BleDevice.class);
        if (!Modifier.isPublic(ctor.getModifiers())) {
            throw new IllegalAccessException(serviceClass.getName() + " constructor must be public");
        }
        mBleServiceClasses.put(service.getUuid(), serviceClass);
    }


    public void readCharacteristic(final BluetoothGattCharacteristic characteristic) {
        if (characteristic == null) {
            return;
        }
        final int properties = characteristic.getProperties();
        if ((properties & BluetoothGattCharacteristic.PROPERTY_READ) > 0) {
            mBleController.readCharacteristic(characteristic);
        }
    }


    public void writeCharacteristic(BluetoothGattCharacteristic characteristic) {
        if (characteristic == null) {
            return;
        }
        final int properties = characteristic.getProperties();
        if ((properties & BluetoothGattCharacteristic.PROPERTY_WRITE) > 0) {
            mBleController.writeCharacteristic(characteristic);
        }
    }


    public void enableCharacteristicNotifications(final BluetoothGattCharacteristic characteristic) {
        if (characteristic == null) {
            return;
        }
        final int properties = characteristic.getProperties();
        if ((properties & BluetoothGattCharacteristic.PROPERTY_NOTIFY) > 0) {
            mBleController.enableCharacteristicNotifications(characteristic);
        }
    }


    private void addNewServices(List<BluetoothGattService> supportedGattServices) {
        for (BluetoothGattService bluetoothGattService : supportedGattServices) {
            BleService bleService = null;
            UUID serviceUuid = bluetoothGattService.getUuid();
            Class<? extends BleService> serviceClass = mBleServiceClasses.get(serviceUuid);

            // Is the service registered?
            if (serviceClass == null) continue;

            // Was the service discovered earlier?
            if (mBleServices.containsKey(serviceUuid)) continue;

            try {
                Constructor<? extends BleService> ctor = serviceClass.getConstructor(BluetoothGattService.class,
                                                                                     BleDevice.class);
                bleService = ctor.newInstance(bluetoothGattService, this);
            } catch (InstantiationException e) {
                throw new AssertionError(); // Should have been verified in registerServiceClass
            } catch (IllegalAccessException e) {
                throw new AssertionError(); // Should have been verified in registerServiceClass
            } catch (NoSuchMethodException e) {
                throw new AssertionError(); // Should have been verified in registerServiceClass
            } catch (InvocationTargetException e) {
                Log.e(TAG, "Could not create an instance of " + serviceClass.getName()
                           + ". Constructor threw an exception");
            }

            mBleServices.put(bluetoothGattService.getUuid(), bleService);
        }
    }


    private static IntentFilter makeGattUpdateIntentFilter() {
        final IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(BleController.ACTION_GATT_CONNECTED);
        intentFilter.addAction(BleController.ACTION_GATT_DISCONNECTED);
        intentFilter.addAction(BleController.ACTION_GATT_SERVICES_DISCOVERED);
        intentFilter.addAction(BleController.ACTION_DATA_READ_AVAILABLE);
        intentFilter.addAction(BleController.ACTION_DATA_CHANGED_AVAILABLE);
        return intentFilter;
    }


    private enum Action {
        IDLE, CONNECT, DISCONNECT
    }

    private final ServiceConnection mServiceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName componentName, IBinder service) {
            mBleController = ((BleController.LocalBinder) service).getService();
            if (!mBleController.initialize()) {
                return;
            }
            switch (mAction) {
            case CONNECT:
                mBleController.connect(mDeviceAddress);
                break;
            case DISCONNECT:
                mBleController.disconnect();
                break;
            default:
                break;
            }
            mAction = Action.IDLE;
        }


        @Override
        public void onServiceDisconnected(ComponentName componentName) {
            mBleController = null;
        }
    };

    private final BroadcastReceiver mGattUpdateReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final String action = intent.getAction();
            if (BleController.ACTION_GATT_CONNECTED.equals(action)) {
            } else if (BleController.ACTION_GATT_DISCONNECTED.equals(action)) {
                if (mLifecycleCallback != null) {
                    mLifecycleCallback.onBluetoothDeviceDisconnected();
                }
            } else if (BleController.ACTION_GATT_SERVICES_DISCOVERED.equals(action)) {
                addNewServices(mBleController.getBaseGattServices());
                if (mLifecycleCallback != null) {
                    mLifecycleCallback.onBluetoothServicesDiscovered();
                }
            } else if (BleController.ACTION_DATA_READ_AVAILABLE.equals(action)
                       || BleController.ACTION_DATA_CHANGED_AVAILABLE.equals(action)) {

                String serviceUuid = intent.getStringExtra(BleController.SERVICE_UUID);
                if (serviceUuid == null) throw new AssertionError();

                String charcteristicUuid = intent.getStringExtra(BleController.CHARACTERISTIC_UUID);
                if (charcteristicUuid == null) throw new AssertionError();

                BleService bleService = mBleServices.get(UUID.fromString(serviceUuid));
                BleCharacteristic<?> bleCharacteristic = bleService.getCharacteristic(UUID.fromString(charcteristicUuid));

                bleCharacteristic.onCharacteristicChanged();
            }
        }
    };

    private Action mAction = Action.IDLE;
    private String mDeviceAddress;
    private final Activity mActivity;
    private final LifecycleCallback mLifecycleCallback;
    private BleController mBleController = null;
    private final HashMap<UUID, BleService> mBleServices = new HashMap<UUID, BleService>();
    private final HashMap<UUID, Class<? extends BleService>> mBleServiceClasses = new HashMap<UUID, Class<? extends BleService>>();

    private static final String TAG = BleDevice.class.getName();
}
