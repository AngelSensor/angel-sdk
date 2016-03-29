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


#import "ANFirmwareUpdateManager.h"
#import "ANDataManager.h"
#import "ANFirmwareUpdateService.h"
#import "ANFirmwareUpdateConrolPointCharacteristic.h"
#import "ANFirmwareUpdateFeatureCharacteristic.h"
#import "ANHexWrapper.h"
#import "ANDownloadManager.h"
#import "AFNetworkReachabilityManager.h"

@interface ANFirmwareUpdateManager()

@property (copy) ProgressBlock transferProgressBlock;
@property (copy) SimpleSuccessBlock transferCompletionBlock;

@property (nonatomic, strong) NSString *firmwareVersion;

@property (nonatomic, assign) BOOL isPause;
@property (nonatomic, assign) ANUpdateStage lastStage;

@end

@implementation ANFirmwareUpdateManager

- (UInt16)accessKey {
    return _service.featureChar.accessCode;
}

- (instancetype)initWithService:(ANFirmwareUpdateService *)service {
    self = [super init];
    if (self) {
        
        NSLog(@"initWithService");
        _service = service;
        ANDataManager *dMgr = [ANDataManager sharedManager];
        self.stage = ANUpdateStageNotActive;
        self.updateInProgress = NO;
        __weak ANFirmwareUpdateManager *wSelf = self;
        
        [dMgr firmwareUpdateWithHandler:^(ANFWResponseCode response, UInt16 value) {
            [wSelf handleServiceUpdateResponse:response value:value];
        }];
    }
    return self;
}

- (void)beginUpdate {
    _currentIndex = 0;
    self.stage = ANUpdateStageDownloadFirmware;
}

- (void)cancelUpdate {
    self.updateInProgress = NO;
    self.stage = ANUpdateStageCanceled;
}

- (void)setStage:(ANUpdateStage)stage {
    _stage = stage;
    switch (stage) {
        case ANUpdateStageDownloadFirmware: {
        } break;
        case ANUpdateStageEraseStagingArea: {
            [self eraseStagingArea];
        } break;
        case ANUpdateStageTransmitCodeBlocks: {
            [self transmitCodeBlocks];
        } break;
        case ANUpdateStageReadCRC: {
            [self sendReadCRCRequest];
        } break;
        case ANUpdateStageStartFWUpdate: {
            [self startFirmwareUpdate];
            
        } break;
        case ANUpdateStageCanceled: {
            [[ANDownloadManager sharedManager] stopDownloading];
            self.updateInProgress = NO;
        } break;
        case ANUpdateStagePause:
        {
            
            self.isPause = YES;
            if (_currentIndex > 0)
            {
                _currentIndex--;
            }
            
        } break;
        case ANUpdateStageContinue:
        {
            [self continueUpdate];
        } break;
        default: {
        } break;
    }
}


- (void)pauseUpdate
{
    self.stage = ANUpdateStagePause;
    self.updateLog(@"Pause");
}

- (void)continueUpdate
{
    self.updateLog(@"Continue");
    if (self.isPause)
    {
        self.isPause = NO;
        self.stage = ANUpdateStageTransmitCodeBlocks;
    }
    else
    {
        self.stage = ANUpdateStageEraseStagingArea;
    }
}

- (void)eraseStagingArea {
    [self.service.controlPointChar eraseStagingArea:self.accessKey];
    self.updateLog(NSLocalizedString(@"Clearing the staging area.", nil));

}

- (void)transmitCodeBlocks {
    NSData *block = [self.hexWrapper blockAtIndex:self.currentIndex];
    
    self.updateLog([NSString stringWithFormat:@"Sending block at index: %d / %ld", self.currentIndex + 1, (long)self.hexWrapper.pages]);
    
    [self.service setCharacteristicsNotifyValue:YES];
    [self.service.controlPointChar writeCodeBlock:block withAccessKey:self.accessKey];
}

- (void)sendReadCRCRequest {
    [self.service.controlPointChar readCRCForCodeBlockAtIndex:self.currentIndex];
    
    self.updateLog(NSLocalizedString(@"Read CRC for code block", nil));
}

- (void)startFirmwareUpdate {
    [self.service.controlPointChar initiateFirmwareUpdateFromStaging:self.accessKey];
    self.updateLog([NSString stringWithFormat:NSLocalizedString(@"Initiate firmware update", nil)]);
    if (self.updateCompliteHandler)
    {
        self.updateCompliteHandler();
    }
}

- (BOOL)validateCRC:(UInt16)CRC forIndex:(NSUInteger)index {
    return [self.hexWrapper validateCRC:CRC forBlockAtIndex:index];
}

