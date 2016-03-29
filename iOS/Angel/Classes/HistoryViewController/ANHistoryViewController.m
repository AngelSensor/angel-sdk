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


#import "ANHistoryViewController.h"
#import "ANMetricsViewController.h"
#import "DejalActivityView.h"
#import "ANTableView.h"
#import "ANTableViewItem.h"
#import "UIView+additions.h"
#import "ANHistoryCell.h"
#import "ANCollapsedView.h"

#import "ANHistoryItem.h"

@interface ANHistoryViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *historyDataContainer;

@end

@implementation ANHistoryViewController

#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)reloadData {
    [DejalBezelActivityView activityViewForView:self.view];
    [[ANDataManager sharedManager] historyDataWithCompletionHandler:^(NSArray *result) {
        if (result) {
            self.historyDataContainer = result;
            [self.tableView reloadData];
        }
        [DejalBezelActivityView removeViewAnimated:NO];
    }];
}

#pragma mark UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.historyDataContainer.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ANHistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    ANHistoryItem *historyItem = [self.historyDataContainer objectAtIndex:indexPath.row];
    
    ANDataManager *dMgr = [ANDataManager sharedManager];
    
    cell.titleLabel.text = [dMgr.mdFormatter stringFromDate:historyItem.startDate];
    cell.stepsLabel.text = [dMgr.numberFormatter stringFromNumber:historyItem.stepsNumber];
    cell.energyLabel.text =[dMgr.numberFormatter stringFromNumber:historyItem.energyNumber];
    
    cell.minHeartLabel.text = [NSString stringWithFormat:@"↑ %@", historyItem.minHeartNumber ? [dMgr.numberFormatter stringFromNumber:historyItem.minHeartNumber] : @"no data"];
    cell.maxHeartLabel.text = [NSString stringWithFormat:@"↓ %@", historyItem.maxHeartNumber ? [dMgr.numberFormatter stringFromNumber:historyItem.maxHeartNumber] : @"no data"];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    ANMetricsViewController *metrics = (ANMetricsViewController *)self.parentViewController;
    [metrics presentDailyWithItem:[self.historyDataContainer objectAtIndex:indexPath.row]];
}

#pragma mark View lifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self reloadData];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
