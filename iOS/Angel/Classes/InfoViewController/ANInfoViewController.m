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


#import "ANInfoViewController.h"
#import "ANTitleValueCell.h"
#import "ANAccountWristbandCell.h"
#import "ANRootNavigationController.h"
#import "ANPeripheral.h"

typedef enum {
    TableViewUserRowSerial,
    TableViewUserRowVersion,
    TableViewUserRowWristbandVersion,
    //TableViewUserRowTutorial,
    tableViewUserRowCount
} TableViewUserRow;

typedef enum {
    TableViewSectionInfo,
    TableViewSectionWristband,
    tableViewSectionCount
} TableViewSection;

typedef enum {
    AlertViewTagNone,
    AlertViewTagForget
} AlertViewTag;

@interface ANInfoViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *braceletsContainer;

@property (nonatomic, strong) NSIndexPath *selectedDateIndexPath;
@property (nonatomic, strong) NSIndexPath *selectedForgetIndexPath;

@end

@implementation ANInfoViewController


#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}


#pragma mark Forget Bracelet handling

- (IBAction)forgetDeviceButtonPressed:(UIButton *)sender {
    self.selectedForgetIndexPath = [self.tableView indexPathForCell:[self cellFromButton:sender]];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"Are you sure you want to forget this device?", nil) delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert setTag:AlertViewTagForget];
    [alert show];
}

- (IBAction)searchBraceletsButtonPressed:(UIButton *)sender {
    [self forgetSelectedWristband];
}

- (void)forgetSelectedWristband {
    self.selectedForgetIndexPath = nil;
    [[ANDataManager sharedManager] forgetDevice];
    [(ANRootNavigationController *)self.navigationController moveToWelcomeScreen];
}

#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        switch (alertView.tag) {
            case AlertViewTagForget: {
                [self forgetSelectedWristband];
            } break;
            default: {
                
            } break;
        }
    }
}

#pragma mark Data reloading

- (void)reloadData {
    if ([[ANDataManager sharedManager] currentWristband]) {
        self.braceletsContainer = @[[[ANDataManager sharedManager] currentWristband]];
    }
    else {
        self.braceletsContainer = nil;
    }
    [self.tableView reloadData];
}

#pragma mark UITableView dataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return tableViewSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case TableViewSectionInfo: {
            return tableViewUserRowCount;
        } break;
        case TableViewSectionWristband: {
            if (self.braceletsContainer.count) {
                return self.braceletsContainer.count;
            } else {
                return 1;
            }
        } break;
        default: {
            return 0;
        } break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case TableViewSectionInfo: {
            ANTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            cell.accessoryType = UITableViewCellAccessoryNone;
            switch (indexPath.row) {
                case TableViewUserRowSerial: {
                    cell.titleLabel.text = NSLocalizedString(@"SN", nil);
                    cell.valueLabel.text = [[[ANDataManager sharedManager] currentWristband] identifier];
                    [cell setUserInteractionEnabled:NO];
                } break;
                case TableViewUserRowVersion: {
                    cell.titleLabel.text = NSLocalizedString(@"App Version", nil);
                    cell.valueLabel.text = [NSString stringWithFormat:@"%@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
                    [cell setUserInteractionEnabled:NO];
                } break;
                case TableViewUserRowWristbandVersion: {
                    cell.titleLabel.text = NSLocalizedString(@"Firmware Version", nil);
                    cell.valueLabel.text = [[ANDataManager sharedManager] firmwareVersion];
                    [cell setUserInteractionEnabled:NO];
                } break;
                /*case TableViewUserRowTutorial: {
                    cell.titleLabel.text = NSLocalizedString(@"Tutorial", nil);
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    [cell setUserInteractionEnabled:YES];
                } break;*/
                default: {
                } break;
            }
            return cell;
        } break;
        case TableViewSectionWristband: {
            if (self.braceletsContainer.count) {
                ANAccountWristbandCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountBraceletCell"];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                ANPeripheral *bracelet = [self.braceletsContainer objectAtIndex:indexPath.row];
                cell.valueField.text = bracelet.identifier;
                cell.valueField.userInteractionEnabled = NO;
                cell.wristbandImageView.image = [UIImage imageNamed:bracelet.connected ? @"icn_braclate" : @"icn_sensor"];
                return cell;
            } else {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"noBraceletsCell"];
                return cell;
            }
        } break;
        default: {
            return nil;
        } break;
    }
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case TableViewSectionInfo: {
            switch (indexPath.row) {
                case TableViewUserRowSerial: {

                } break;
                case TableViewUserRowVersion: {
                    
                } break;
                case TableViewUserRowWristbandVersion: {
                    
                } break;
                /*case TableViewUserRowTutorial: {
                    
                } break;*/
            }
        } break;
        default: {
        } break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (ANAccountWristbandCell *)cellFromButton:(UIButton *)sender {
    UIView *view = sender;
    while (view && (![view isKindOfClass:[ANAccountWristbandCell class]])) {
        view = view.superview;
    }
    ANAccountWristbandCell *cell = (ANAccountWristbandCell *)view;
    NSAssert([cell isKindOfClass:[ANAccountWristbandCell class]], @"");
    return cell;
}

#pragma mark View lifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:kPeripheralStatusChangedNotification object:nil];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


@end