- (void)handleServiceUpdateResponse:(ANFWResponseCode)code value:(UInt16)value {
    if (code != ANFWResponseCodeSuccess) {
        
    }
    switch (self.stage) {
        case ANUpdateStageEraseStagingArea: {
            NSLog(@"ANUpdateStageEraseStagingArea");
            if (code == ANFWResponseCodeSuccess)
            {
                self.updateLog(NSLocalizedString(@"Success", nil));
                self.stage = ANUpdateStageTransmitCodeBlocks;
            }
            else
            {
                if (self.transferCompletionBlock)
                {
                    NSString* errorDescrib = [self descriptionErrorForCode:code];
                    self.updateLog([NSString stringWithFormat:@"Error: %@", errorDescrib]);
                    self.transferCompletionBlock(NO, [NSError errorWithDomain:@"ANUpdateStageEraseStagingArea" code:code userInfo:nil]);
                }
                self.updateInProgress = NO;
            }
        } break;
        case ANUpdateStageTransmitCodeBlocks: {
            NSLog(@"ANUpdateStageTransmitCodeBlocks");
            if (code == ANFWResponseCodeSuccess)
            {
                if (_currentIndex < self.hexWrapper.pages - 1)
                {
                    _currentIndex++;
                    if (self.transferProgressBlock)
                    {
                        self.transferProgressBlock(@(((self.currentIndex + 1) / (double)(self.hexWrapper.pages)) * 100));
                    }
                    [self transmitCodeBlocks];
                }
                else
                {
                    self.stage = ANUpdateStageReadCRC;
                }
            }
            else
            {
                if (self.transferCompletionBlock)
                {
                    NSString* errorDescrib = [self descriptionErrorForCode:code];
                    self.updateLog([NSString stringWithFormat:@"Error %@", errorDescrib]);
                    self.transferCompletionBlock(NO, [NSError errorWithDomain:@"ANUpdateStageTransmitCodeBlocks" code:code userInfo:nil]);
                    self.isPause = YES;
                }
                self.updateInProgress = NO;
            }
        } break;
        case ANUpdateStageReadCRC: {
            if (code == ANFWResponseCodeSuccess)
            {
                if (self.transferCompletionBlock)
                {
                    self.transferCompletionBlock(YES, nil);
                }
            }
            else
            {
                if (self.transferCompletionBlock)
                {
                    self.transferCompletionBlock(NO, [NSError errorWithDomain:@"ANUpdateStageReadCRC" code:code userInfo:nil]);
                    self.updateLog(NSLocalizedString(@"Update stage read CRC - error", nil));
                }
            }
            self.updateInProgress = NO;
        } break;
        case ANUpdateStageStartFWUpdate:
        {
            
        } break;
            
        case ANUpdateStagePause:
        {
            
        } break;
        default: {
            
        } break;
    }
}

- (void)continueFromCurrentState {
    [self setStage:self.stage];
}

#pragma mark Update controls

