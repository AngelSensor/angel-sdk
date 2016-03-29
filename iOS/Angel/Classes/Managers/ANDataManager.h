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
#import "ANHistoryItem.h"
#import "ANFirmwareUpdateConrolPointCharacteristic.h"
#import "ANAlarmClockControlPointCharacteristic.h"

#define kValue @"randomValue"
#define kDuration @"randomDuration"

@class ANAccount, ANPeripheral, ANAlarm, ANPlayground;

static BOOL sensorMode = YES;

typedef void (^RefreshBlock) (NSNumber *result);
typedef void (^SimpleResultBlock) (NSArray *result, NSError *error);
typedef void (^WaveformResultBlock) (NSArray *waveformData, NSArray *accelerometerData, NSError *error);
typedef void (^ConnectPeripheralBlock) (BOOL success, NSError *error);
typedef void (^SimpleSuccessBlock) (BOOL success, NSError *error);
typedef void (^CheckUpdateBlock) (BOOL success, NSDictionary *info, NSError *error);
typedef void (^ProgressBlock) (NSNumber *progress);
typedef void (^FirmwareUpdateResponseBlock) (ANFWResponseCode response, UInt16 value);
typedef void (^AlarmClockResponseBlock) (ANAlarmClockResponseCode response, UInt16 value);
typedef void (^UpdateLog) (NSString* log);
typedef void (^UpdateComplite)(void);

typedef enum {
    ServiceEnableModeNone,
    ServiceEnableModePortrait,
    ServiceEnableModeLandscape,
    ServiceEnableModeFWUpdate
} ServiceEnableMode;

@interface ANDataManager : NSObject

@property (nonatomic, strong) ANPeripheral *        currentWristband;

@property (nonatomic, strong) NSDateFormatter *     mdFormatter;
@property (nonatomic, strong) NSDateFormatter *     hmaFormatter;
@property (nonatomic, strong) NSDateFormatter *     birthdayFormatter;
@property (nonatomic, strong) NSDateFormatter *     alarmFormatter;

@property (nonatomic, strong) NSNumberFormatter *   numberFormatter;

@property (nonatomic, strong) NSDictionary *        updateInfo;
@property (nonatomic) BOOL                          updating;

@property (nonatomic) ServiceEnableMode             serviceEnableMode;

@property (nonatomic) BOOL                          connectionRequestedButManagerStateIsNotOn;

@property (nonatomic, strong) NSString *            firmwareVersion;
@property (nonatomic, assign) BOOL                  isUpdateMode;
@property (nonatomic, assign) BOOL                  isLandscapeMode;


@property NSInteger batteryStatus;
@property NSInteger signalStrength;

+ (id)sharedManager;

#pragma mark Wristbands Handling
- (void)searchPeripheralWithCompletionHandler:(SimpleResultBlock)completionHandler;
- (void)connectedPeripheralsWithCompletionHandler:(void(^)(NSArray *result, NSError *error))completionHandler;
- (void)connectPeripheral:(ANPeripheral *)peripheral completionHandler:(ConnectPeripheralBlock)completionHandler;
- (void)connectStoredPeripheralWithCompletionHandler:(ConnectPeripheralBlock)completionHandler;

- (BOOL)connectedPeripheralsExists;
- (void)startScanningForPeripherals;
- (void)stopScanningForPeripherals;
- (void)forgetDevice;

#pragma mark Alarms handling
- (void)alarmsListWithCompletionHandler:(void(^)(NSArray *result, NSError *error))completionHandler;
- (void)alarmClockWithHandler:(AlarmClockResponseBlock)refreshHandler;
- (void)addAlarm:(ANAlarm *)alarm completionHandler:(SimpleSuccessBlock)completionHandler;
- (void)updateAlarm:(ANAlarm *)alarm completionHandler:(SimpleSuccessBlock)completionHandler;
- (void)removeAlarm:(ANAlarm *)alarm completionHandler:(SimpleSuccessBlock)completionHandler;

#pragma mark Playground handling
- (void)playgroundListWithCompletionHandler:(void(^)(NSArray *result, NSError *error))completionHandler;
- (void)addPlayground:(ANPlayground *)playground completionHandler:(SimpleSuccessBlock)completionHandler;
- (void)updatePlayground:(ANPlayground *)playground completionHandler:(SimpleSuccessBlock)completionHandler;
- (void)removePlayground:(ANPlayground *)playground completionHandler:(SimpleSuccessBlock)completionHandler;

#pragma mark Right now handling
- (void)heartRateDataWithRefreshHandler:(RefreshBlock)refreshHandler;
- (void)temperatureDataWithRefreshHandler:(RefreshBlock)refreshHandler;
- (void)oxygenDataWithRefreshHandler:(RefreshBlock)refreshHandler;
- (void)stepsDataWithRefreshHandler:(RefreshBlock)refreshHandler;
- (void)energyDataWithRefreshHandler:(RefreshBlock)refreshHandler;
- (void)stopRefreshingData;

#pragma mark Landscape graph handling

- (void)waveformDataWithOpticalHandler:(SimpleResultBlock)opticalHandler accelerometerHandler:(SimpleResultBlock)accelerometerHandler;
- (void)stopRefreshingWaveform;

#pragma mark Random data handling
- (void)dailyDataWithCompletionHandler:(void(^)(ANHistoryItem *result))completionHandler;
- (void)historyDataWithCompletionHandler:(void(^)(NSArray *result))completionHandler;

#pragma mark Update handling
- (void)firmwareUpdateWithHandler:(FirmwareUpdateResponseBlock)refreshHandler;
- (void)checkUpdateExistsWithCompletionHandler:(CheckUpdateBlock)completionHandler;
- (void)downloadUpdateWithProgressHandler:(ProgressBlock)progressHandler completionHandler:(SimpleSuccessBlock)completionHandler;
- (void)transferAndVerifyUpdateDataWithProgressHandler:(ProgressBlock)progressHandler completionHandler:(SimpleSuccessBlock)completionHandler recover:(BOOL)recover;
- (void)updateBraceletWithCompletionHandler:(SimpleSuccessBlock)completionHandler recover:(BOOL)recover;
- (void)cancelUpdateFirmware;
- (void)pauseUpdateFirmware;
- (void)continueUpdateFirmware;
- (void)addLogHandler:(UpdateLog)logBlock;
- (void)addUpdateCompliteHandler:(UpdateComplite)updateComplite;

@end
