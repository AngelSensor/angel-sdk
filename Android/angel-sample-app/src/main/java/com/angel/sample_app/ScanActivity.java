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
package com.angel.sample_app;

import android.app.Activity;
import android.app.Dialog;
import android.bluetooth.BluetoothDevice;
import android.content.DialogInterface;
import android.content.DialogInterface.OnDismissListener;
import android.content.Intent;
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

import com.angel.sdk.BleScanner;
import com.angel.sdk.BluetoothInaccessibleException;

import junit.framework.Assert;

/**
 * This is the main activity of the sample application. It displays UI that
 * allows to scan for Bluetooth devices, connect to one of them and retrieve
 * heart rate measurements.
 */
public class ScanActivity extends Activity implements OnClickListener {

    private static final int IDLE = 0;
    private static final int SCANNING = 1;
    private static final int CONNECTED = 2;

    private BleScanner mBleScanner;
    private RelativeLayout mControl;
    private TextView mControlAction;

    private Dialog mDeviceListDialog;
    private ListItemsAdapter mDeviceListAdapter;

    static private int sState = IDLE;

    /**
     * Adds discovered Bluetooth devices to the devices list. After that user
     * can click the device to connect to it.
     */
    BleScanner.ScanCallback mScanCallback = new BleScanner.ScanCallback() {
        @Override
        public void onBluetoothDeviceFound(BluetoothDevice device) {
            if (device.getName() != null && device.getName().startsWith("Angel")) {
                ListItem newDevice = new ListItem(device.getName(), device.getAddress(), device);
                mDeviceListAdapter.add(newDevice);
                mDeviceListAdapter.addItem(newDevice);
                mDeviceListAdapter.notifyDataSetChanged();
            }
        }
    };


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mControl = (RelativeLayout) findViewById(R.id.control);
        mControl.setOnClickListener(this);

        mControlAction = (TextView) findViewById(R.id.controlAction);

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
//            disconnect();
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

        // Initialize the of the Ble Scanner.
        try {
            if (mBleScanner == null) {

                mBleScanner = new BleScanner(this, mScanCallback);
            }
        } catch (BluetoothInaccessibleException e) {
            throw new AssertionError("Bluetooth is not accessible");
        }

        lockOrientation();

        sState = SCANNING;
        mBleScanner.startScan();
        showDeviceListDialog();
    }


    private void stopScan() {
        if (sState == SCANNING) {
            mBleScanner.stopScan();
            sState = IDLE;
            releaseOrientation();
        }
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
            public void onItemClick(AdapterView<?> parent, View item, int position, long id) {
                stopScan();
                mDeviceListDialog.dismiss();

                BluetoothDevice bluetoothDevice = mDeviceListAdapter.getItem(position).getBluetoothDevice();
                Assert.assertTrue(bluetoothDevice != null);
                Intent intent = new Intent(parent.getContext(), HomeActivity.class);
                intent.putExtra("ble_device_address", bluetoothDevice.getAddress());
                startActivity(intent);
            }
        });

        mDeviceListDialog.setOnDismissListener(new OnDismissListener() {
            @Override
            public void onDismiss(DialogInterface dialog) {
                stopScan();
            }
        });
        mDeviceListDialog.show();
    }

    protected void onStop() {
        super.onStop();
        stopScan();
    }
}
