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

#import "ANUpdateFirmwareVC.h"
#import "ANUpdateFirmwareController.h"
#import "ANUpdateFirmwareDataSource.h"
#import "ANUpdateFirmwareContentView.h"
#import "ANAppDelegate.h"


@interface ANUpdateFirmwareVC ()

@property (nonatomic, strong) ANUpdateFirmwareController* controller;
@property (nonatomic, strong) ANUpdateFirmwareContentView* contentView;
@property (nonatomic, assign) NSInteger updateState;

@property (nonatomic, assign) BOOL showDicconnectAlert;
@end


@implementation ANUpdateFirmwareVC

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.contentView = [ANUpdateFirmwareContentView new];
        self.controller = [[ANUpdateFirmwareController alloc] initWithTableView:self.contentView.tableView];
    }
    return self;
}

- (void)loadView
{
    self.view = self.contentView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.contentView.cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView.pauseButton addTarget:self action:@selector(pauseAction:) forControlEvents:UIControlEventTouchUpInside];
    self.showDicconnectAlert = YES;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resingAction) name:UIApplicationWillResignActiveNotification object:nil];
}
 
- (void)resingAction
{
    [self pauseAction:self.contentView.pauseButton];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Action

- (void)cancelAction:(UIButton*)sender
{
    [self.eventHandler canccelSelected];
}

- (void)pauseAction:(UIButton*)sender
{
    if (self.updateState == 1)
    {
        if (sender.selected)
        {
            [self.eventHandler continueSelected];
        }
        else
        {
            [self.eventHandler pauseSelected];
        }
        sender.selected = !sender.selected;
        
    }
}


- (void)connectDevice
{
    self.contentView.pauseButton.enabled = YES;
    self.showDicconnectAlert = YES;

}

- (void)disconnectDevice
{
    [self pause];
    self.contentView.pauseButton.enabled = NO;
    if (self.showDicconnectAlert)
    {
        NSString* title = NSLocalizedString(@"Device disconnected", nil);
        NSString* message = NSLocalizedString(@"Check the connection to the device, and click Continue", nil);
        [[[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil]show];
        self.showDicconnectAlert = NO;
    }
}


#pragma mark - User Interface

- (void)pause
{
    if (!self.contentView.pauseButton.selected)
    {
        [self.eventHandler pauseSelected];
        self.contentView.pauseButton.selected = YES;
    }
}

- (void)updateDataSource:(ANUpdateFirmwareDataSource *)dataSource
{
    [self.controller updateDataSource:dataSource];
}

- (void)updateViewWithModel:(ANUpdateViewDomainModel*)model
{
    [self.contentView updateWithModel:model];
}

- (void)updateFirmwareState:(NSInteger)state
{
    self.updateState = state;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ANTableController Delegate


@end
