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


#import "ANDataManager.h"
#import "ANAccount.h"
#import "ANHistoryItem.h"
#import "ANGraphView.h"
#import "ANAlarm.h"
#import "ANPlayground.h"
#import "NSDate+Utilities.h"

#import "ANDemoConnectionManager.h"
#import "ANFirmwareUpdateManager.h"
#import "ANAlarmManager.h"

#import "ANHeartRateService.h"
#import "ANHRMeasurmentCharacteristic.h"

#import "ANBloodOxygenService.h"
#import "ANBloodOxygenSaturationCharacteristic.h"

#import "ANActivityService.h"
#import "ANStepCountCharacteristic.h"
#import "ANAccelerationEnergyMagnitudeCharacteristic.h"

#import "ANHealthThermometerService.h"
#import "ANHTTemperatureMeasurmentCharacteristic.h"

#import "ANFirmwareUpdateService.h"
#import "ANFirmwareUpdateConrolPointCharacteristic.h"
#import "ANFirmwareUpdateFeatureCharacteristic.h"

#import "ANDeviceInfoService.h"
#import "ANFirmwareRevisionCharacteristic.h"
#import "ANAlarmClockService.h"

#import "ANBloodOxygenService.h"

#import "ANBatteryService.h"
#import "ANBatteryLevelCharacteristic.h"

#import "ANWaveformSignalService.h"
#import "ANWaveformSignalFeatureCharacteristic.h"
#import "ANOpticalWaveformCharacteristic.h"
#import "ANAccelerationMagnitudeWaveformCharacteristic.h"

#import "ANHexWrapper.h"
#import "ANHistoryManager.h"
#import "ANHistoryRecord.h"

#import "NSObject+MTKObserving.h"
#import "ANFirmwareUpdateManager.h"

#define MAX_WAVEFORM_COUNT 200
#define UPDATE_COMPLETION_TIMEOUT 15

#define RECONNECT_TIMEOUT 5

@interface ANDataManager () <ANConnectionDelegate, ANPeripheralDelegate, ANServiceDelegate>

@property (copy) RefreshBlock heartRefreshBlock;
@property (copy) RefreshBlock temperatureRefreshBlock;
@property (copy) RefreshBlock oxygenRefreshBlock;
@property (copy) RefreshBlock stepsRefreshBlock;
@property (copy) RefreshBlock energyRefreshBlock;

@property (copy) SimpleResultBlock searchPeripheralBlock;
@property (copy) ConnectPeripheralBlock connectPeripheralBlock;
@property (copy) FirmwareUpdateResponseBlock firmwareUpdateResponseBlock;
@property (copy) AlarmClockResponseBlock alarmClockResponseBlock;

@property (copy) SimpleResultBlock opticalResultBlock;
@property (copy) SimpleResultBlock accelerometerResultBlock;

@property (copy) SimpleSuccessBlock updateCompletionBlock;

@property (nonatomic, strong) NSTimer *updateCompletionTimer;

@property (nonatomic, strong) NSMutableArray *foundPeripherals;
@property (nonatomic, strong) NSArray *connectedPeripherals;

@property (nonatomic, strong) NSMutableArray *alarmsList;
@property (nonatomic, strong) NSMutableArray *playgroundList;

@property (nonatomic, strong) NSMutableArray *opticalData;
@property (nonatomic, strong) NSMutableArray *accelerometerData;

@property (nonatomic, strong) ANFirmwareUpdateManager *fwManager;
@property (nonatomic, strong) ANAlarmManager *alManager;
@property (nonatomic, strong) ANActivityService *activityService;
@property (weak) NSTimer *accelerationReadTimer;

@property (nonatomic, strong) NSTimer *connectionTimer;

@property BOOL deviceChanged;

@end

@implementation ANDataManager

#pragma mark Initialization

- (id)init {
    self = [super init];
    if (self) {
        
        self.deviceChanged = NO;
        self.updating = NO;
        
        self.batteryStatus = 0;
        self.signalStrength = -100;
        
        [ANDemoConnectionManager sharedInstance].delegate = self;
        
        /*dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.firmwareVersion = @"DANIEL015";
            [[NSNotificationCenter defaultCenter] postNotificationName:kCheckUpdateNotification object:nil];
        });*/
        
        self.foundPeripherals = [NSMutableArray new];
    }
    return self;
}

