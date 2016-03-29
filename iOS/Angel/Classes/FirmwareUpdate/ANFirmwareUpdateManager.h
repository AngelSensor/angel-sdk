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

@class ANHexWrapper, ANFirmwareUpdateService, ANFirmwareUpdateManager;

typedef NS_ENUM(NSUInteger, ANUpdateStage) {
    ANUpdateStageNotActive,
    ANUpdateStageDownloadFirmware,
    ANUpdateStageEraseStagingArea,
    ANUpdateStageTransmitCodeBlocks,
    ANUpdateStageReadCRC,
    ANUpdateStageStartFWUpdate,
    ANUpdateStageCanceled,
    ANUpdateStagePause,
    ANUpdateStageContinue,
};

@protocol ANFirmwareUpdateDelegate <NSObject>

- manager:(ANFirmwareUpdateManager *)manager didMoveToStage:(ANUpdateStage)stage;
- manager:(ANFirmwareUpdateManager *)manager didFailWithError:(NSError *)error;

@end

@interface ANFirmwareUpdateManager : NSObject

@property (nonatomic, weak) id <ANFirmwareUpdateDelegate>    delegate;
@property (nonatomic, readonly) ANUpdateStage               stage;
@property (nonatomic, readonly) UInt16                      currentIndex;
@property (nonatomic, strong)   ANHexWrapper *              hexWrapper;

@property (nonatomic, strong)   ANFirmwareUpdateService *   service;
@property (nonatomic, copy)     UpdateLog                   updateLog;
@property (nonatomic, copy)     UpdateComplite              updateCompliteHandler;

@property (nonatomic, strong) NSDictionary *updateInfo;
@property BOOL updateInProgress;

- (instancetype)initWithService:(ANFirmwareUpdateService *)service;
- (void)cancelUpdate;
- (void)pauseUpdate;
- (void)continueUpdate;

- (void)checkUpdateExists:(NSString *)firmwareVersion completionHandler:(CheckUpdateBlock)completionHandler;
- (void)downloadUpdateWithProgressHandler:(ProgressBlock)progressHandler completionHandler:(SimpleSuccessBlock)completionHandler;
- (void)transferAndVerifyUpdateDataWithProgressHandler:(ProgressBlock)progressHandler completionHandler:(SimpleSuccessBlock)completionHandler recover:(BOOL)recover;
- (void)continueFromCurrentState;
- (void)updateBracelet;
- (void)deviceDisconnected;

@end
