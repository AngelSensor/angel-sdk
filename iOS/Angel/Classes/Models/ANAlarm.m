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


#import "ANAlarm.h"

#define kAlarmID @"alarmID"
#define kAlarmName @"alarmName"
#define kAlarmSoundID @"alarmSoundID"
#define kAlarmTime @"alarmTime"
#define kAlarmRepeatMode @"alarmRepeatMode"
#define kAlarmEnabled @"alarmEnabled"
#define kAlarmVibrate @"alarmVibrate"

@implementation ANAlarm

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.alarmID = [aDecoder decodeObjectForKey:kAlarmID];
        self.alarmName = [aDecoder decodeObjectForKey:kAlarmName];
        self.alarmSoundID = [aDecoder decodeObjectForKey:kAlarmSoundID];
        self.alarmTime = [aDecoder decodeObjectForKey:kAlarmTime];
        self.alarmRepeatMode = (AlarmRepeatMode)[aDecoder decodeIntegerForKey:kAlarmRepeatMode];
        self.alarmEnabled = [aDecoder decodeBoolForKey:kAlarmEnabled];
        self.alarmVibrate = [aDecoder decodeBoolForKey:kAlarmVibrate];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.alarmID forKey:kAlarmID];
    [aCoder encodeObject:self.alarmName forKey:kAlarmName];
    [aCoder encodeObject:self.alarmSoundID forKey:kAlarmSoundID];
    [aCoder encodeObject:self.alarmTime forKey:kAlarmTime];
    [aCoder encodeInteger:self.alarmRepeatMode forKey:kAlarmRepeatMode];
    [aCoder encodeBool:self.alarmEnabled forKey:kAlarmEnabled];
    [aCoder encodeBool:self.alarmVibrate forKey:kAlarmVibrate];
}

- (id)copyWithZone:(NSZone *)zone {
    ANAlarm *instance = [[[self class] allocWithZone:zone] init];
    instance.alarmID = self.alarmID;
    instance.alarmName = self.alarmName;
    instance.alarmSoundID = self.alarmSoundID;
    instance.alarmTime = self.alarmTime;
    instance.alarmRepeatMode = self.alarmRepeatMode;
    instance.alarmEnabled = self.alarmEnabled;
    instance.alarmVibrate = self.alarmVibrate;
    return instance;
}

- (void)updateFromCopy:(ANAlarm *)alarm {
    self.alarmID = alarm.alarmID;
    self.alarmName = alarm.alarmName;
    self.alarmSoundID = alarm.alarmSoundID;
    self.alarmTime = alarm.alarmTime;
    self.alarmRepeatMode = alarm.alarmRepeatMode;
    self.alarmEnabled = alarm.alarmEnabled;
    self.alarmVibrate = alarm.alarmVibrate;
}

@end