+ (id)sharedManager {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark Custom methods

- (NSDateFormatter *)mdFormatter {
    if (!_mdFormatter) {
        _mdFormatter = [[NSDateFormatter alloc] init];
        [_mdFormatter setDateFormat:@"MMM d"];
    }
    return _mdFormatter;
}

- (NSDateFormatter *)hmaFormatter {
    if (!_hmaFormatter) {
        _hmaFormatter = [[NSDateFormatter alloc] init];
        [_hmaFormatter setAMSymbol:@"AM"];
        [_hmaFormatter setPMSymbol:@"PM"];
        [_hmaFormatter setDateFormat:@"hh:mma"];
    }
    return _hmaFormatter;
}

- (NSDateFormatter *)birthdayFormatter {
    if (!_birthdayFormatter) {
        _birthdayFormatter = [[NSDateFormatter alloc] init];
        [_birthdayFormatter setDateFormat:@"dd MMMM, YYYY"];
    }
    return _birthdayFormatter;
}

- (NSDateFormatter *)alarmFormatter {
    if (!_alarmFormatter) {
        _alarmFormatter = [[NSDateFormatter alloc] init];
        [_alarmFormatter setAMSymbol:@"AM"];
        [_alarmFormatter setPMSymbol:@"PM"];
        [_alarmFormatter setDateFormat:@"MMM d, hh:mma"];
    }
    return _alarmFormatter;
}

- (NSNumberFormatter *)numberFormatter {
    if (!_numberFormatter) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        [_numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [_numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    }
    return _numberFormatter;
}

#pragma mark Right now handling

- (void)heartRateDataWithRefreshHandler:(RefreshBlock)refreshHandler {
    self.heartRefreshBlock = refreshHandler;
    if (!sensorMode) {
        [self heartValueChanged];
    }
}

- (void)temperatureDataWithRefreshHandler:(void(^)(NSNumber *result))refreshHandler {
    self.temperatureRefreshBlock = refreshHandler;
    if (!sensorMode) {
        [self temperatureValueChanged];
    }
}

- (void)oxygenDataWithRefreshHandler:(void(^)(NSNumber *result))refreshHandler {
    self.oxygenRefreshBlock = refreshHandler;
    if (!sensorMode) {
        [self oxygenValueChanged];
    }
}

- (void)stepsDataWithRefreshHandler:(void(^)(NSNumber *result))refreshHandler {
    self.stepsRefreshBlock = refreshHandler;
    if (!sensorMode) {
        [self stepsValueChanged];
    }
}

- (void)energyDataWithRefreshHandler:(void(^)(NSNumber *result))refreshHandler {
    self.energyRefreshBlock = refreshHandler;
    if (!sensorMode) {
        [self energyValueChanged];
    }
}

#pragma mark Dummy data handling

- (void)addHistoryRecord:(NSNumber *)value timestamp:(NSDate *)timestamp type:(ANHistoryRecordType)type unique:(BOOL)unique {
    ANHistoryRecord *ah = [[ANHistoryRecord alloc] init];
    ah.recordValue = value;
    ah.recordType = type;
    ah.recordTimestamp = timestamp ? timestamp : [NSDate date];
    if (unique) {
        [[ANHistoryManager sharedManager] addUniquePerDayRecord:ah completionHandler:nil];
    } else {
        [[ANHistoryManager sharedManager] addRecord:ah completionHandler:nil];
    }
}

- (void)heartValueChanged {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(heartValueChanged) object:nil];
    if (self.heartRefreshBlock) {
        NSNumber *value = @([self randomIntegerBetween:40 and:200]);
        [self addHistoryRecord:value timestamp:[NSDate date] type:ANHistoryRecordTypeHeartRate unique:NO];
        self.heartRefreshBlock(value);
        [self performSelector:@selector(heartValueChanged) withObject:nil afterDelay:1.0f];
    }
}

- (void)temperatureValueChanged {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(temperatureValueChanged) object:nil];
    if (self.temperatureRefreshBlock) {
        NSNumber *value = @([self randomFloatBetween:30.0f and:44.0f]);
        [self addHistoryRecord:value timestamp:[NSDate date] type:ANHistoryRecordTypeTemperature unique:NO];
        self.temperatureRefreshBlock(value);
        [self performSelector:@selector(temperatureValueChanged) withObject:nil afterDelay:[self randomFloatBetween:1.0f and:2.0f]];
    }
}

- (void)oxygenValueChanged {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(oxygenValueChanged) object:nil];
    if (self.oxygenRefreshBlock) {
        NSNumber *value = @([self randomFloatBetween:0.0f and:100.0f]);
        [self addHistoryRecord:value timestamp:[NSDate date] type:ANHistoryRecordTypeOxygen unique:NO];
        self.oxygenRefreshBlock(value);
        [self performSelector:@selector(oxygenValueChanged) withObject:nil afterDelay:[self randomFloatBetween:1.0f and:2.0f]];
    }
}

- (void)stepsValueChanged {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stepsValueChanged) object:nil];
    if (self.stepsRefreshBlock) {
        NSNumber *value = @([self randomIntegerBetween:0.0f and:10000]);
        [self addHistoryRecord:value timestamp:[NSDate date] type:ANHistoryRecordTypeSteps unique:YES];
        self.stepsRefreshBlock(value);
        [self performSelector:@selector(stepsValueChanged) withObject:nil afterDelay:[self randomFloatBetween:1.0f and:2.0f]];
    }
}

- (void)energyValueChanged {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(energyValueChanged) object:nil];
    if (self.energyRefreshBlock) {
        self.energyRefreshBlock(@([self randomIntegerBetween:100 and:4000]));
        [self performSelector:@selector(energyValueChanged) withObject:nil afterDelay:[self randomFloatBetween:1.0f and:2.0f]];
    }
}

- (void)stopRefreshingData {
    self.heartRefreshBlock = nil;
    self.temperatureRefreshBlock = nil;
    self.oxygenRefreshBlock = nil;
    self.stepsRefreshBlock = nil;
    self.energyRefreshBlock = nil;
}

#pragma mark Screen lock handling

- (void)setUpdating:(BOOL)updating {
    _updating = updating;
//    [[UIApplication sharedApplication] setIdleTimerDisabled:updating];
}

#pragma mark Landscape graph handling

- (NSMutableArray *)opticalData {
    if (!_opticalData) {
        _opticalData = [NSMutableArray new];
//#warning Remove on prod
//        for (NSInteger i = ANHistoryRecordTypeOpticalWaveform1; i <= ANHistoryRecordTypeOpticalWaveform2; i++) {
//            NSMutableArray *items = [NSMutableArray new];
//            for (NSInteger k = 0; k < 100; k++) {
//                ANHistoryRecord *ah = [ANHistoryRecord new];
//                ah.recordType = (ANHistoryRecordType)i;
//                ah.recordValue = @([self randomIntegerBetween:1 and:100]);
//                [items addObject:ah];
//            }
//            [_opticalData addObject:items];
//        }
    }
    return _opticalData;
}

