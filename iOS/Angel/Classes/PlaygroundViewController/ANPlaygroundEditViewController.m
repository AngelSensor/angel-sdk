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


#import "ANPlaygroundEditViewController.h"
#import "ANPlayground.h"
#import "DejalActivityView.h"

@interface ANPlaygroundEditViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIButton *saveButton;

@property (nonatomic, strong) ANPlayground *tempPlayground;

@end

@implementation ANPlaygroundEditViewController

#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)setPlayground:(ANPlayground *)playground {
    _playground = playground;
    self.tempPlayground = [playground copy];
}

#pragma mark Interface Actions

- (IBAction)saveButtonPressed:(id)sender {
    [DejalBezelActivityView activityViewForView:self.view];
    if (self.playground) {
        [self.playground updateFromCopy:self.tempPlayground];
        [[ANDataManager sharedManager] updatePlayground:self.playground completionHandler:^(BOOL success, NSError *error) {
            if (success && !error) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                //show alert
            }
            [DejalBezelActivityView removeViewAnimated:NO];
        }];
    } else {
        [[ANDataManager sharedManager] addPlayground:self.tempPlayground completionHandler:^(BOOL success, NSError *error) {
            if (success && !error) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                //show alert
            }
            [DejalBezelActivityView removeViewAnimated:NO];
        }];
    }
}

#pragma mark UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *rowCell;
    /*switch (indexPath.row) {
        case TableViewRowRepeat: {
            ANTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:@"alarmCell"];
            cell.titleLabel.text = NSLocalizedString(@"Repeat", nil);
            cell.valueField.text = [ANEnumManager stringFromRepeatMode:self.tempAlarm.alarmRepeatMode];
            cell.valueField.userInteractionEnabled = NO;
            cell.accessoryType = UITableViewCellAccessoryNone;
            rowCell = cell;
        } break;
        case TableViewRowVibrate: {
            ANAlarmEditCell *cell = [tableView dequeueReusableCellWithIdentifier:@"alarmEditCell"];
            cell.titleLabel.text = NSLocalizedString(@"Vibrate", nil);
            cell.valueField.text = self.tempAlarm.alarmVibrate ? NSLocalizedString(@"On", nil) : NSLocalizedString(@"Off", nil);
            cell.valueField.userInteractionEnabled = NO;
            [cell.alarmSwitch setOn:self.tempAlarm.alarmVibrate];
            cell.accessoryType = UITableViewCellAccessoryNone;
            rowCell = cell;
        } break;
        case TableViewRowSound: {
            ANTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:@"alarmCell"];
            cell.titleLabel.text = NSLocalizedString(@"Sound", nil);
            cell.valueField.text = self.tempAlarm.alarmSoundID ? [NSString stringWithFormat:@"Sound %@", self.tempAlarm.alarmSoundID] : nil;
            cell.valueField.userInteractionEnabled = NO;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            rowCell = cell;
        } break;
    }*/
    return rowCell;
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)cellFromControl:(UIControl *)sender {
    UIView *view = sender;
    while (view && (![view isKindOfClass:[UITableViewCell class]])) {
        view = view.superview;
    }
    UITableViewCell *cell = (UITableViewCell *)view;
    NSAssert([cell isKindOfClass:[UITableViewCell class]], @"");
    return cell;
}

#pragma mark Data reloading

- (void)reloadData {
    if (!self.tempPlayground) {
        self.tempPlayground = [[ANPlayground alloc] init];
    }
    [self.tableView reloadData];
}

#pragma mark View lifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.saveButton.layer.masksToBounds = YES;
    self.saveButton.layer.cornerRadius = 3.0f;
    
    [self reloadData];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
