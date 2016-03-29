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


#import <Foundation/Foundation.h>


typedef enum {
    GenderMale,
    GenderFemale
} Gender;

typedef enum {
    WeightMetricsKg,
    WeightMetricsLb
} WeightMetrics;

typedef enum {
    HeightMetricsCm,
    HeightMetricsIn
} HeightMetrics;

typedef enum {
    AlarmRepeatModeNever,
    AlarmRepeatModeEveryDay,
    AlarmRepeatModeEveryWeek,
    alarmRepeatModeCount
} AlarmRepeatMode;

typedef enum {
    PlaygroundTypeHeart,
    PlaygroundTypeOxygen,
    PlaygroundTypeTemperature,
    PlaygroundTypeRunning,
    PlaygroundTypeSteps,
    PlaygroundTypeEnergy
} PlaygroundType;

typedef enum {
    PlaygroundCompareTypeAbove,
    PlaygroundCompareTypeBelow,
} PlaygroundCompareType;

typedef enum {
    VibrateModeOnce,
    VibrateModeTwice,
    VibrateModeMultiple,
    vibrateModeCount
} VibrateMode;

typedef enum {
    LedMode10,
    LedMode20,
    LedMode30,
    LedMode40,
    LedMode50,
    LedMode60,
    ledModeCount
} LedMode;

typedef enum {
    ANHistoryRecordTypeNone,
    ANHistoryRecordTypeHeartRate,
    ANHistoryRecordTypeOxygen,
    ANHistoryRecordTypeTemperature,
    ANHistoryRecordTypeSteps,
    ANHistoryRecordTypeEnergy,
    ANHistoryRecordTypeOpticalWaveform1,
    ANHistoryRecordTypeOpticalWaveform2,
    ANHistoryRecordTypeAccelerometer
} ANHistoryRecordType;

@interface ANEnumManager : NSObject

+ (NSString *)stringFromRepeatMode:(AlarmRepeatMode)mode;
+ (NSString *)stringFromPlaygroundType:(PlaygroundType)type;
+ (NSString *)unitFromPlaygroundType:(PlaygroundType)type;
+ (NSString *)stringFromPlaygroundCompareType:(PlaygroundCompareType)type;
+ (NSString *)stringFromVibrateMode:(VibrateMode)mode;
+ (NSString *)stringFromLedMode:(LedMode)mode;

@end