- (NSMutableArray *)accelerometerData {
    if (!_accelerometerData) {
        _accelerometerData = [NSMutableArray new];
//#warning Remove on prod
//        for (NSInteger k = 0; k < 100; k++) {
//            ANHistoryRecord *ah = [ANHistoryRecord new];
//            ah.recordType = ANHistoryRecordTypeAccelerometer;
//            ah.recordValue = @([self randomIntegerBetween:1 and:100]);
//            [items addObject:ah];
//        }
    }
    return _accelerometerData;
}


- (void)waveformDataWithOpticalHandler:(SimpleResultBlock)opticalHandler accelerometerHandler:(SimpleResultBlock)accelerometerHandler {
    if (opticalHandler) {
        opticalHandler(self.opticalData, nil);
    }
    if (accelerometerHandler) {
        accelerometerHandler(self.accelerometerData, nil);
    }
    self.opticalResultBlock = opticalHandler;
    self.accelerometerResultBlock = accelerometerHandler;
}

- (void)stopRefreshingWaveform {
    self.opticalResultBlock = nil;
    self.accelerometerResultBlock = nil;
}

#pragma mark Peripheral handling

- (void)startScanningForPeripherals {
    
    if ([ANDemoConnectionManager sharedInstance].state == CBCentralManagerStatePoweredOn) {
        if (![ANDemoConnectionManager sharedInstance].isScanning) {
            [[ANDemoConnectionManager sharedInstance] setDelegate:self];
            NSArray *serviceUUIDs = @[[ANHeartRateService UUID], [ANDeviceInfoService UUID], [ANAlarmClockService UUID], [ANHealthThermometerService UUID], /*[ANBloodOxygenService UUID]*/];
            [[ANDemoConnectionManager sharedInstance] startScanningForPeripheralsWithServiceUUIDs:serviceUUIDs];
        }
    }
}

- (void)stopScanningForPeripherals {
    [[ANDemoConnectionManager sharedInstance] stopScanning];
    self.searchPeripheralBlock = nil;
}

#pragma mark Service enable mode handling

- (void)setServiceEnableMode:(ServiceEnableMode)serviceEnableMode {
    if (_serviceEnableMode != serviceEnableMode) {
        _serviceEnableMode = serviceEnableMode;
        switch (serviceEnableMode) {
            case ServiceEnableModeNone: {
                [self.currentWristband enableServices:NO except:nil];
            } break;
            case ServiceEnableModePortrait: {
                [self.currentWristband enableServices:YES except:@[NSStringFromClass([ANWaveformSignalService class]), NSStringFromClass([ANFirmwareUpdateService class])]];
            } break;
            case ServiceEnableModeLandscape: {
                [self.currentWristband enableServices:YES except:@[NSStringFromClass([ANFirmwareUpdateService class])]];
            } break;
            case ServiceEnableModeFWUpdate: {
                [self.currentWristband enableServices:NO except:@[NSStringFromClass([ANFirmwareUpdateService class])]];
            } break;
            default:
                break;
        }
    }
}

#pragma mark Connection handling

- (void)connectionManager:(ANConnectionManager *)manager didDiscoverPeripheral:(ANPeripheral *)peripheral {

    NSInteger index = [self.foundPeripherals indexOfObjectPassingTest:^BOOL(ANPeripheral *foundPeripheral, NSUInteger idx, BOOL *stop) {
        if ([foundPeripheral.peripheral.identifier isEqual:peripheral.peripheral.identifier]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    
    if (index == NSNotFound) {
        [self.foundPeripherals addObject:peripheral];
    } else {
        [self.foundPeripherals replaceObjectAtIndex:index  withObject:peripheral];
    }
    
    if (self.searchPeripheralBlock) {
        self.searchPeripheralBlock(self.foundPeripherals, nil);
    }
}

- (void)connectionManager:(ANConnectionManager *)manager didConnectPeripheral:(ANPeripheral *)peripheral {
    
    self.currentWristband = peripheral;
    
    peripheral.delegate = self;
    peripheral.connected = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![[defaults objectForKey:kStoredPeripheral] isEqualToString:peripheral.peripheral.identifier.UUIDString]) {
        [defaults setObject:peripheral.peripheral.identifier.UUIDString forKey:kStoredPeripheral];
        [defaults synchronize];
        self.deviceChanged = YES;
    }
    
    self.signalStrength = -50;
    
    if (self.connectPeripheralBlock) {
        self.connectPeripheralBlock(YES, nil);
        self.connectPeripheralBlock = nil;
    }
    [self stopScanningForPeripherals];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPeripheralStatusChangedNotification object:nil];
}

- (void)connectionManager:(ANConnectionManager *)manager didFailConnectingPeripheral:(ANPeripheral *)peripheral error:(NSError *)error {
    peripheral.connected = NO;
    if (self.connectPeripheralBlock) {
        self.connectPeripheralBlock(NO, error);
        self.connectPeripheralBlock = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kPeripheralStatusChangedNotification object:nil];
}

- (void)connectionManager:(ANConnectionManager *)manager disconnectedFromPeripheral:(ANPeripheral *)peripheral error:(NSError *)error {
    peripheral.connected = NO;
    self.signalStrength = -100;
    self.connectPeripheralBlock = nil;
    self.fwManager.service = nil;
    if (error) {
        [manager connectToStoredPeripheralWithUUID:[CBUUID UUIDWithString:self.currentWristband.identifier]];
    }
    if (self.fwManager.updateInProgress) {
        if (!self.fwManager.stage != ANUpdateStageStartFWUpdate) {
            [self setupConnectionTimer];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kPeripheralStatusChangedNotification object:nil];
}

- (void)connectionManager:(ANConnectionManager *)manager didChangeState:(CBCentralManagerState)state {
    if (state == CBCentralManagerStatePoweredOn) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kBlueToothStatePoweredOn object:nil userInfo:@{}];
        if (self.connectionRequestedButManagerStateIsNotOn) {
            NSString *storedPeripheralUUIDString = [[NSUserDefaults standardUserDefaults] objectForKey:kStoredPeripheral];
            if (storedPeripheralUUIDString) {
                CBUUID *storedPeripheral = [CBUUID UUIDWithString:storedPeripheralUUIDString];
                if (![manager connectToStoredPeripheralWithUUID:storedPeripheral]) {
                    [self startScanningForPeripherals];
                }
            }
            else {
                [self startScanningForPeripherals];
            }
        }
    }
    else if (state == CBCentralManagerStatePoweredOff)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kBlueToothStatePoweredOff object:nil userInfo:@{}];
    }
}

