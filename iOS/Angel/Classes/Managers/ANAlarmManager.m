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


#import "ANAlarmManager.h"
#import "ANAlarmClockService.h"
#import "ANAlarmClockControlPointCharacteristic.h"
#import "ANAlarm.h"
#import "NSDate+Utilities.h"

#define kAlarmsFile @"alarms"

@interface ANAlarmManager ()

@property (nonatomic, strong) ANAlarmClockService *service;

@property (nonatomic, strong) NSMutableArray *alarmsList;

@property NSInteger maxSupportedAlarms;
@property NSInteger numberOfAlarms;

@property NSUInteger currentIndex;

@property (nonatomic, strong) ANAlarm *currentAlarm;

@property (copy) SimpleSuccessBlock alarmOperationSuccessBlock;

@end

@implementation ANAlarmManager

- (UInt16)accessKey {
    return 0x000000;//_service.featureChar.accessCode;
}

- (instancetype)initWithService:(ANAlarmClockService *)service {
    self = [super init];
    if (self) {
        _service = service;
        __weak ANAlarmManager *wSelf = self;
        
        [[ANDataManager sharedManager] alarmClockWithHandler:^(ANAlarmClockResponseCode response, UInt16 value) {
            [wSelf handleServiceResponse:response value:value];
        }];
        self.stage = ANAlarmStageDateTime;
        
    }
    return self;
}

- (void)setStage:(ANAlarmStage)stage {
    if (stage != _stage) {
        _stage = stage;
        switch (stage) {
            case ANAlarmStageDateTime: {
                [self updateDateTime];
            } break;
            case ANAlarmStageMaxSupportedAlarms: {
                [self loadMaxSupportedAlarms];
            } break;
            case ANAlarmStageNumberOfAlarmsDefined: {
                [self loadNumberOfAlarms];
            } break;
            case ANAlarmStageReadAlarms: {
                self.currentIndex = 0;
                [self loadAlarmsList];
            } break;
            default: {
            } break;
        }
    }
}

- (void)updateDateTime {
    [self.service.controlPointChar setAlarmClockDateTime:[NSDate date]];
}

- (void)loadMaxSupportedAlarms {
    [self.service.controlPointChar getMaxSupportedAlarms];
}

- (void)loadNumberOfAlarms {
    [self.service.controlPointChar getNumberOfAlarmsDefined];
}

- (void)loadAlarmsList {
    self.currentIndex = 0;
    [self loadAlarm:self.currentIndex];
}

- (void)loadAlarm:(NSInteger)alarmID {
    [self.service.controlPointChar readAlarm:alarmID];
}

- (NSMutableArray *)alarmsList {
    if (!_alarmsList) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *path = [self filePathForName:kAlarmsFile];
        if ([fileManager fileExistsAtPath:path]) {
            NSData *data = [NSData dataWithContentsOfFile:[self filePathForName:kAlarmsFile]];
            
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            NSArray *result = [unarchiver decodeObjectForKey:kAlarmsFile];
            [unarchiver finishDecoding];
            
            NSMutableArray *tempArray = [NSMutableArray new];
            
            for (ANAlarm *alarm in result) {
                if ([alarm.alarmTime isLaterThanDate:[NSDate date]]) {
                    [tempArray addObject:alarm];
                }
            }
            
            _alarmsList = [[NSMutableArray alloc] initWithArray:tempArray];
        } else {
            _alarmsList = [NSMutableArray new];
        }
    }
    return _alarmsList;
}

- (void)alarmsListWithCompletionHandler:(AlarmsListBlock)completionHandler {
    if (completionHandler) {
        completionHandler(self.alarmsList, nil);
    }
}

- (void)saveAlarmList {
    NSMutableData *data = [NSMutableData data];
    
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver setOutputFormat:NSPropertyListBinaryFormat_v1_0];
    [archiver encodeObject:self.alarmsList forKey:kAlarmsFile];
    [archiver finishEncoding];
    
    [data writeToFile:[self filePathForName:kAlarmsFile] atomically:YES];
}