- (void)checkUpdateExists:(NSString *)firmwareVersion completionHandler:(CheckUpdateBlock)completionHandler {
    self.updateInProgress = YES;
    self.firmwareVersion = [firmwareVersion stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
    [[ANDataManager sharedManager] setFirmwareVersion:self.firmwareVersion];
    [self downloadContentForVersion:self.firmwareVersion completionHandler:completionHandler];
}

- (void)downloadContentForVersion:(NSString *)version completionHandler:(CheckUpdateBlock)completionHandler {

//    version = @"DANIEL020";
    BOOL isConnect =[AFNetworkReachabilityManager sharedManager].networkReachabilityStatus != AFNetworkReachabilityStatusNotReachable;
    if (version && isConnect) {
        NSString *suffix = [version hasSuffix:@".json"] ? @"" : @".json";
        NSString *urlString = [NSString stringWithFormat:@"http://www.angelsensor.com/versions/%@%@", version, suffix];
        NSURL *url = [NSURL URLWithString:urlString];
        DLog(@"CHECKING VERSION %@", url.absoluteString);
        [[ANDownloadManager sharedManager] downloadContentFrom:url completion:^(NSDictionary *result, NSError *error) {
            if (completionHandler) {
                DLog(@"UPDATE RESULT %@", result);
                if (result && !error) {
                    if ([[result objectForKey:kIsRequired] boolValue]) {
                        DLog(@"UPDATE REQUIRED, UPDATING");
                        self.updateInfo = result;
                        completionHandler(YES, self.updateInfo, nil);
                    } else {
                        NSString *nextVersion = [result objectForKey:kNextVersion];
                        if (nextVersion && [nextVersion isKindOfClass:[NSString class]]) {
                            DLog(@"UPDATE NOT REQUIRED, CHECKING NEXT VERSION %@", nextVersion);
                            [self downloadContentForVersion:nextVersion completionHandler:completionHandler];
                        } else {
                            if ([self.firmwareVersion isEqualToString:version]) {
                                DLog(@"UPDATE NOT REQUIRED %@, FINISHING", nextVersion);
                                completionHandler(NO, nil, nil);
                            } else {
                                DLog(@"UPDATE NOT REQUIRED, BUT VERSION IS NOT EQUAL, UPDATING");
                                self.updateInfo = result;
                                completionHandler(YES, self.updateInfo, nil);
                            }
                        }
                    }
                } else {
                    DLog(@"UPDATE FAILED");
                    completionHandler(NO, nil, error);
                }
            }
        }];
    } else {
        DLog(@"UPDATE FAILED");
        if (completionHandler) {
            completionHandler(NO, nil, nil);
        }
    }
}

- (void)downloadUpdateWithProgressHandler:(ProgressBlock)progressHandler completionHandler:(SimpleSuccessBlock)completionHandler {
    _currentIndex = 0;
    [self setStage:ANUpdateStageDownloadFirmware];
    DLog(@"DOWNLOADING FILE FROM %@", [self.updateInfo objectForKey:kPath]);
    [[ANDownloadManager sharedManager] downloadFileFrom:[NSURL URLWithString:[self.updateInfo objectForKey:kPath]] progress:^(NSNumber *progress) {
        if (progressHandler) {
            progressHandler(progress);
        }
    } completion:^(NSString *filePath, NSError *error) {
        if (filePath && !error) {
            
            NSString *selectedFilePath ;
            
    #ifdef TEST_UPDATE_MODE
            self.updateLog(@"Test Model: daniel27g27");
            selectedFilePath  = [[NSBundle mainBundle] pathForResource:@"daniel27g27" ofType:@"hex"];
    #else
            selectedFilePath = filePath;
    #endif
            self.updateLog(@"Unpacking the firmware");
            BSDispatchBlockToBackgroundQueue(^{
                
                self.hexWrapper = [[ANHexWrapper alloc] initWithHexFile:selectedFilePath];
                
                BSDispatchBlockToMainQueue(^{
                    
                    self.updateLog(@"Success");
                    if (completionHandler){
                        completionHandler(YES, error);
                    }
                });
                
            });
        }
        else
        {
            if (completionHandler) {
                self.updateLog([NSString stringWithFormat:@"%@",error]);
                completionHandler(NO, error);
            }
        }
    }];
}

- (void)transferAndVerifyUpdateDataWithProgressHandler:(ProgressBlock)progressHandler completionHandler:(SimpleSuccessBlock)completionHandler recover:(BOOL)recover {
    self.transferProgressBlock = progressHandler;
    self.transferCompletionBlock = completionHandler;
    if (!recover) {
        _currentIndex = 0;
        self.stage = ANUpdateStageEraseStagingArea;
    } else {
        
        self.stage = ANUpdateStageContinue;
        [self continueFromCurrentState];
        
    }
}

- (void)updateBracelet {
    self.stage = ANUpdateStageStartFWUpdate;
}

- (void)deviceDisconnected {
    [self cancelUpdate];
    if (self.transferCompletionBlock) {
        self.transferCompletionBlock(NO, [NSError errorWithDomain:@"deviceDisconnected" code:ANFWResponseCodeDeviceDisconnected userInfo:nil]);
    }
    self.transferCompletionBlock = nil;
    self.transferProgressBlock = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString*)descriptionErrorForCode:(NSInteger)code
{
    switch (code) {
        case 1:
            return NSLocalizedString(@"Success", nil);
            break;
        case 2:
        {
            return NSLocalizedString(@"Op Code not supported", nil);
        } break;
        case 3:
        {
            return NSLocalizedString(@"Invalid operator. Returned if the Access Key is invalid.", nil);
        } break;
        case 4:
        {
            return NSLocalizedString(@"Invalid CRC. Returned if the CRC-16 signature of the code block is invalid.", nil);
        } break;
        case 5:
        {
            return NSLocalizedString(@"Invalid code block. Returned if the StartAddress, Block Index or block size is invalid.", nil);
        } break;
        case 6:
        {
            return NSLocalizedString(@"Staging area validation failure.", nil);
        } break;
        case 7:
        {
            return NSLocalizedString(@"Power source disconnected.", nil);
        }
            
        default:
            return [NSString stringWithFormat:@"%ld", (long)code];
            break;
    }
}

@end