#pragma mark - Peripheral handling

- (void)peripheral:(ANPeripheral *)peripheral didDiscoverService:(ANService *)service {
    [service setDelegate:self];
    
    if ([service isMemberOfClass:[ANActivityService class]]) {
        if (_accelerationReadTimer) {
            [self.accelerationReadTimer invalidate];
        }
        
        self.activityService = (ANActivityService*)service;
        self.accelerationReadTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                      target:self
                                                                    selector:@selector(readAccelerationEnergy:)
                                                                    userInfo:nil
                                                                     repeats:YES];
    }
}

- (void)peripheral:(ANPeripheral *)peripheral discoveredCharacteristicsForService:(ANService *)service {
    if ([service isMemberOfClass:[ANAlarmClockService class]]) {
        
        self.alManager = [[ANAlarmManager alloc] initWithService:(ANAlarmClockService *)service];
        if (self.deviceChanged) {
            self.deviceChanged = NO;
            [self.alManager removeAllAlarms];
        }
    }
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (!UIDeviceOrientationIsLandscape(deviceOrientation)) {
        [self.currentWristband enableServices:YES except:nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPeripheralConnected object:nil userInfo:nil];
    
}

- (void)peripheral:(ANPeripheral *)peripheral didUpdateRSSI:(NSNumber *)RSSI {
    self.signalStrength = [RSSI intValue];
}

- (void)service:(ANService *)service didUpdateValueForCharacterstic:(ANCharacteristic *)characteristic error:(NSError *)error {
    
    void (^addHistoryRecord)(NSNumber *value, NSDate *timestamp, ANHistoryRecordType type, BOOL unique) = ^(NSNumber *value, NSDate *timestamp, ANHistoryRecordType type, BOOL unique){
        ANHistoryRecord *ah = [[ANHistoryRecord alloc] init];
        ah.recordValue = value;
        ah.recordType = type;
        ah.recordTimestamp = timestamp ? timestamp : [NSDate date];
        if (unique) {
            [[ANHistoryManager sharedManager] addUniquePerDayRecord:ah completionHandler:nil];
        } else {
            [[ANHistoryManager sharedManager] addRecord:ah completionHandler:nil];
        }
    };
    /* DEVICE INFO */
    if ([service isMemberOfClass:[ANDeviceInfoService class]]) {
        if ([characteristic isMemberOfClass:[ANFirmwareRevisionCharacteristic class]]) {
            self.firmwareVersion = ((ANFirmwareRevisionCharacteristic *)characteristic).firmwareVersion;
            [[NSNotificationCenter defaultCenter] postNotificationName:kCheckUpdateNotification object:nil];
        }
    }
    /* HEART RATE */
    else if ([service isMemberOfClass:[ANHeartRateService class]]) {
        if ([characteristic isMemberOfClass:[ANHRMeasurmentCharacteristic class]]) {
            float heartRate = ((ANHRMeasurmentCharacteristic *)characteristic).heartRate;
            addHistoryRecord(@(heartRate), nil, ANHistoryRecordTypeHeartRate, NO);
            if (self.heartRefreshBlock) {
                self.heartRefreshBlock(@(heartRate));
            }
        }
    }
    /* TEMPERATURE */
    else if ([service isMemberOfClass:[ANHealthThermometerService class]]) {
        if ([characteristic isMemberOfClass:[ANHTTemperatureMeasurmentCharacteristic class]]) {
            Float32 tempRate = ((ANHTTemperatureMeasurmentCharacteristic *)characteristic).value.temperature;
            NSDate *timestamp = ((ANHTTemperatureMeasurmentCharacteristic *)characteristic).value.timeStamp;
            addHistoryRecord(@(tempRate), timestamp, ANHistoryRecordTypeTemperature, NO);
            if (self.temperatureRefreshBlock) {
                self.temperatureRefreshBlock(@(tempRate));
            }
        }
    }
    /* ACTIVITY */
    else if ([service isMemberOfClass:[ANActivityService class]]) {
        if ([characteristic isMemberOfClass:[ANStepCountCharacteristic class]]) {
            int steps = ((ANStepCountCharacteristic *)characteristic).steps;
            addHistoryRecord(@(steps), nil, ANHistoryRecordTypeSteps, YES);
            if (self.stepsRefreshBlock) {
                self.stepsRefreshBlock(@(steps));
            }
        }
        else if ([characteristic isMemberOfClass:[ANAccelerationEnergyMagnitudeCharacteristic class]]) {
            int value = ((ANAccelerationEnergyMagnitudeCharacteristic *)characteristic).magnitude;
            if (self.energyRefreshBlock) {
                self.energyRefreshBlock(@(value));
            }
        }
    }
    /* BLOOD OXYGEN LEVEL */
    else if ([service isMemberOfClass:[ANBloodOxygenService class]]) {
        if ([characteristic isMemberOfClass:[ANBloodOxygenSaturationCharacteristic class]]) {
            Float32 oxygenLevel = ((ANBloodOxygenSaturationCharacteristic *)characteristic).value.oxygenLevel;
            NSDate *timestamp = ((ANBloodOxygenSaturationCharacteristic *)characteristic).value.timeStamp;
            addHistoryRecord(@(oxygenLevel), timestamp, ANHistoryRecordTypeOxygen, NO);
            if (self.oxygenRefreshBlock) {
                self.oxygenRefreshBlock(@(oxygenLevel));
            }
        }
    }
    /* ALARM */
    else if ([service isMemberOfClass:[ANAlarmClockService class]]) {
        if ([characteristic isMemberOfClass:[ANAlarmClockControlPointCharacteristic class]]) {
            if (self.alarmClockResponseBlock) {
                ANAlarmClockResponseCode response = ((ANAlarmClockControlPointCharacteristic *)characteristic).responseCode;
                UInt16 value = ((ANAlarmClockControlPointCharacteristic *)characteristic).responseValue;
                self.alarmClockResponseBlock(response, value);
            }
        }
    }
    /* FIRMWARE UPDATE */
    else if ([service isMemberOfClass:[ANFirmwareUpdateService class]]) {
        if ([characteristic isMemberOfClass:[ANFirmwareUpdateConrolPointCharacteristic class]]) {
            if (self.firmwareUpdateResponseBlock) {
                ANFWResponseCode response = ((ANFirmwareUpdateConrolPointCharacteristic *)characteristic).responseCode;
                self.firmwareUpdateResponseBlock(response, 0);
            }
        }
        /* only now, when we get the feature values, we can use the service */
        if ([characteristic isMemberOfClass:[ANFirmwareUpdateFeatureCharacteristic class]]) {
            if (!self.fwManager) {
                self.fwManager = [[ANFirmwareUpdateManager alloc] initWithService:(ANFirmwareUpdateService *)service];
            } else {
                [self.fwManager setService:(ANFirmwareUpdateService *)service];
                
                [self invalidateUpdateCompletionTimer];
                if (self.updateCompletionBlock) {
                    self.updateInfo = nil;
                    self.updateCompletionBlock(YES, nil);
                    self.updateCompletionBlock = nil;
                }
            }
        }
    }
    /* BATTERY */
    else if ([service isMemberOfClass:[ANBatteryService class]]) {
        if ([characteristic isMemberOfClass:[ANBatteryLevelCharacteristic class]]) {
            self.batteryStatus = ((ANBatteryLevelCharacteristic *)characteristic).level;
        }
    }
    /* WAVEFORM */
    else if ([service isMemberOfClass:[ANWaveformSignalService class]]) {
        if ([characteristic isMemberOfClass:[ANOpticalWaveformCharacteristic class]]) {
            NSArray *waveLengths = ((ANOpticalWaveformCharacteristic *)characteristic).values;
            for (NSArray *waveLengthItems in waveLengths) {
                NSInteger index = [waveLengths indexOfObject:waveLengthItems];
                if (self.opticalData.count <= index) {
                    [self.opticalData addObject:[NSMutableArray new]];
                }
                NSMutableArray *items = [NSMutableArray new];
                for (NSNumber *value in waveLengthItems) {
                    ANHistoryRecord *ah = [ANHistoryRecord new];
                    ah.recordType = (ANHistoryRecordType)(ANHistoryRecordTypeOpticalWaveform1 + index);
                    ah.recordValue = value;
                    [items addObject:ah];
                }
                NSMutableArray *waveformItems = [self.opticalData objectAtIndex:index];
                if (waveformItems.count + items.count > MAX_WAVEFORM_COUNT) {
                    [waveformItems removeObjectsInRange:NSMakeRange(0, items.count)];
                }
                [waveformItems addObjectsFromArray:items];
            }
            
            if (self.opticalResultBlock) {
                self.opticalResultBlock(self.opticalData, nil);
            }
        }
        else if ([characteristic isMemberOfClass:[ANAccelerationMagnitudeWaveformCharacteristic class]]) {
            NSArray *waveLengthItems = ((ANAccelerationMagnitudeWaveformCharacteristic *)characteristic).values;
            
            NSMutableArray *items = [NSMutableArray new];
            for (NSNumber *value in waveLengthItems) {
                ANHistoryRecord *ah = [ANHistoryRecord new];
                ah.recordType = ANHistoryRecordTypeAccelerometer;
                ah.recordValue = value;
                [items addObject:ah];
            }
            
            if (self.accelerometerData.count + items.count > MAX_WAVEFORM_COUNT) {
                [self.accelerometerData removeObjectsInRange:NSMakeRange(0, items.count)];
            }
            [self.accelerometerData addObjectsFromArray:items];
            
            if (self.accelerometerResultBlock) {
                self.accelerometerResultBlock(self.accelerometerData, nil);
            }
        }
    }
}

- (void)forgetDevice {
    [[ANDemoConnectionManager sharedInstance] disconnectPeripheral:[ANDemoConnectionManager sharedInstance].currentPeripheral];
    self.currentWristband = nil;
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kStoredPeripheral];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)readAccelerationEnergy:(NSTimer*)theTimer {
    if (_currentWristband && _activityService) {
        [self.activityService requestAccelerationEnergyMagnitude];
    }
}

