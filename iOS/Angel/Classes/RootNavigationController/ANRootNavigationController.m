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


#import "ANRootNavigationController.h"
#import "ANHeaderView.h"
#import "ANMenuView.h"
#import "ANUpdateView.h"
#import "ANAccount.h"
#import "UIView+additions.h"
#import "NSObject+MTKObserving.h"
#import "ANUpdateFirmwareWireframe.h"


typedef enum {
    AlertViewTagConnectPowerSupply,
    AlertViewTagUpdateError,
    AlertViewTagBluetoothDisconnect,
    AlertViewTagHaveLatestVersion,
    AlertViewTagUpdate,
} AlertViewTag;

@interface ANRootNavigationController () <ANMenuViewDelegate, ANHeaderViewDelegate, ANUpdateViewDelegate, UIAlertViewDelegate>

@end

@implementation ANRootNavigationController

- (void)startApplicationFlow {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideUpdateButton) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    ANDataManager *dMgr = [ANDataManager sharedManager];
    if ([ANAccount accountExists]) {
        if (dMgr.connectedPeripheralsExists) {
            [self moveToMainScreen];
        } else {
            [self moveToWelcomeScreen];
        }
    } else {
        [self moveToWelcomeScreen];
    }
}

- (void)moveToWelcomeScreen {
    [self setHeaderViewHidden:YES];
    [self pushViewControllerWithIdentifier:@"welcomeFindMyAngelViewController" animated:NO];
}

- (void)moveToMainScreen {
    [self.menuView setSelectedItem:ANMenuViewItemMetrics];
    [self setHeaderViewHidden:NO];
    [self setViewControllerWithIdentifier:@"metricsViewController" animated:NO];
}

- (void)pushViewControllerWithIdentifier:(NSString *)identifier animated:(BOOL)animated {
    [self.headerView setHeaderMode:HeaderModeBack];
    UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    [self pushViewController:controller animated:animated];
}

- (void)setViewControllerWithIdentifier:(NSString *)identifier animated:(BOOL)animated {
    [self.headerView setHeaderMode:HeaderModeMenu];
    UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    [self setViewControllers:@[controller] animated:animated];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self.headerView setHeaderMode:HeaderModeBack];
    [super pushViewController:viewController animated:YES];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    if (self.viewControllers.count == 2) {
        [self.headerView setHeaderMode:HeaderModeMenu];
    }
    return [super popViewControllerAnimated:animated];
}

#pragma mark Update handling

- (ANUpdateView *)updateView {
    if (!_updateView) {
        _updateView = [ANUpdateView sharedView];
        _updateView.delegate = self;
    }
    return _updateView;
}

- (void)showHideUpdate {

    NSString* fwname = [[[ANDataManager sharedManager] updateInfo] objectForKey:@"name"];
    NSString* title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"New firmware version:", nil), fwname];
    
    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:title
                                                   message:NSLocalizedString(@"Update now?", nil)
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Later", nil)
                                         otherButtonTitles:NSLocalizedString(@"Update", nil), nil];
    alert.tag = AlertViewTagUpdate;
    [alert show];

}

- (void)checkFirmwareUpdate {
    void (^checkUpdateBlock)(void) = ^{
        ANDataManager *dMgr = [ANDataManager sharedManager];
        [dMgr checkUpdateExistsWithCompletionHandler:^(BOOL success, NSDictionary *info, NSError *error) {
            if (!error)
            {
                if (success)
                {
                    [self showUpdateButton];
                }
            }
        }];
    };
    
    if (!self.updateView.visible) {
        checkUpdateBlock();
    } else {
        [self removeAllObservations];
        [self observeProperty:@"updateView.visible" withBlock:^(__weak id self, id old, id newVal) {
            if (newVal && (![newVal boolValue])) {
                checkUpdateBlock();
            }
        }];
    }
}

#pragma mark ANUpdateView delegate

- (void)updateViewUpdateButtonPressed:(ANUpdateView *)updateView {
    
}

- (void)updateViewShouldClose:(ANUpdateView *)updateView {
    [self showHideUpdate];
}


#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case AlertViewTagUpdateError:
        {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [self showHideUpdate];
            } else {
                [self showUpdateButton];
            }
        } break;
        case AlertViewTagUpdate:
        {
            if(buttonIndex == alertView.cancelButtonIndex)
            {
                
            }
            else
            {
                [self startUpdate];
            }
        } break;
        default: {
            
        } break;
    }
}