- (NSString *)filePathForName:(NSString *)name {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:name];
}

- (void)handleAlarmCallback:(NSError *)error {
    if (self.alarmOperationSuccessBlock) {
        self.alarmOperationSuccessBlock(error ? NO : YES, error);
    }
}

#pragma mark Alarms updating

- (void)addAlarm:(ANAlarm *)alarm completionHandler:(SimpleSuccessBlock)completionHandler {
    self.alarmOperationSuccessBlock = completionHandler;
//    if (self.alarmsList.count < self.maxSupportedAlarms) {
    self.currentAlarm = alarm;
    self.stage = ANAlarmStageAddAlarm;
    [self.service.controlPointChar addAlarm:alarm.alarmTime];
    [self handleServiceResponse:ANAlarmClockResponseCodeSuccess value:192];
//    } else {
//        [self handleAlarmCallback:[NSError errorWithDomain:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__] code:MaximumAmountOfAlarmsReachedErrorCode userInfo:nil]];
//    }
}

- (void)updateAlarm:(ANAlarm *)alarm completionHandler:(SimpleSuccessBlock)completionHandler {
    self.alarmOperationSuccessBlock = completionHandler;
    self.currentAlarm = alarm;
    self.stage = ANAlarmStageUpdateRemoveAlarm;
    [self.service.controlPointChar removeAlarm:alarm.alarmID.intValue];
}

- (void)removeAlarm:(ANAlarm *)alarm completionHandler:(SimpleSuccessBlock)completionHandler {
    self.alarmOperationSuccessBlock = completionHandler;
    self.currentAlarm = alarm;
    self.stage = ANAlarmStageRemoveAlarm;
    [self.service.controlPointChar removeAlarm:alarm.alarmID.intValue];
    [self handleServiceResponse:ANAlarmClockResponseCodeSuccess value:192];
}

- (void)removeAllAlarms {
    self.stage = ANAlarmStageRemoveAllAlarms;
    [self.service.controlPointChar removeAllAlarms];
    [[NSFileManager defaultManager] removeItemAtPath:[self filePathForName:kAlarmsFile] error:nil];
    [self.alarmsList removeAllObjects];
    [self handleAlarmCallback:nil];
}

- (void)handleServiceResponse:(ANAlarmClockResponseCode)code value:(uint8_t)value {
    if (code == ANAlarmClockResponseCodeSuccess) {
        switch (self.stage) {
            case ANAlarmStageDateTime: {
                self.stage = ANAlarmStageMaxSupportedAlarms;
            } break;
            case ANAlarmStageMaxSupportedAlarms: {
                self.maxSupportedAlarms = value;
            } break;
            case ANAlarmStageAddAlarm: {
                self.currentAlarm.alarmID = @(value);
                self.currentAlarm.alarmEnabled = YES;
                [self.alarmsList addObject:self.currentAlarm];
                [self saveAlarmList];
                self.stage = ANAlarmStageNone;
                [self handleAlarmCallback:nil];
            } break;
            case ANAlarmStageUpdateRemoveAlarm: {
                self.stage = ANAlarmStageUpdateAddAlarm;
            } break;
            case ANAlarmStageUpdateAddAlarm: {
                self.currentAlarm.alarmID = @(value);
                [self saveAlarmList];
                self.stage = ANAlarmStageNone;
                [self handleAlarmCallback:nil];
            } break;
            case ANAlarmStageRemoveAlarm: {
                [self.alarmsList removeObject:self.currentAlarm];
                [self saveAlarmList];
                self.stage = ANAlarmStageNone;
                [self handleAlarmCallback:nil];
            } break;
            default: {
                
            } break;
        }
    } else {
        [self handleAlarmCallback:[NSError errorWithDomain:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__] code:code userInfo:nil]];
    }
}

@end