#pragma mark Battery and signal handling

- (void)someDelegateMethodThatWillBeCalledOnBatteryChange:(NSNumber *)result {
    self.batteryStatus = result.intValue;
}

#pragma mark Wristbands handling

- (void)searchPeripheralWithCompletionHandler:(SimpleResultBlock)completionHandler {
    [self.foundPeripherals removeAllObjects];
    self.searchPeripheralBlock = completionHandler;
    if (sensorMode) {
        /* if connection manager is ready, try to connect. if not, raise a flag to connect when ready */
        if ([ANDemoConnectionManager sharedInstance].state == CBCentralManagerStatePoweredOn) {
            self.connectionRequestedButManagerStateIsNotOn = NO;
            [self startScanningForPeripherals];
        }
        else {
            self.connectionRequestedButManagerStateIsNotOn = YES;
        }
        
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (completionHandler) {
                ANPeripheral *p1 = [[ANPeripheral alloc] init];
                ANPeripheral *p2 = [[ANPeripheral alloc] init];
                ANPeripheral *p3 = [[ANPeripheral alloc] init];
                ANPeripheral *p4 = [[ANPeripheral alloc] init];
                ANPeripheral *p5 = [[ANPeripheral alloc] init];
                ANPeripheral *p6 = [[ANPeripheral alloc] init];
                
                [self.foundPeripherals addObjectsFromArray:@[p1, p2, p3, p4, p5, p6]];
                completionHandler(self.foundPeripherals, nil);
            }
        });
    }
}