- (void)startUpdate
{
    [[ANUpdateFirmwareWireframe new] presentUpdateFirmwareControllerFromNavigationController:self];
    [self hideUpdateButton];
    [self.headerView setHeaderMode:HeaderModeIcon];

}

#pragma mark Menu handling

- (ANMenuView *)menuView {
    if (!_menuView) {
        _menuView = [ANMenuView sharedMenu];
        _menuView.delegate = self;
    }
    return _menuView;
}

- (void)showHideMenu {
    if (self.menuView.visible) {
        [self.menuView hide:YES completion:nil];
    } else {
        [self.view endEditing:YES];
        [self.menuView showInView:self.view animated:YES appearance:^{
            [self.view bringSubviewToFront:self.headerView];
        } completion:nil];
    }
}

- (void)showUpdateButton {
    if ([[ANDataManager sharedManager] updateInfo] && ![[ANDataManager sharedManager] isUpdateMode]) {
        [self.headerView showUpdateButtonWithText:@"New" animated:YES];
    } else {
        [self hideUpdateButton];
    }
}

- (void)hideUpdateButton {
    [self.headerView hideUpdateButtonAnimated:YES];
}

#pragma mark ANMenuView delegate

- (void)menuView:(ANMenuView *)menuView menuItemPressed:(ANMenuViewItem)item {
    if (self.menuView.selectedItem != item) {
        [self.menuView setSelectedItem:item];
        NSString *identifier;
        switch (item) {
            case ANMenuViewItemMetrics: {
                identifier = @"metricsViewController";
            } break;
            case ANMenuViewItemAlarm: {
                identifier = @"alarmViewController";
            } break;
            case ANMenuViewItemAccount: {
                identifier = @"accountViewController";
            } break;
            case ANMenuViewItemPlayground: {
                [self checkUpdatefrm];
                return;
            } break;
            case ANMenuViewItemInfo: {
                identifier = @"infoViewController";
            } break;
        }
        if (identifier) {
            [self setViewControllerWithIdentifier:identifier animated:YES];
        }
    }
    [self.menuView hide:YES completion:nil];
}

- (void) checkUpdatefrm
{
        if ([[ANDataManager sharedManager] updateInfo])
        {
            
                [self showHideUpdate];
        }
        else
        {
            UIAlertView* alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString( @"Update firmware", nil)
                                                           message:NSLocalizedString(@"You have the latest version.", nil)
                                                          delegate:self
                                                 cancelButtonTitle: NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles: nil];
            alert.tag = AlertViewTagHaveLatestVersion;
            [alert show];
        }
}

#pragma mark Header delegate

- (void)menuButtonPressedOnHeaderView:(ANHeaderView *)headerView {
    if (self.updateView.viewMode != ViewModeUpdating) {
        if (self.updateView.visible) {
            [[ANDataManager sharedManager] setUpdating:NO];
            [self.updateView hide:YES completion:nil];
            [self showUpdateButton];
        }
        [self showHideMenu];
    }
}

- (void)backButtonPressedOnHeaderView:(ANHeaderView *)headerView {
    [self popViewControllerAnimated:YES];
}

- (void)updateButtonPressedOnHeaderView:(ANHeaderView *)headerView {
    if (self.menuView.visible) {
        [self.menuView hide:YES completion:nil];
    }
    [self showHideUpdate];
}

#pragma mark Header manipulations

- (void)setHeaderViewHidden:(BOOL)hidden {
    [self setHeaderViewHidden:hidden animated:NO];
}

- (void)setHeaderViewHidden:(BOOL)hidden animated:(BOOL)animated {
    self.headerView.hidden = hidden;
}

- (void)setupHeaderView {
    self.headerView = [UIView loadFromXibNamed:@"ANHeaderView"];
    self.headerView.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height, self.headerView.frame.size.width, self.headerView.frame.size.height);
    self.headerView.delegate = self;
    [self.view addSubview:self.headerView];
}

#pragma mark View lifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkFirmwareUpdate) name:kCheckUpdateNotification object:nil];
    
    [self setupHeaderView];
    [self startApplicationFlow];
}

- (void)dealloc {
    [self removeAllObservations];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotate {
    return YES;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
}

@end
