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
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.pm.PackageManager;
import android.os.Handler;

import java.util.TreeSet;


/**
 * Scans for available Bluetooth devices.
 * <p>
 * This class gives a concise interface for Bluetooth devices discovery. Each
 * discovered device is reported via a callback object configured in the
 * constructor.
 */
public class BleScanner {

    /**
     * {@code BleScanner} reports about the discovered devices using this
     * interface.
     * <p>
     * Each device is reported only once.
     */
    public interface ScanCallback {
        public void onBluetoothDeviceFound(BluetoothDevice device);
    }


    /**
     * Creates and configures a new {@code BleScanner} instance.
     * 
     * @param activity
     *            the Android activity that owns the object
     * @param scanCallback
     *            the callback object that will handle the device discovery
     * @throws BluetoothInaccessibleException
     *             thrown if the Bluetooth device is unaccessible
     */
    public BleScanner(Activity activity, ScanCallback scanCallback)
            throws BluetoothInaccessibleException {

        if (!activity.getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
            throw new BluetoothInaccessibleException();
        }

        mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        if (mBluetoothAdapter == null) {
            throw new BluetoothInaccessibleException();
        }

        mUserScanCallback = scanCallback;
        mActivity = activity;
        mScanHandler = new Handler();
    }


    /**
     * Scan for 10 seconds, report discovered devices, stop scanning.
     */
    public void startScan() {
        mScanStopper = new Runnable() {
            @Override
            public void run() {
                stopScan();
            }
        };
        mScanHandler.postDelayed(mScanStopper, SCAN_PERIOD_MILLIS);
        mBluetoothAdapter.startLeScan(mBleAdapterScanCallback);
    }


    public void stopScan() {
        mScanHandler.removeCallbacks(mScanStopper);
        mBluetoothAdapter.stopLeScan(mBleAdapterScanCallback);
    }

    /**
     * This callback is called each time BluetoothAdapter#startLeScan()
     * discovers a device. Note that it might be called more than once for a
     * device.
     */
    private final BluetoothAdapter.LeScanCallback mBleAdapterScanCallback = new BluetoothAdapter.LeScanCallback() {
        @Override
        public void onLeScan(final BluetoothDevice device, int rssi, byte[] scanRecord) {
        if (!mDeviceAddresses.contains(device.getAddress())) {
            mDeviceAddresses.add(device.getAddress());

            mActivity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                mUserScanCallback.onBluetoothDeviceFound(device);
                }
            });
        }
        }
    };

    private static final long SCAN_PERIOD_MILLIS = 10000;
    private final BluetoothAdapter mBluetoothAdapter;

    private final Activity mActivity;
    private final ScanCallback mUserScanCallback;
    private final Handler mScanHandler;
    private Runnable mScanStopper;

    /** A collection of addresses of all the discovered devices */
    private final TreeSet<String> mDeviceAddresses = new TreeSet<String>();
}