- (void)connectedPeripheralsWithCompletionHandler:(void(^)(NSArray *result, NSError *error))completionHandler {
    if (sensorMode) {
        if (completionHandler) {
            completionHandler(nil, nil);
        }
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (completionHandler) {
                ANPeripheral *p1 = [[ANPeripheral alloc] init];
                ANPeripheral *p2 = [[ANPeripheral alloc] init];
                ANPeripheral *p3 = [[ANPeripheral alloc] init];
                ANPeripheral *p4 = [[ANPeripheral alloc] init];
                ANPeripheral *p5 = [[ANPeripheral alloc] init];
                ANPeripheral *p6 = [[ANPeripheral alloc] init];
                
                self.connectedPeripherals = @[p1, p2, p3, p4, p5, p6];
                completionHandler(self.connectedPeripherals, nil);
            }
        });
    }
}

- (void)connectPeripheral:(ANPeripheral *)peripheral completionHandler:(ConnectPeripheralBlock)completionHandler {
    if (sensorMode) {
        self.connectPeripheralBlock = completionHandler;
        [[ANDemoConnectionManager sharedInstance] connectPeripheral:peripheral];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (completionHandler) {
                self.currentWristband = peripheral;
                [[NSUserDefaults standardUserDefaults] setObject:peripheral.identifier forKey:kStoredPeripheral];
                [[NSUserDefaults standardUserDefaults] synchronize];
                completionHandler(YES, nil);
            }
        });
    }
}

- (void)connectStoredPeripheralWithCompletionHandler:(ConnectPeripheralBlock)completionHandler {
    if (sensorMode) {
        self.connectPeripheralBlock = completionHandler;
        /* if connection manager is ready, try to connect. if not, raise a flag to connect when ready */
        if ([ANDemoConnectionManager sharedInstance].state == CBCentralManagerStatePoweredOn) {
            self.connectionRequestedButManagerStateIsNotOn = NO;
            [[ANDemoConnectionManager sharedInstance] connectToStoredPeripheralWithUUID:[CBUUID UUIDWithString:[[NSUserDefaults standardUserDefaults] objectForKey:kStoredPeripheral]]];
        }
        else {
            self.connectionRequestedButManagerStateIsNotOn = YES;
        }
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (completionHandler) {
                self.currentWristband = [[ANPeripheral alloc] init];
                completionHandler(YES, nil);
            }
        });
    }
}

- (BOOL)connectedPeripheralsExists {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kStoredPeripheral] ? YES : NO;
}

#pragma mark Alarms handling

- (void)alarmsListWithCompletionHandler:(void(^)(NSArray *result, NSError *error))completionHandler {
    if (!sensorMode) {
        if (!self.alManager) {
            self.alManager = [[ANAlarmManager alloc] initWithService:nil];
        }
    }
    [self.alManager alarmsListWithCompletionHandler:completionHandler];
}

- (void)alarmClockWithHandler:(AlarmClockResponseBlock)refreshHandler {
    self.alarmClockResponseBlock = refreshHandler;
}

- (void)addAlarm:(ANAlarm *)alarm completionHandler:(SimpleSuccessBlock)completionHandler {
    [self.alManager addAlarm:alarm completionHandler:completionHandler];
}

- (void)updateAlarm:(ANAlarm *)alarm completionHandler:(SimpleSuccessBlock)completionHandler {
    [self.alManager updateAlarm:alarm completionHandler:completionHandler];
}

- (void)removeAlarm:(ANAlarm *)alarm completionHandler:(SimpleSuccessBlock)completionHandler {
    [self.alManager removeAlarm:alarm completionHandler:completionHandler];
}

#pragma mark Playground handling

