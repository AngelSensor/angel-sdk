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


#import "ANEnumManager.h"

@implementation ANEnumManager

+ (NSString *)stringFromRepeatMode:(AlarmRepeatMode)mode {
    switch (mode) {
        case AlarmRepeatModeEveryDay: {
            return NSLocalizedString(@"Every Day", nil);
        } break;
        case AlarmRepeatModeEveryWeek: {
            return NSLocalizedString(@"Every Week", nil);
        } break;
        case AlarmRepeatModeNever: {
            return NSLocalizedString(@"Never", nil);
        } break;
        default: {
            return nil;
        } break;
    }
    return nil;
}

+ (NSString *)stringFromPlaygroundType:(PlaygroundType)type {
    switch (type) {
        case PlaygroundTypeHeart: {
            return NSLocalizedString(@"Heart Rate", nil);
        } break;
        case PlaygroundTypeOxygen: {
            return NSLocalizedString(@"Oxygen Level", nil);
        } break;
        case PlaygroundTypeEnergy: {
            return NSLocalizedString(@"Energy", nil);
        } break;
        case PlaygroundTypeRunning: {
            return NSLocalizedString(@"Running", nil);
        } break;
        case PlaygroundTypeSteps: {
            return NSLocalizedString(@"Steps", nil);
        } break;
        case PlaygroundTypeTemperature: {
            return NSLocalizedString(@"Temperature", nil);
        } break;
        default: {
            return nil;
        } break;
    }
    return nil;
}

+ (NSString *)unitFromPlaygroundType:(PlaygroundType)type {
    switch (type) {
        case PlaygroundTypeHeart: {
            return NSLocalizedString(@"BPM", nil);
        } break;
        case PlaygroundTypeOxygen: {
            return NSLocalizedString(@"%", nil);
        } break;
        case PlaygroundTypeEnergy: {
            return NSLocalizedString(@"Kcal", nil);
        } break;
        case PlaygroundTypeRunning: {
            return NSLocalizedString(@"Unit", nil);
        } break;
        case PlaygroundTypeSteps: {
            return NSLocalizedString(@"Steps", nil);
        } break;
        case PlaygroundTypeTemperature: {
            return NSLocalizedString(@"°C", nil);
        } break;
        default: {
            return nil;
        } break;
    }
    return nil;
}

+ (NSString *)stringFromPlaygroundCompareType:(PlaygroundCompareType)type {
    switch (type) {
        case PlaygroundCompareTypeAbove: {
            return NSLocalizedString(@"Above", nil);
        } break;
        case PlaygroundCompareTypeBelow: {
            return NSLocalizedString(@"Below", nil);
        } break;
        default: {
            return nil;
        } break;
    }
    return nil;
}

+ (NSString *)stringFromVibrateMode:(VibrateMode)type {
    switch (type) {
        case VibrateModeMultiple: {
            return NSLocalizedString(@"Multiple", nil);
        } break;
        case VibrateModeOnce: {
            return NSLocalizedString(@"Once", nil);
        } break;
        case VibrateModeTwice: {
            return NSLocalizedString(@"Twice", nil);
        } break;
        default: {
            return nil;
        } break;
    }
    return nil;
}

+ (NSString *)stringFromLedMode:(LedMode)mode {
    switch (mode) {
        case LedMode10: {
            return NSLocalizedString(@"10s", nil);
        } break;
        case LedMode20: {
            return NSLocalizedString(@"20s", nil);
        } break;
        case LedMode30: {
            return NSLocalizedString(@"30s", nil);
        } break;
        case LedMode40: {
            return NSLocalizedString(@"40s", nil);
        } break;
        case LedMode50: {
            return NSLocalizedString(@"50s", nil);
        } break;
        case LedMode60: {
            return NSLocalizedString(@"60s", nil);
        } break;
        default: {
            return nil;
        } break;
    }
    return nil;
}

@end
