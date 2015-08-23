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

import java.util.UUID;


/**
 * Base class for all the concrete characteristic classes.
 */
public abstract class BleCharacteristic<ValueType> {

    public BleCharacteristic(UUID uuid,
                             BluetoothGattCharacteristic gattCharacteristic,
                             BleDevice bleDevice) {
        if (!uuid.equals(gattCharacteristic.getUuid())) {
            throw new AssertionError();
        }
        mUuid = uuid;
        mBaseGattCharacteristic = gattCharacteristic;
        mBleDevice = bleDevice;
    }


    /**
     * Creates a non-operation instance used to investigate static properties in
     * contexts where these properties are accessible only via a class instance.
     * Calling most methods of such an object will cause an undefined behavior.
     */
    public BleCharacteristic(UUID uuid) {
        mUuid = uuid;
        mBaseGattCharacteristic = null;
        mBleDevice = null;
    }


    public UUID getUuid() {
        return mUuid;
    }


    public BluetoothGattCharacteristic getBaseGattCharacteristic() {
        return mBaseGattCharacteristic;
    }


    public BleDevice getBleDevice() {
        return mBleDevice;
    }


    /** Used to report characteristic value asynchronously */
    public interface ValueReadyCallback<T> {
        public void onValueReady(T value);
    }


    /**
     * Enable notifications for the characteristic. The actual notifications are
     * asynchronous and are delivered via the supplied callback.
     */
    public void enableNotifications(ValueReadyCallback<ValueType> callback) {
        mOnDataReadyListener = callback;
        mBleDevice.enableCharacteristicNotifications(this.mBaseGattCharacteristic);
    }

    /**
     * Request characteristic value. The value is returned asynchronously via
     * the supplied callback.
     */
    public void readValue(ValueReadyCallback<ValueType> callback) {
        mOnDataReadyListener = callback;
        mBleDevice.readCharacteristic(this.mBaseGattCharacteristic);
    }


    protected final void onCharacteristicChanged() {
        ValueType value = processCharacteristicValue();
        mOnDataReadyListener.onValueReady(value);
    };


    /**
     * Converts the raw characteristic value into the human friendly ValueType.
     * <p>
     * For example, a heart rate measurement may contain both the heart rate
     * value and several RR-intervals. BluetoothGattCharacteristic returns the
     * value as a byte array. The purpose of this method is to parse the byte
     * array and create a strongly typed data structure.
     * <p>
     * The implementation is expected to call
     * {@link #getBaseGattCharacteristic()} to access the underlying
     * characteristic and use one of its {@code get*Value} methods to get the
     * raw characteristic value.
     */
    protected abstract ValueType processCharacteristicValue();

    private final UUID mUuid;
    private final BluetoothGattCharacteristic mBaseGattCharacteristic;
    private final BleDevice mBleDevice;
    private ValueReadyCallback<ValueType> mOnDataReadyListener;

}
