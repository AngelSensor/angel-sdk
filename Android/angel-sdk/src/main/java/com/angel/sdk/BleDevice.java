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

import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.IBinder;
import android.util.Log;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Modifier;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;


/**
 * Bluetooth device object. Manages the life cycle and provides access to the
 * GATT services.
 * <p>
 * The client is expected to initialize a BleDevice object in three steps:
 * create an instance of BleDevice or an inherited class, register all the
 * required services by calling {@link #registerServiceClass(Class)}, call
 * {@link #connect(String)}.
 */
public class BleDevice {
    private static HandlerThread makeThread() {
        HandlerThread handlerThread = new HandlerThread("BleDevice_callback_thread");
        handlerThread.start();
        return handlerThread;
    }

    public BleDevice(Context context, LifecycleCallback lifecycleCallback) {
        this(context, lifecycleCallback, new Handler(makeThread().getLooper()));
    }

    public BleDevice(Context context, LifecycleCallback lifecycleCallback, Handler callbackHandler) {
        mActivity = (Activity) context;
        mLifecycleCallback = lifecycleCallback;
        mCallbackHandler = callbackHandler;
    }

    /**
     * Interface for notifications on BLE device life cycle events
     */
    public interface LifecycleCallback {

        /** Called after the device discovers new supported services */
        public void onBluetoothServicesDiscovered(BleDevice device);


        /** Called on device disconnection */
        public void onBluetoothDeviceDisconnected();

