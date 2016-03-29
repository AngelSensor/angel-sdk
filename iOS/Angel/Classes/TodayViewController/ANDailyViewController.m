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


#import "ANDailyViewController.h"
#import "DejalActivityView.h"
#import "ANExpandedView.h"
#import "UIView+additions.h"

@interface ANDailyViewController ()

@property (nonatomic, weak) IBOutlet UIView *containerView;

@property (nonatomic, strong) ANExpandedView *expandedView;

@end

@implementation ANDailyViewController

#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)loadData {
    static BOOL loading = NO;
    @synchronized(self) {
        if (!loading) {
            loading = YES;
            [DejalBezelActivityView activityViewForView:self.view];
            [[ANDataManager sharedManager] dailyDataWithCompletionHandler:^(ANHistoryItem *result) {
                self.historyItem = result;
                [DejalBezelActivityView removeViewAnimated:NO];
                loading = NO;
            }];
        }
    }
}

- (void)setHistoryItem:(ANHistoryItem *)historyItem {
    _historyItem = historyItem;
    self.expandedView.historyItem = historyItem;
}

#pragma mark View lifeCycle

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.expandedView.frame = self.containerView.bounds;
    [self.containerView addSubview:self.expandedView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadData];
    [self.expandedView setTitleInset:[[ANDataManager sharedManager] updateInfo] ? 40.0f : 0.0f];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.expandedView = [UIView loadFromXibNamed:@"ANExpandedView"];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