- (void)playgroundListWithCompletionHandler:(void(^)(NSArray *result, NSError *error))completionHandler {
    if (!self.playgroundList) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (completionHandler) {
                
                ANPlayground *p1 = [[ANPlayground alloc] init];
                p1.playgroundID = @(1);
                p1.playgroundType = PlaygroundTypeHeart;
                p1.playgroundCompareValue = @(120);
                p1.playgroundLedMode = LedMode20;
                p1.playgroundVibrateMode = VibrateModeTwice;
                p1.playgroundSoundID = @(1);
                p1.playgroundCompareType = PlaygroundCompareTypeAbove;
                
                ANPlayground *p2 = [[ANPlayground alloc] init];
                p2.playgroundID = @(2);
                p2.playgroundType = PlaygroundTypeHeart;
                p2.playgroundCompareValue = @(40);
                p2.playgroundLedMode = LedMode10;
                p2.playgroundVibrateMode = VibrateModeMultiple;
                p2.playgroundSoundID = @(2);
                p2.playgroundCompareType = PlaygroundCompareTypeBelow;
                
                ANPlayground *p3 = [[ANPlayground alloc] init];
                p3.playgroundID = @(3);
                p3.playgroundType = PlaygroundTypeOxygen;
                p3.playgroundCompareValue = @(90);
                p3.playgroundLedMode = LedMode40;
                p3.playgroundVibrateMode = VibrateModeOnce;
                p3.playgroundSoundID = @(3);
                p3.playgroundCompareType = PlaygroundCompareTypeBelow;
                
                ANPlayground *p4 = [[ANPlayground alloc] init];
                p4.playgroundID = @(4);
                p4.playgroundType = PlaygroundTypeTemperature;
                p4.playgroundCompareValue = @(37.3);
                p4.playgroundLedMode = LedMode30;
                p4.playgroundVibrateMode = VibrateModeMultiple;
                p4.playgroundSoundID = @(4);
                p4.playgroundCompareType = PlaygroundCompareTypeAbove;
                
                ANPlayground *p5 = [[ANPlayground alloc] init];
                p5.playgroundID = @(5);
                p5.playgroundType = PlaygroundTypeSteps;
                p5.playgroundCompareValue = @(1000);
                p5.playgroundLedMode = LedMode50;
                p5.playgroundVibrateMode = VibrateModeOnce;
                p5.playgroundSoundID = @(5);
                p5.playgroundCompareType = PlaygroundCompareTypeBelow;
            
                self.playgroundList = [[NSMutableArray alloc] initWithArray:@[p1, p2, p3, p4, p5]];
                
                completionHandler(self.playgroundList, nil);
            }
        });
    } else {
        if (completionHandler) {
            completionHandler(self.playgroundList, nil);
        }
    }
}

- (void)addPlayground:(ANPlayground *)playground completionHandler:(SimpleSuccessBlock)completionHandler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.playgroundList removeObject:playground];
        if (completionHandler) {
            completionHandler(YES, nil);
        }
    });
}

- (void)updatePlayground:(ANPlayground *)playground completionHandler:(SimpleSuccessBlock)completionHandler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (completionHandler) {
            completionHandler(YES, nil);
        }
    });
}

- (void)removePlayground:(ANPlayground *)playground completionHandler:(SimpleSuccessBlock)completionHandler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.playgroundList removeObject:playground];
        if (completionHandler) {
            completionHandler(YES, nil);
        }
    });
}

#pragma mark Random data handling

- (void)historyDataForStartDate:(NSDate *)startDate endDate:(NSDate *)endDate completionHandler:(void(^)(ANHistoryItem *result))completionHandler {
    [[ANHistoryManager sharedManager] loadDatabaseWithCompletionHandler:^(NSArray *result, NSError *error) {
        if (result && !error) {
            ANHistoryItem *item = [[ANHistoryItem alloc] init];
            for (ANHistoryRecord *record in result) {
                if ([record.recordTimestamp isLaterOrEqualThanDate:startDate] && [record.recordTimestamp isEarlierOrEqualThanDate:endDate]) {
                    [item addRecord:record];
                }
            }
            item.startDate = startDate;
            item.endDate = endDate;
            if (completionHandler) {
                completionHandler(item);
            }
        }
    }];
}

- (void)dailyDataWithCompletionHandler:(void(^)(ANHistoryItem *result))completionHandler {
    [self historyDataForStartDate:[[NSDate date] dateAtStartOfDay] endDate:[[NSDate date] dateAtEndOfDay] completionHandler:completionHandler];
}

- (void)historyDataWithCompletionHandler:(void(^)(NSArray *result))completionHandler {
    [[ANHistoryManager sharedManager] loadDatabaseWithCompletionHandler:^(NSArray *result, NSError *error) {
        if (result && !error) {
            NSMutableDictionary *historyItems = [NSMutableDictionary new];
            for (ANHistoryRecord *record in result) {
                NSDate *startDate = [record.recordTimestamp dateAtStartOfDay];
                NSDate *endDate = [record.recordTimestamp dateAtEndOfDay];
                ANHistoryItem *item = [historyItems objectForKey:startDate];
                if (!item) {
                    item = [ANHistoryItem new];
                    item.startDate = startDate;
                    item.endDate = endDate;
                    [historyItems setObject:item forKey:startDate];
                }
                [item addRecord:record];
            }
            NSArray *allItems = [[historyItems allValues] sortedArrayUsingComparator:^NSComparisonResult(ANHistoryItem *obj1, ANHistoryItem *obj2) {
                return [obj2.startDate compare:obj1.startDate];
            }];
            
            if (completionHandler) {
                completionHandler(allItems);
            }
        }
    }];
}

#pragma mark Random data handling