        public void onReadRemoteRssi(final int rssi);
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
            connect(mBleController.getRemoteDevice(deviceAddress));
        }
    }
    
    
    public void disconnect() {
        mDeviceAddress = "";
        if (mBluetoothGatt != null) mBluetoothGatt.close();
    }

    public BleController getBleController() {
        return mBleController;
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


    /**
     * Request characteristic value. The value is returned asynchronously via
     * ACTION_DATA_READ_AVAILABLE intent.
     */
    public void readCharacteristic(final BluetoothGattCharacteristic characteristic) {
        if (characteristic == null) {
            return;
        }
        final int properties = characteristic.getProperties();
        if ((mBluetoothGatt != null)
            && (properties & BluetoothGattCharacteristic.PROPERTY_READ) > 0) {
            mBluetoothGatt.readCharacteristic(characteristic);
        }
    }


    public void writeCharacteristic(BluetoothGattCharacteristic characteristic) {
        if (characteristic == null) {
            return;
        }
        final int properties = characteristic.getProperties();
        if ((mBluetoothGatt != null)
            && (properties & BluetoothGattCharacteristic.PROPERTY_WRITE) > 0) {
            mBluetoothGatt.writeCharacteristic(characteristic);
        }
    }


    /**
     * Enable notifications and/or indications for the characteristic. Both
     * types are enabled in the rare case when a characteristic supports them.
     * 
     * This method will block if called on the BLE thread. Make sure it is called from
     * another thread.
     */
    public void enableCharacteristicNotifications(final BluetoothGattCharacteristic characteristic) {
        if (characteristic == null) {
            return;
        }
        final int properties = characteristic.getProperties();
        if (mBluetoothGatt != null) {
            if (((properties & BluetoothGattCharacteristic.PROPERTY_NOTIFY) > 0) ||
                ((properties & BluetoothGattCharacteristic.PROPERTY_INDICATE) > 0)) {
                setCharacteristicNotification(characteristic, true);
            }
        }
    }

    public void readRemoteRssi() {
        if (mBluetoothGatt != null) {
            mBluetoothGatt.readRemoteRssi();
        }
    }

    private void connect(BluetoothDevice device) {
        mBluetoothGatt = device.connectGatt(mBleController, false, mGattCallback);
    }
    
    
    private void setCharacteristicNotification(BluetoothGattCharacteristic characteristic,
                                               boolean enabled) {
        if (mBluetoothGatt == null) {
            return;
        }

        if (!mBluetoothGatt.setCharacteristicNotification(characteristic, enabled)) {
            throw new AssertionError("Failed setCharacteristicNotification for UUID " + characteristic.getUuid());
        }

        BluetoothGattDescriptor descriptor = characteristic.getDescriptor(UUID.fromString(BleController.CLIENT_CHARACTERISTIC_CONFIG));
        final byte NOTIFY_AND_INDICATE[] = {3,0};
        descriptor.setValue(enabled ? NOTIFY_AND_INDICATE : BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE);
        mWaitingForConfirmation = true;
        if (!mBluetoothGatt.writeDescriptor(descriptor)) {
            throw new AssertionError("Failed to write BLE descriptor " + descriptor.getUuid() + " for UUID " + characteristic.getUuid());
        }

        try {
            synchronized (this) {
                wait(DESCRIPTOR_WRITE_TIMEOUT);
                if (mWaitingForConfirmation) {
                    throw new AssertionError("Did not receive confirmation for mBluetoothGatt.writeDescriptor(" + characteristic.getUuid() + ")");
                }
            }
        } catch (InterruptedException e) {
            throw new AssertionError("Interrupted while waiting for response to mBluetoothGatt.writeDescriptor");        
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
                connect(mBleController.getRemoteDevice(mDeviceAddress));
                break;
            //TODO possibly deprecated
            case DISCONNECT:
                mBluetoothGatt.close();
                break;
            default:
                break;
            }
            mAction = Action.IDLE;
        }


        @Override
        public void onServiceDisconnected(ComponentName componentName) {
            mBluetoothGatt = null;
            mBleController = null;
        }
    };


    private final BluetoothGattCallback mGattCallback = new BluetoothGattCallback() {
        @Override
        public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                mBluetoothGatt.discoverServices();

            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                if (mLifecycleCallback != null) {
                    mCallbackHandler.post(new Runnable() {
                        @Override
                        public void run() {
                            mLifecycleCallback.onBluetoothDeviceDisconnected();
                        }
                    });
                }
            }
        }

        @Override
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                addNewServices(mBluetoothGatt.getServices());
                if (mLifecycleCallback != null) {
                    mCallbackHandler.post(new Runnable() {
                        @Override
                        public void run() {
                            mLifecycleCallback.onBluetoothServicesDiscovered(BleDevice.this);
                        }
                    });
                }
            } else {
                //TODO
            }
        }

        @Override
        public void onCharacteristicRead(BluetoothGatt gatt,
                                         BluetoothGattCharacteristic characteristic,
                                         int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                String serviceUuid = characteristic.getService().getUuid().toString();
                if (serviceUuid == null) throw new AssertionError();

                String charcteristicUuid = characteristic.getUuid().toString();
                if (charcteristicUuid == null) throw new AssertionError();
                handleOnCharacteristicChanged(serviceUuid, charcteristicUuid);
            }
        }

        @Override
        public void onCharacteristicChanged(BluetoothGatt gatt,
                                            BluetoothGattCharacteristic characteristic) {
            String serviceUuid = characteristic.getService().getUuid().toString();
            if (serviceUuid == null) throw new AssertionError();

            String charcteristicUuid = characteristic.getUuid().toString();
            if (charcteristicUuid == null) throw new AssertionError();
            handleOnCharacteristicChanged(serviceUuid, charcteristicUuid);
        }

        @Override
        public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
            synchronized (BleDevice.this) {
                mWaitingForConfirmation = false;
                BleDevice.this.notify();
            }
        }

        @Override
        public void onReadRemoteRssi(BluetoothGatt gatt, final int rssi, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS && mLifecycleCallback != null) {
                mCallbackHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        mLifecycleCallback.onReadRemoteRssi(rssi);
                    }
                });
            }
        }
    };
    

    private void handleOnCharacteristicChanged(String serviceUuid, String charcteristicUuid) {
        final BleService bleService = mBleServices.get(UUID.fromString(serviceUuid));
        final BleCharacteristic<?> bleCharacteristic = bleService.getCharacteristic(UUID.fromString(charcteristicUuid));
        mCallbackHandler.post(new Runnable() {
            @Override
            public void run() {
                bleCharacteristic.onCharacteristicChanged();
            }
        });
    }

    /** Maximum milliseconds to wait for writeDescriptor() confirmation from the remote device */
    private final int DESCRIPTOR_WRITE_TIMEOUT = 5000;

    private BluetoothGatt mBluetoothGatt;
    private Action mAction = Action.IDLE;
    private String mDeviceAddress;
    private final Activity mActivity;
    private final LifecycleCallback mLifecycleCallback;
    private BleController mBleController = null;
    private final HashMap<UUID, BleService> mBleServices = new HashMap<UUID, BleService>();
    private final HashMap<UUID, Class<? extends BleService>> mBleServiceClasses = new HashMap<UUID, Class<? extends BleService>>();
    private int mRssi;

    /** Thread for asynchronous execution of callbacks */
    private HandlerThread mCallbackThread;

    /**
     * Handler for asynchronous execution of callbacks. If user code makes new
     * calls to Bluetooth services from within a callback, execution will be
     * blocked. Deferring callbacks to a separate thread resolves this.
     */
    private Handler mCallbackHandler;

    private boolean mWaitingForConfirmation = false;
    
    private static final String TAG = BleDevice.class.getName();
}
