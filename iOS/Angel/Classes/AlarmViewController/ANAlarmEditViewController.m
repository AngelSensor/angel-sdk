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


#import "ANAlarmEditViewController.h"
#import "ANRootNavigationController.h"
#import "ANAlarmRepeatViewController.h"
#import "ANAlarmSoundViewController.h"
#import "ANTitleValueCell.h"
#import "ANAlarmEditCell.h"
#import "ANAlarm.h"
#import "DejalActivityView.h"

typedef enum {
    //TableViewRowRepeat,
    //TableViewRowVibrate,
    //TableViewRowSound,
    rowsCount
} TableViewRow;

@interface ANAlarmEditViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, weak) IBOutlet UIButton *alarmButton;

@property (nonatomic, strong) ANAlarm *tempAlarm;

@end

@implementation ANAlarmEditViewController

#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)setAlarm:(ANAlarm *)alarm {
    _alarm = alarm;
    self.tempAlarm = [alarm copy];
}

- (void)showFailedAlarmAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"Failed to create alarm", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", nil) otherButtonTitles:nil];
    [alert show];
}

- (void)showMaximumAlarmAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"Amount of alarms exceeds wristband`s limit", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", nil) otherButtonTitles:nil];
    [alert show];
}

#pragma mark Interface Actions

- (IBAction)alarmButtonPressed:(id)sender {
    [DejalBezelActivityView activityViewForView:self.view];
    
    void (^handleErrorWithCode)(NSInteger code) = ^(NSInteger code) {
        if (code == MaximumAmountOfAlarmsReachedErrorCode) {
            [self showMaximumAlarmAlert];
        } else {
            [self showFailedAlarmAlert];
        }
    };
    
    if (self.alarm) {
        [[ANDataManager sharedManager] updateAlarm:self.alarm completionHandler:^(BOOL success, NSError *error) {
            if (success && !error) {
                [self.alarm updateFromCopy:self.tempAlarm];
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                handleErrorWithCode(error.code);
            }
            [DejalBezelActivityView removeViewAnimated:NO];
        }];
    } else {
        [[ANDataManager sharedManager] addAlarm:self.tempAlarm completionHandler:^(BOOL success, NSError *error) {
            if (success && !error) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                handleErrorWithCode(error.code);
            }
            [DejalBezelActivityView removeViewAnimated:NO];
        }];
    }
}

- (IBAction)alarmSwitchValueChanged:(UISwitch *)sender {
    self.tempAlarm.alarmVibrate = sender.isOn;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:[self cellFromControl:sender]];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)datePickerValueChanged:(UIDatePicker *)sender {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSTimeZoneCalendarUnit) fromDate:sender.date];
    [components setSecond:0];
    self.tempAlarm.alarmTime = [[NSCalendar currentCalendar] dateFromComponents:components];
}

#pragma mark UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return rowsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *rowCell;
    switch (indexPath.row) {
        /*case TableViewRowRepeat: {
            ANTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:@"alarmCell"];
            cell.titleLabel.text = NSLocalizedString(@"Repeat", nil);
            cell.valueField.text = [ANEnumManager stringFromRepeatMode:self.tempAlarm.alarmRepeatMode];
            cell.valueField.userInteractionEnabled = NO;
            cell.accessoryType = UITableViewCellAccessoryNone;
            rowCell = cell;
        } break;
        /case TableViewRowVibrate: {
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
        } break;*/
    }
    return rowCell;
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *controller;
    switch (indexPath.row) {
        /*case TableViewRowRepeat: {
            controller = [self.storyboard instantiateViewControllerWithIdentifier:@"alarmRepeatViewController"];
            [(ANAlarmRepeatViewController *)controller setAlarm:self.tempAlarm];
        } break;
        case TableViewRowVibrate: {
            
        } break;
        case TableViewRowSound: {
            controller = [self.storyboard instantiateViewControllerWithIdentifier:@"alarmSoundViewController"];
            [(ANAlarmSoundViewController *)controller setAlarm:self.tempAlarm];
        } break;*/
    }
    
    if (controller) {
        [(ANRootNavigationController *)self.navigationController pushViewController:controller animated:YES];
    }
    
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
    if (!self.tempAlarm) {
        self.tempAlarm = [[ANAlarm alloc] init];
        self.tempAlarm.alarmTime = [NSDate date];
    }
    self.datePicker.minimumDate = self.tempAlarm.alarmTime;
    self.datePicker.date = self.tempAlarm.alarmTime;
    [self.tableView reloadData];
}

#pragma mark View lifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self.navigationController setNavigationBarHidden:YES animated:animated];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.alarmButton.layer.masksToBounds = YES;
    self.alarmButton.layer.cornerRadius = 3.0f;

    [self reloadData];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