- (float)randomFloatBetween:(float)smallNumber and:(float)bigNumber {
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

- (NSInteger)randomIntegerBetween:(NSInteger)smallNumber and:(NSInteger)bigNumber {
    return ((arc4random() % (bigNumber - smallNumber + 1)) + smallNumber);
}

#pragma mark Update handling

- (void)firmwareUpdateWithHandler:(FirmwareUpdateResponseBlock)refreshHandler {
    self.firmwareUpdateResponseBlock = refreshHandler;
}

- (void)checkUpdateExistsWithCompletionHandler:(CheckUpdateBlock)completionHandler {
    
    if (self.isUpdateMode)
    {
        return;
    }
    if (!sensorMode) {
        self.fwManager = [[ANFirmwareUpdateManager alloc] initWithService:nil];
    }
    static BOOL checkingUpdate = NO;
    @synchronized(self) {
        if (!checkingUpdate) {
            checkingUpdate = YES;
            if (self.fwManager) {
                [self.fwManager checkUpdateExists:self.firmwareVersion completionHandler:^(BOOL success, NSDictionary *info, NSError *error) {
                    if (completionHandler) {
                        if (success && !error) {
                            self.updateInfo = info;
                        }
                        completionHandler(success, info, error);
                        checkingUpdate = NO;
                    }
                }];
            } else {
                [self removeAllObservations];
                __weak typeof(self) wself = self;
                [self observeProperty:@"fwManager" withBlock:^(__weak id self, id old, id newVal) {
                    if (newVal) {
                        [wself.fwManager checkUpdateExists:wself.firmwareVersion completionHandler:^(BOOL success, NSDictionary *info, NSError *error) {
                            if (completionHandler) {
                                if (success && !error) {
                                    wself.updateInfo = info;
                                }
                                completionHandler(success, info, error);
                                checkingUpdate = NO;
                            }
                        }];
                    }
                }];
            }
        } else {
            if (completionHandler) {
                completionHandler(NO, nil, nil);
            }
        }
    }
    
}

- (void)downloadUpdateWithProgressHandler:(ProgressBlock)progressHandler completionHandler:(SimpleSuccessBlock)completionHandler {
    [self.fwManager downloadUpdateWithProgressHandler:progressHandler completionHandler:completionHandler];
}

- (void)transferAndVerifyUpdateDataWithProgressHandler:(ProgressBlock)progressHandler completionHandler:(SimpleSuccessBlock)completionHandler recover:(BOOL)recover {
    [self.fwManager transferAndVerifyUpdateDataWithProgressHandler:progressHandler completionHandler:completionHandler recover:recover];
}

- (void)updateBraceletWithCompletionHandler:(SimpleSuccessBlock)completionHandler recover:(BOOL)recover {
    self.updateCompletionBlock = completionHandler;
    [self setupUpdateCompletionTimer];
    [self.fwManager updateBracelet];
}

- (void)cancelUpdateFirmware
{
    [self.fwManager cancelUpdate];
}

- (void)pauseUpdateFirmware
{
    [self.fwManager pauseUpdate];
}

- (void)continueUpdateFirmware
{
    [self.fwManager continueUpdate];
}


#pragma mark Connection recovery timer

- (void)setupConnectionTimer {
    [self removeAllObservations];
    [self invalidateConnectionTimer];
    self.connectionTimer = [NSTimer scheduledTimerWithTimeInterval:RECONNECT_TIMEOUT target:self selector:@selector(reconnectTimoutFired) userInfo:nil repeats:NO];
    __weak typeof(self) wself = self;

    void (^handleConnected)(void) = ^{
        [self invalidateConnectionTimer];
        if (!self.fwManager.service) {
            [self observeProperty:@"fwManager.service" withBlock:^(__weak id self, id old, id newVal) {
                if (newVal) {
                    [wself removeAllObservations];
                    [wself.fwManager continueFromCurrentState];
                }
            }];
        } else {
            [self.fwManager continueFromCurrentState];
        }
    };
    
    if (!self.currentWristband.connected) {
        [self observeProperty:@"currentWristband.connected" withBlock:^(__weak id self, NSNumber *old, NSNumber *newVal) {
            if (newVal.boolValue) {
                [wself removeAllObservations];
                handleConnected();
            }
        }];
    } else {
        handleConnected();
    }
}

- (void)reconnectTimoutFired {
    [self removeAllObservations];
    [self.fwManager deviceDisconnected];
}

- (void)invalidateConnectionTimer {
    if (self.connectionTimer) {
        if ([self.connectionTimer isValid]) {
            [self.connectionTimer invalidate];
        }
        self.connectionTimer = nil;
    }
}

- (void)addLogHandler:(UpdateLog)logBlock
{
    self.fwManager.updateLog = logBlock;
}

- (void)addUpdateCompliteHandler:(UpdateComplite)updateComplite
{
    self.fwManager.updateCompliteHandler = updateComplite;
}


#pragma mark Update timer

- (void)setupUpdateCompletionTimer {
    //[self invalidateUpdateCompletionTimer];
 //   self.updateCompletionTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_COMPLETION_TIMEOUT target:self selector:@selector(updateCompletionTimeout) userInfo:nil repeats:NO];
}

- (void)invalidateUpdateCompletionTimer {
    if (self.updateCompletionTimer) {
        if ([self.updateCompletionTimer isValid]) {
            [self.updateCompletionTimer invalidate];
        }
    }
    self.updateCompletionTimer = nil;
}

- (void)updateCompletionTimeout {
    if (self.updateCompletionBlock) {
        self.updateCompletionBlock(NO, [NSError errorWithDomain:@"invalidateUpdateCompletionTimeout" code:0 userInfo:nil]);
        self.updateCompletionBlock = nil;
    }
}

@end
