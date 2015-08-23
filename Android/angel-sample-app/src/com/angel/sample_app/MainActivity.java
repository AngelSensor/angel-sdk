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
package com.angel.sample_app;

import android.app.Activity;
import android.app.Dialog;
import android.bluetooth.BluetoothDevice;
import android.content.DialogInterface;
import android.content.DialogInterface.OnDismissListener;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.angel.sdk.BleCharacteristic;
import com.angel.sdk.BleDevice;
import com.angel.sdk.BleScanner;
import com.angel.sdk.BluetoothUnaccessibleException;
import com.angel.sdk.SrvHeartRate;


/**
 * This is the main activity of the sample application. It displays UI that
 * allows to scan for Bluetooth devices, connect to one of them and retrieve
 * heart rate measurements.
 */
public class MainActivity extends Activity implements OnClickListener {

    private static final int IDLE = 0;
    private static final int SCANNING = 1;
    private static final int CONNECTED = 2;

    private TextView mHeartRate;
    private BleScanner mBleScanner;
    private BleDevice mBleDevice;

    private RelativeLayout mControl;
    private TextView mControlAction;

    private Dialog mDeviceListDialog;
    private ListItemsAdapter mDeviceListAdapter;

    private SrvHeartRate mHeartRateService;

    static private int sState = IDLE;

    /**
     * Handles incoming heart rate readings
     */
    private final BleCharacteristic.ValueReadyCallback<Integer> mHeartRateListener = new BleCharacteristic.ValueReadyCallback<Integer>() {
        @Override
        public void onValueReady(Integer hrMeasurement) {
            String currHeartRate = String.valueOf(hrMeasurement);
            mHeartRate.setText(currHeartRate);
        }
    };

    /**
     * Upon Heart Rate Service discovery starts listening to incoming heart rate
     * notifications. {@code onBluetoothServicesDiscovered} is triggered after
     * {@link BleDevice#connect(String)} is called.
     */
    private final BleDevice.LifecycleCallback mDeviceLifecycleCallback = new BleDevice.LifecycleCallback() {
        @Override
        public void onBluetoothServicesDiscovered() {
            sState = CONNECTED;
            setControlActionText();

            mHeartRateService = mBleDevice.getService(SrvHeartRate.class);
            if (mHeartRateService != null) {
                mHeartRateService.getHeartRateMeasurement().enableNotifications(mHeartRateListener);
            }
        }


        @Override
        public void onBluetoothDeviceDisconnected() {
            sState = IDLE;
            setControlActionText();
            mHeartRate.setText("");
        }
    };

    /**
     * Adds discovered Bluetooth devices to the devices list. After that user
     * can click the device to connect to it.
     */
    BleScanner.ScanCallback mScanCallback = new BleScanner.ScanCallback() {
        @Override
        public void onBluetoothDeviceFound(BluetoothDevice device) {

            ListItem newDevice = new ListItem(device.getName(), device.getAddress(), device);
            mDeviceListAdapter.add(newDevice);
            mDeviceListAdapter.addItem(newDevice);
            mDeviceListAdapter.notifyDataSetChanged();
        }
    };


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mHeartRate = (TextView) findViewById(R.id.heartRate);
        mControl = (RelativeLayout) findViewById(R.id.control);
        mControl.setOnClickListener(this);

        mControlAction = (TextView) findViewById(R.id.controlAction);

        // Just initialize the scanner. The scan itself start upon user request
        try {
            mBleScanner = new BleScanner(this, mScanCallback);
        } catch (BluetoothUnaccessibleException e) {
            throw new AssertionError("Bluetooth is not accessible");
        }

        mDeviceListAdapter = new ListItemsAdapter(this, R.layout.list_item);
    }


    @Override
    protected void onResume() {
        super.onResume();

        setControlActionText();
    }


    @Override
    public void onClick(View v) {
        switch (sState) {
        case IDLE:
            startScan();
            break;
        case SCANNING:
            stopScan();
            break;
        case CONNECTED:
            disconnect();
            break;
        }
        setControlActionText();
    }


    private void lockOrientation() {
        int currentOrientation = getResources().getConfiguration().orientation;
        if (currentOrientation == Configuration.ORIENTATION_LANDSCAPE) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
        } else {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT);
        }
    }


    private void releaseOrientation() {
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR);
    }


    private void startScan() {

        lockOrientation();

        sState = SCANNING;
        mBleScanner.startScan();
        showDeviceListDialog();
    }


    private void stopScan() {
        mBleScanner.stopScan();
        sState = IDLE;
        setControlActionText();
        releaseOrientation();

    }


    private void disconnect() {
        mBleDevice.disconnect();
    }


    private void setControlActionText() {
        switch (sState) {
        case IDLE:
            mControlAction.setText(R.string.scan);
            break;
        case SCANNING:
            mControlAction.setText(R.string.scanning);
            break;
        case CONNECTED:
            mControlAction.setText(R.string.disconnect);
            break;
        }
    }


    private void showDeviceListDialog() {
        mDeviceListDialog = new Dialog(this);
        mDeviceListDialog.setTitle("Select A Device");
        mDeviceListDialog.setContentView(R.layout.device_list);
        ListView lv = (ListView) mDeviceListDialog.findViewById(R.id.lv);
        lv.setAdapter(mDeviceListAdapter);
        lv.setOnItemClickListener(new OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> arg0, View item, int position, long arg3) {

                // A device has been chosen from the list. Create an instance of BleDevice,
                // populate it with interesting services and then connect

                mBleDevice = new BleDevice(MainActivity.this, mDeviceLifecycleCallback);

                try {
                    mBleDevice.registerServiceClass(SrvHeartRate.class);
                } catch (NoSuchMethodException e) {
                    throw new AssertionError();
                } catch (IllegalAccessException e) {
                    throw new AssertionError();
                } catch (InstantiationException e) {
                    throw new AssertionError();
                }

                BluetoothDevice bluetoothDevice = mDeviceListAdapter.getItem(position).getBluetoothDevice();
                mBleDevice.connect(bluetoothDevice.getAddress());
                mDeviceListDialog.dismiss();
            }
        });

        mDeviceListDialog.setOnDismissListener(new OnDismissListener() {
            @Override
            public void onDismiss(DialogInterface dialog) {
                if (sState == SCANNING) {
                    stopScan();
                }
            }
        });
        mDeviceListDialog.show();

    }

}
