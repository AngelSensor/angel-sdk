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

#import "ANUpdateFirmwareInteractor.h"
#import "ANUpdateViewDomainModel.h"


typedef void(^TransferAndVerifyBlock)(void);
typedef void (^InnerCompletion)(void);
typedef void (^Log)(NSString* log);

@interface ANUpdateFirmwareInteractor ()

@property (nonatomic, copy) void(^transferAndVerifyBlock)(void);
@property (nonatomic, copy) void(^innerCompletion)(void);
@property (nonatomic, copy) void(^log)(NSString* log);

@property (nonatomic, assign) BOOL isHandledError;
@property (nonatomic, assign) __block BOOL recover;

@end


@implementation ANUpdateFirmwareInteractor

- (void)loadData
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnectDevice) name:kPeripheralDisconnected object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectDevice) name:kPeripheralConnected object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];

     [self.output dataLoaded];
    
    ANDataManager *dMgr = [ANDataManager sharedManager];
    dMgr.isUpdateMode = YES;
    [dMgr setServiceEnableMode:ServiceEnableModeFWUpdate];
    __weak typeof(self) wself = self;
    __weak typeof(dMgr) wdMgr = dMgr;
    
    
    self.innerCompletion = ^{
        [[ANDataManager sharedManager] setServiceEnableMode:ServiceEnableModePortrait];
    };
    
    self.log = ^(NSString* log){
        [wself.output updateWithLog:log];
    };
    
    NSString* fwname = [[dMgr updateInfo] objectForKey:@"name"];
    self.log([NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Downloading firmware:", nil), fwname]);
    [dMgr addLogHandler:self.log];
    
    void (^updateComplite)(void) = ^{
        
        wdMgr.isUpdateMode = NO;
        [wself.output updateCompliteHandler];
        wdMgr.updateInfo = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kPeripheralDisconnected object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kPeripheralConnected object:nil];
    };
    
    [dMgr addUpdateCompliteHandler:updateComplite];
    
 
    self.transferAndVerifyBlock = [self transferAndVerifyBlock];
    
    [dMgr setServiceEnableMode:ServiceEnableModeFWUpdate];
    
    ANUpdateViewDomainModel* updateViewDomainModel = [ANUpdateViewDomainModel new];
    updateViewDomainModel.updateMode = NSLocalizedString(@"Prepare", nil);
    updateViewDomainModel.progress = @"0";
    [self.output updateProgressWithModel:updateViewDomainModel];
    
    [dMgr downloadUpdateWithProgressHandler:^(NSNumber *progress) {
        
        NSInteger progressInt = [progress integerValue];
        if (progressInt > 75)
        {
            progressInt = 75;
        }
            updateViewDomainModel.progress = [NSString stringWithFormat:@"%ld",(long)progressInt];
            [wself.output updateProgressWithModel:updateViewDomainModel];
        
    } completionHandler:^(BOOL success, NSError *error) {
        if (success && !error) {
            
            updateViewDomainModel.progress = [NSString stringWithFormat:@"100"];
            [wself.output updateProgressWithModel:updateViewDomainModel];
            wself.transferAndVerifyBlock();
            [wself.output updateFirmwareState:ANFirmwareStateUpdate];

        } else {
            wself.innerCompletion();
//            wdMgr.isUpdateMode = NO;
        }
    }];
}


- (TransferAndVerifyBlock)transferAndVerifyBlock
{
    ANDataManager *dMgr = [ANDataManager sharedManager];
    __weak typeof(self) wself = self;
    __weak typeof(dMgr) wdMgr = dMgr;

    void(^transferAndVerifyBlock)(void) = ^{
        [dMgr transferAndVerifyUpdateDataWithProgressHandler:^(NSNumber *progress) {
            
            ANUpdateViewDomainModel* progressModel = [ANUpdateViewDomainModel new];
            progressModel.updateMode = NSLocalizedString(@"Firmware", nil);
            progressModel.progress = [NSString stringWithFormat:@"%ld", (long)[progress integerValue]];
            [wself.output updateProgressWithModel:progressModel];
            
        } completionHandler:^(BOOL success, NSError *error) {
            
            if (success && !error)
            {
                [wdMgr updateBraceletWithCompletionHandler:^(BOOL success, NSError *error) {
                    if (success && !error)
                    {
                        wself.innerCompletion();
                    }
                    else
                    {
                        [wself handlerError:error];
                    }
                } recover:wself.recover];
            }
            else
            {
                wself.recover = YES;
                [wself handlerError:error];
            }
        } recover:wself.recover];
    };
    
    return transferAndVerifyBlock;
}

- (void)cancelUpdate
{
    ANDataManager *dMgr = [ANDataManager sharedManager];
    [dMgr cancelUpdateFirmware];
    [self.output backSelected];
    dMgr.isUpdateMode = NO;
}

- (void)pauseUpdate
{
    ANDataManager *dMgr = [ANDataManager sharedManager];
    [dMgr pauseUpdateFirmware];
    self.recover = YES;
}

- (void)continueUpdate
{
    self.isHandledError = NO;
    ANDataManager *dMgr = [ANDataManager sharedManager];
    [dMgr continueUpdateFirmware];
}

- (void)handlerError:(NSError*)error
{
    if (!self.isHandledError)
    {
        self.isHandledError = YES;
        switch (error.code) {
            case ANFWResponseCodeNotConnectedToCharger:
            {
                [self.output showAlertWithType:ANUpdateFirmwareErrorTypeConnectedToCharger];
            } break;
            case ANFWResponseCodeInvalidCRC:
            {
                self.transferAndVerifyBlock();
            } break;
            default:
            {
                
                NSLog(@"%@", error);
            }
                break;
        }
    }
}

- (void)appDidEnterBackground
{
    [self.output appDidEnterBackground];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];   
}


#pragma mark - Notification

- (void)connectDevice
{
    self.log(NSLocalizedString(@"Connect to device", nil));
    [self.output connectDevice];
    
}

- (void)disconnectDevice
{
    self.log(NSLocalizedString(@"Disconnect device", nil));
    self.log(NSLocalizedString(@"Please check the connection with your Angel", nil));
    [self.output disconnectDevice];
}

@end
