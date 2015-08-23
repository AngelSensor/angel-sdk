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

import java.util.Calendar;
import java.util.GregorianCalendar;


/**
 * Serializes dates into the BLE standard type
 * org.bluetooth.characteristic.day_date_time
 */
public class BleDayDateTime {

    public static final int DAY_DATE_SERIALIZED_SIZE = 8;
    public static final int DATE_SERIALIZED_SIZE = 7;


    public static GregorianCalendar Deserialize(byte[] data) {
        if (data.length != DATE_SERIALIZED_SIZE && data.length != DAY_DATE_SERIALIZED_SIZE) {
            throw new RuntimeException("Trying to deserialize a date from a buffer of wrong size");
        }

        int year = data[1] & 0xFF;
        year = year << 8;
        year = year | (data[0] & 0xFF);
        int month = data[2];
        int day = data[3];
        int hour = data[4];
        int minutes = data[5];
        int seconds = data[6];
        return new GregorianCalendar(year, month - 1, day, hour, minutes, seconds);
    }


    public static byte[] SerializeDayDateTime(GregorianCalendar dateTime) {
        int year = dateTime.get(Calendar.YEAR);
        int month = dateTime.get(Calendar.MONTH);
        int day = dateTime.get(Calendar.DAY_OF_MONTH);
        int hour = dateTime.get(Calendar.HOUR_OF_DAY);
        int minutes = dateTime.get(Calendar.MINUTE);
        int seconds = dateTime.get(Calendar.SECOND);
        int dayOfWeek = dateTime.get(Calendar.DAY_OF_WEEK);

        byte[] data = new byte[DAY_DATE_SERIALIZED_SIZE];
        data[0] = (byte) (year & 0x00FF);
        data[1] = (byte) ((year & 0xFF00) >> 8);
        data[2] = (byte) (month + 1); // GregorianCalendar months are zero based
        data[3] = (byte) day;
        data[4] = (byte) hour;
        data[5] = (byte) minutes;
        data[6] = (byte) seconds;
        data[7] = (byte) dayOfWeek;

        return data;
    }


    public static byte[] SerializeDateTime(GregorianCalendar dateTime) {
        int year = dateTime.get(Calendar.YEAR);
        int month = dateTime.get(Calendar.MONTH);
        int day = dateTime.get(Calendar.DAY_OF_MONTH);
        int hour = dateTime.get(Calendar.HOUR_OF_DAY);
        int minutes = dateTime.get(Calendar.MINUTE);
        int seconds = dateTime.get(Calendar.SECOND);

        byte[] data = new byte[DATE_SERIALIZED_SIZE];
        data[0] = (byte) (year & 0x00FF);
        data[1] = (byte) ((year & 0xFF00) >> 8);
        data[2] = (byte) (month + 1); // GregorianCalendar months are zero based
        data[3] = (byte) day;
        data[4] = (byte) hour;
        data[5] = (byte) minutes;
        data[6] = (byte) seconds;

        return data;
    }

}
