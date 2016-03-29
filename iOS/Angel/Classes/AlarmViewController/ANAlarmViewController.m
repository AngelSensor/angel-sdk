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


#import "ANAlarmViewController.h"
#import "ANAlarmEditViewController.h"
#import "ANRootNavigationController.h"
#import "ANAlarmCell.h"
#import "ANAlarm.h"
#import "NSDate+Utilities.h"
#import "DejalActivityView.h"

typedef enum {
    AlertViewTagNone,
    AlertViewTagRemove
} AlertViewTag;

@interface ANAlarmViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *dataContainer;

@property (nonatomic, strong) NSIndexPath *selectedRemoveIndexPath;

@property (nonatomic, strong) NSTimer *timeMonitoringTimer;
@property (nonatomic, strong) UIAlertView *removeAlertView;

@end

@implementation ANAlarmViewController

#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

#pragma mark Interface Actions

- (IBAction)addButtonPressed:(id)sender {
    [(ANRootNavigationController *)self.navigationController pushViewControllerWithIdentifier:@"alarmEditViewController" animated:YES];
}

#pragma mark Alarm actions

- (IBAction)removeAlarmButtonPressed:(UIButton *)sender {
    self.selectedRemoveIndexPath = [self.tableView indexPathForCell:[self cellFromControl:sender]];
    if (self.removeAlertView) {
        [self.removeAlertView dismissWithClickedButtonIndex:self.removeAlertView.cancelButtonIndex animated:NO];
    }
    self.removeAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"Are you sure you want to remove this alarm?", nil) delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [self.removeAlertView setTag:AlertViewTagRemove];
    [self.removeAlertView show];
}

- (IBAction)onOffAlarmValueChanged:(UISwitch *)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:[self cellFromControl:sender]];
    ANAlarm *alarm = [self.dataContainer objectAtIndex:indexPath.row];
    alarm.alarmEnabled = sender.isOn;
    [DejalBezelActivityView activityViewForView:self.view];
    [[ANDataManager sharedManager] updateAlarm:alarm completionHandler:^(BOOL success, NSError *error) {
        if (success && !error) {
            
        } else {
            //show alert
        }
        [DejalBezelActivityView removeViewAnimated:NO];
    }];
}

- (void)removeSelectedAlarm {
    ANAlarm *alarm = [self.dataContainer objectAtIndex:self.selectedRemoveIndexPath.row];
    [DejalBezelActivityView activityViewForView:self.view];
    [self.tableView beginUpdates];
    [[ANDataManager sharedManager] removeAlarm:alarm completionHandler:^(BOOL success, NSError *error) {
        if (success && !error) {
            if (self.dataContainer) {
                NSMutableArray *tempContainer = [NSMutableArray arrayWithArray:self.dataContainer];
                [tempContainer removeObjectAtIndex:self.selectedRemoveIndexPath.row];
                self.dataContainer = tempContainer;
                [self.tableView deleteRowsAtIndexPaths:@[self.selectedRemoveIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        } else {
            //show alert
        }
        [self.tableView endUpdates];
        self.selectedRemoveIndexPath = nil;
        [DejalBezelActivityView removeViewAnimated:NO];
    }];

}

#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        switch (alertView.tag) {
            case AlertViewTagRemove: {
                [self removeSelectedAlarm];
                self.removeAlertView = nil;
            } break;
            default: {
                
            } break;
        }
    }
}

#pragma mark UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataContainer.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ANAlarmCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    ANAlarm *alarm = [self.dataContainer objectAtIndex:indexPath.row];
    
    ANDataManager *dMgr = [ANDataManager sharedManager];
    
    cell.alarmTimeLabel.text = [dMgr.alarmFormatter stringFromDate:alarm.alarmTime];
    cell.alarmRepeatLabel.text = [ANEnumManager stringFromRepeatMode:alarm.alarmRepeatMode];
    [cell.alarmSwitch setOn:alarm.alarmEnabled];
    
    return cell;
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (ANAlarmCell *)cellFromControl:(UIControl *)sender {
    UIView *view = sender;
    while (view && (![view isKindOfClass:[ANAlarmCell class]])) {
        view = view.superview;
    }
    ANAlarmCell *cell = (ANAlarmCell *)view;
    NSAssert([cell isKindOfClass:[ANAlarmCell class]], @"");
    return cell;
}

#pragma mark Data reloading

- (void)reloadData {
    [DejalBezelActivityView activityViewForView:self.view];
    [[ANDataManager sharedManager] alarmsListWithCompletionHandler:^(NSArray *result, NSError *error) {
        self.dataContainer = [result sortedArrayUsingComparator:^NSComparisonResult(ANAlarm *obj1, ANAlarm *obj2) {
            return [obj1.alarmTime compare:obj2.alarmTime];
        }];
        [self.tableView reloadData];
        [DejalBezelActivityView removeViewAnimated:NO];
        [self setupTimeMonitoringTimer];
    }];
}

#pragma mark Time monitoring 

- (void)setupTimeMonitoringTimer {
    [self invalidateTimeMonitoringTimer];
    if (self.isViewLoaded && self.view.window) {
        NSDate *currentDate = [NSDate date];
        NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSTimeZoneCalendarUnit) fromDate:currentDate];
        [components setSecond:0];
        [components setMinute:components.minute + 1];
        NSDate *nextDate = [[NSCalendar currentCalendar] dateFromComponents:components];
        self.timeMonitoringTimer = [NSTimer scheduledTimerWithTimeInterval:[nextDate timeIntervalSinceDate:currentDate] target:self selector:@selector(timeMonitoringTimerFired) userInfo:nil repeats:NO];
    }
}

- (void)timeMonitoringTimerFired {
    if (self.dataContainer) {
        NSMutableArray *alarms = [[NSMutableArray alloc] initWithArray:self.dataContainer];
        NSMutableArray *alarmsToRemove = [NSMutableArray new];
        for (ANAlarm *alarm in alarms) {
            if ([alarm.alarmTime isEarlierThanDate:[NSDate date]]) {
                [alarmsToRemove addObject:alarm];
                if (self.selectedRemoveIndexPath) {
                    if (self.selectedRemoveIndexPath.row == [alarms indexOfObject:alarm]) {
                        if (self.removeAlertView) {
                            [self.removeAlertView dismissWithClickedButtonIndex:self.removeAlertView.cancelButtonIndex animated:NO];
                        }
                    }
                }
            }
        }
        [alarms removeObjectsInArray:alarmsToRemove];
        self.dataContainer = alarms;
        [self.tableView reloadData];
        [self setupTimeMonitoringTimer];
    }
}

- (void)invalidateTimeMonitoringTimer {
    if (self.timeMonitoringTimer) {
        if ([self.timeMonitoringTimer isValid]) {
            [self.timeMonitoringTimer invalidate];
        }
    }
    self.timeMonitoringTimer = nil;
}

#pragma mark View lifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self invalidateTimeMonitoringTimer];
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
