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

@class ANAlarmClockService;

typedef NS_ENUM(NSUInteger, ANAlarmStage) {
    ANAlarmStageNone,
    ANAlarmStageNotActive,
    ANAlarmStageDateTime,
    ANAlarmStageMaxSupportedAlarms,
    ANAlarmStageNumberOfAlarmsDefined,
    ANAlarmStageReadAlarms,
    ANAlarmStageAddAlarm,
    ANAlarmStageUpdateRemoveAlarm,
    ANAlarmStageUpdateAddAlarm,
    ANAlarmStageRemoveAlarm,
    ANAlarmStageRemoveAllAlarms
};

typedef void (^AlarmsListBlock) (NSArray *result, NSError *error);

@interface ANAlarmManager : NSObject

@property (nonatomic) ANAlarmStage stage;

- (instancetype)initWithService:(ANAlarmClockService *)service;

- (void)alarmsListWithCompletionHandler:(AlarmsListBlock)completionHandler;
- (void)addAlarm:(ANAlarm *)alarm completionHandler:(SimpleSuccessBlock)completionHandler;
- (void)updateAlarm:(ANAlarm *)alarm completionHandler:(SimpleSuccessBlock)completionHandler;
- (void)removeAlarm:(ANAlarm *)alarm completionHandler:(SimpleSuccessBlock)completionHandler;
- (void)removeAllAlarms;

@end
