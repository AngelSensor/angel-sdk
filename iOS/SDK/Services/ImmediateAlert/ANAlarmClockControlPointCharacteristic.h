/*
 * Copyright (c) 2016, Seraphim Sense Ltd.
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


#import "ANCharacteristic.h"

#define kAlarmClockControlPointCharacteristicUUIDString @"E4616B0C-22D5-11E4-A7BF-B2227CCE2B54"


typedef NS_ENUM(UInt8, ANAlarmClockResponseCode) {
    ANAlarmClockResponseCodeUnknown =           0x00,
    ANAlarmClockResponseCodeSuccess =           0x01,
    ANAlarmClockResponseCodeNotSupported =      0x02,
    ANAlarmClockResponseCodeInvalidOperator =   0x03,
    ANAlarmClockResponseCodeInvalidOperand =    0x04
};

typedef NS_ENUM(UInt8, ANAlarmClockOpCode) {
    ANAlarmClockOpCodeGetMaxAlarms =        0x01,
    ANAlarmClockOpCodeGetCurrentAlarms =    0x02,
    ANAlarmClockOpCodeReadAlarm =           0x03,
    ANAlarmClockOpCodeAddAlarm =            0x04,
    ANAlarmClockOpCodeRemoveAlarm =         0x05,
    ANAlarmClockOpCodeRemoveAllAlarms =     0x06,
    ANAlarmClockOpCodeSetClock =            0x07,
};

@interface ANAlarmClockControlPointCharacteristic : ANCharacteristic

@property (nonatomic) ANAlarmClockResponseCode  responseCode;
@property (nonatomic) UInt16                    responseValue;

- (void)getMaxSupportedAlarms;
- (void)getNumberOfAlarmsDefined;
- (void)readAlarm:(UInt8)alarmID;
- (void)addAlarm:(NSDate *)date;
- (void)removeAlarm:(UInt8)alarmID;
- (void)removeAllAlarms;
- (void)setAlarmClockDateTime:(NSDate *)date;

@end
