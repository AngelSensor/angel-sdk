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

#import "ANUpdateFirmwarePresenter.h"
#import "ANUpdateFirmwareDataSource.h"


typedef NS_ENUM(NSInteger, ANUpdateFirmwareAlertType) {
    ANUpdateFirmwareAlertTypeCancel = 10,
    ANUpdateFirmwareAlertTypeContinue,
    ANUpdateFirmwareAlertTypeComplite,
};

@interface ANUpdateFirmwarePresenter () <ANUpdateFirmwareDataSourceDelegate>

@property (nonatomic, strong) ANUpdateFirmwareDataSource* tableDataSource;

@end

@implementation ANUpdateFirmwarePresenter

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.tableDataSource = [ANUpdateFirmwareDataSource new];
        self.tableDataSource.delegate = self;
    }
    return self;
}

- (void)configurePresenterWithUserInterface:(UIViewController<ANUpdateFirmwareViewInterface>*)userInterface
{
    self.userInterface = userInterface;
    [self.userInterface updateDataSource:self.tableDataSource];
    [self.interactor loadData];
}


#pragma mark - Output

- (void)dataLoaded
{
    [self.tableDataSource setupStorage];
}

- (void)showAlertWithType:(ANUpdateFirmwareErrorType)type
{
    NSString* title;
    NSString* message;
    if (type == ANUpdateFirmwareErrorTypeDisconnect)
    {
        title = NSLocalizedString(@"Disconnect", nil);
        message =  NSLocalizedString(@"Verify bluetooth connect", nil);
    }
    else if (type == ANUpdateFirmwareErrorTypeConnectedToCharger)
    {
        title = NSLocalizedString(@"Warning", nil);
        message = NSLocalizedString(@"Check connection to charger", nil);
    }
    
    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:title
                                                   message:message
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel update", nil)
                                         otherButtonTitles:NSLocalizedString(@"Continue", nil), nil];
    alert.tag = ANUpdateFirmwareAlertTypeContinue;
    [alert show];
}

- (void)updateWithLog:(NSString*)log
{
    [self.tableDataSource addLog:log];
}

- (void)updateProgressWithModel:(ANUpdateViewDomainModel*)model
{
    [self.userInterface updateViewWithModel:model];
}

- (void)updateFirmwareState:(ANFirmwareState)state
{
    [self.userInterface updateFirmwareState:state];
}

- (void)appDidEnterBackground
{
    [self.userInterface pause];
}

- (void)updateCompliteHandler
{
    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Complete", nil)   message:NSLocalizedString(@"Wait for 20 - 100 seconds until the updates come into force.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles: nil];
    alert.tag = ANUpdateFirmwareAlertTypeComplite;
    [alert show];
}

- (void)disconnectDevice
{
    [self.userInterface disconnectDevice];
}

- (void)connectDevice
{
    [self.userInterface connectDevice];
}


#pragma mark - Module Interface

- (void)backSelected
{
    [self.wireframe dismissUpdateFirmwareController];
}

- (void)canccelSelected
{
  UIAlertView* alert =  [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Cancel", nil)
                               message:NSLocalizedString(@"All progress will be lost. Are you sure?", nil)
                              delegate:self
                     cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                     otherButtonTitles:NSLocalizedString(@"Ok",nil), nil];
    
    alert.tag = ANUpdateFirmwareAlertTypeCancel;
    [alert show];
}

- (void)pauseSelected
{
    [self.interactor pauseUpdate];
}

- (void)continueSelected
{
    [self.interactor continueUpdate];
}



#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
            
        case ANUpdateFirmwareAlertTypeCancel:
        {
            if (buttonIndex == alertView.cancelButtonIndex)
            {
            }
            else
            {
                [self.interactor cancelUpdate];
            }
        } break;
            
        case ANUpdateFirmwareAlertTypeContinue:
        {
         
            if (buttonIndex == alertView.cancelButtonIndex)
            {
                [self.interactor cancelUpdate];
            }
            else
            {
                [self.interactor continueUpdate];
            }
        } break;
        case ANUpdateFirmwareAlertTypeComplite:
        {
            [self.wireframe dismissUpdateFirmwareController];
        } break;
    }
    
}

@end
