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
import android.bluetooth.BluetoothGattService;
import android.util.Log;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.util.HashMap;
import java.util.UUID;


/**
 * Base class for all the concrete GATT service classes.
 */
public abstract class BleService {

    public BleService(UUID uuid, BluetoothGattService gattService, BleDevice bleDevice) {
        if (!uuid.equals(gattService.getUuid())) {
            throw new AssertionError();
        }

        mUuid = uuid;
        mBaseGattService = gattService;
        mBleDevice = bleDevice;
    }


    /**
     * Creates a non-operation instance used to investigate static properties in
     * contexts where these properties are accessible only via a class instance.
     * Calling most methods of such an object will cause an undefined behavior.
     */
    public BleService(UUID uuid) {
        mUuid = uuid;
        mBaseGattService = null;
        mBleDevice = null;
    }


    public UUID getUuid() {
        return mUuid;
    }


    public BleCharacteristic<?> getCharacteristic(UUID uuid) {
        return mBleCharacteristics.get(uuid);
    }


    public BluetoothGattService getBaseGattService() {
        return mBaseGattService;
    }


    /**
     * Register a concrete characteristic class that encapsulates one of the
     * characteristics supported by the service.
     * <p>
     * Immediately after the registration creates an instance and returns it.
     * The concrete characteristic class has to follow certain rules. If one of
     * the rules is not met, an exception is thrown.
     * 
     * @param characteristicClass
     *            the concrete characteristic class
     * @throws InstantiationException
     *             failed to create an instance of the concrete characteristic
     * @throws IllegalAccessException
     *             the constructor of the concrete characteristic class is not
     *             accessible
     * @throws NoSuchMethodException
     *             a concrete characteristic must define two constructors: one
     *             without arguments and another with two arguments of types
     *             {@code BluetoothGattCharacteristic} and {@code BleDevice}
     * @throws InvocationTargetException
     *             one of the constructors on the concrete characteristic threw
     *             an exception
     */
    protected <T extends BleCharacteristic<?>> T createAndRegisterCharacteristic(Class<T> characteristicClass)
            throws InstantiationException,
                IllegalAccessException,
                NoSuchMethodException,
                InvocationTargetException {

        // Create a non-operational dummy instance only to access the UUID
        T dummyCh = characteristicClass.newInstance();
        UUID uuid = dummyCh.getUuid();

        // Check whether the service indeed supports the characteristic
        BluetoothGattCharacteristic baseCh = mBaseGattService.getCharacteristic(uuid);
        if (baseCh == null) {
            Log.e("ang", "No characteristic " + uuid + " in service " + mBaseGattService.getUuid());
            return null;
        }

        // Was the characteristic registered earlier?
        if (mBleCharacteristics.containsKey(uuid)) {
            throw new RuntimeException("Trying to register characteristic (UUID:"
                                       + uuid.toString() + ") twice inside a service (UUID:"
                                       + mBaseGattService.getUuid() + ")");
        }

        Constructor<T> ctor = characteristicClass.getConstructor(BluetoothGattCharacteristic.class,
                                                                 BleDevice.class);
        T characteristic = ctor.newInstance(baseCh, mBleDevice);

        mBleCharacteristics.put(uuid, characteristic);

        return characteristic;
    }

    private final UUID mUuid;
    private final HashMap<UUID, BleCharacteristic<?>> mBleCharacteristics = new HashMap<UUID, BleCharacteristic<?>>();
    private final BluetoothGattService mBaseGattService;
    private final BleDevice mBleDevice;
}
