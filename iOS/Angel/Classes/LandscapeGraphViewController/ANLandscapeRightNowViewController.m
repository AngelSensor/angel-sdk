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


#import "ANLandscapeRightNowViewController.h"
#import "ANGraphView.h"
#import "NSDate+Utilities.h"
#import "ANConnectionManager.h"

#define DEFAULT_TIME_STEP D_MINUTE

typedef enum {
    ANGraphViewTypeOpticalWaveform1,
    ANGraphViewTypeOpticalWaveform2,
    ANGraphViewTypeAccelerometer,
    numberOfGraphs
} ANGraphViewType;

#define kGraphMargin 5.0f
#define kIntervalStep 3 * D_HOUR
#define kScrollTimerInterval 1.0f

@interface ANLandscapeRightNowViewController () <ANGraphViewDataSource>

@property (nonatomic, weak) IBOutlet UIView *containerView;

@property (nonatomic, strong) NSMutableArray *graphsContainer;
@property (nonatomic, strong) NSMutableArray *separatorsContainer;

@property (nonatomic, strong) ANHistoryItem *historyItem;

@end

@implementation ANLandscapeRightNowViewController

- (void)createGraphViews {
    
    self.graphsContainer = [NSMutableArray new];
    self.separatorsContainer = [NSMutableArray new];
    
    void (^createSeparatorView)(CGFloat y) = ^(CGFloat y) {
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, self.containerView.frame.origin.y + y, self.view.frame.size.width, 1.0 / [UIScreen mainScreen].scale)];
        [separator setUserInteractionEnabled:NO];
        [separator setBackgroundColor:UIColorFromRGB(0xd2d7ce)];
        
        [self.view addSubview:separator];
        
        [self.separatorsContainer addObject:separator];
    };
    
    for (NSInteger graphType = ANGraphViewTypeOpticalWaveform1; graphType < numberOfGraphs; graphType++) {
        
        ANGraphView *graph = [[ANGraphView alloc] initWithFrame:CGRectIntegral(CGRectMake(0, self.containerView.frame.size.height / numberOfGraphs * graphType + kGraphMargin, self.containerView.frame.size.width, self.containerView.frame.size.height / numberOfGraphs - 2 * kGraphMargin))];
        [graph setGraphType:(ANGraphViewType)graphType];
        [graph setDataSource:self];
        [graph reloadData];
        
        [self.containerView addSubview:graph];
        [self.graphsContainer addObject:graph];
        
        createSeparatorView(self.containerView.frame.size.height / numberOfGraphs * graphType);
    }
    
    createSeparatorView(self.containerView.frame.size.height - 1);
}

- (void)layoutGraphViews {
    for (NSInteger graphType = ANGraphViewTypeOpticalWaveform1; graphType < numberOfGraphs; graphType++) {
        [[self.graphsContainer objectAtIndex:graphType] setFrame:CGRectIntegral(CGRectMake(0, self.containerView.frame.size.height / numberOfGraphs * graphType + kGraphMargin, self.containerView.frame.size.width, self.containerView.frame.size.height / numberOfGraphs - 2 * kGraphMargin))];
        [[self.separatorsContainer objectAtIndex:graphType] setFrame:CGRectMake(0, self.containerView.frame.origin.y + self.containerView.frame.size.height / numberOfGraphs * graphType, self.containerView.frame.size.width, 1.0 / [UIScreen mainScreen].scale)];
    }
}

- (ANHistoryRecordType)recordTypeForGraphType:(ANGraphViewType)graphType {
    switch (graphType) {
        case ANGraphViewTypeOpticalWaveform1: {
            return ANHistoryRecordTypeOpticalWaveform1;
        } break;
        case ANGraphViewTypeOpticalWaveform2: {
            return ANHistoryRecordTypeOpticalWaveform2;
        } break;
        case ANGraphViewTypeAccelerometer: {
            return ANHistoryRecordTypeAccelerometer;
        } break;
        default: {
            return ANHistoryRecordTypeNone;
        } break;
    }
}

#pragma mark ANGraphView dataSource

- (NSInteger)numberOfRangesInGraphView:(ANGraphView *)graphView {
    return [[self.historyItem.rangeItems objectForKey:@([self recordTypeForGraphType:(ANGraphViewType)graphView.graphType])] count];
}

- (NSInteger)graphView:(ANGraphView *)graphView numberOfItemsInRange:(NSInteger)range {
    NSArray *ranges = [self.historyItem.rangeItems objectForKey:@([self recordTypeForGraphType:(ANGraphViewType)graphView.graphType])];
    return [[ranges objectAtIndex:range] count];
}

- (ANGraphItem *)graphView:(ANGraphView *)graphView graphItemAtRangePath:(ANRangePath *)rangePath {
    ANHistoryRecord *historyRecord = [[[self.historyItem.rangeItems objectForKey:@([self recordTypeForGraphType:(ANGraphViewType)graphView.graphType])] objectAtIndex:rangePath.range] objectAtIndex:rangePath.index];
    ANGraphItem *graphItem = [ANGraphItem new];
    graphItem.value = historyRecord.recordValue;
    graphItem.date = historyRecord.recordTimestamp;
    return graphItem;
}

- (NSDate *)startDateForGraphView:(ANGraphView *)graphView {
    return [self.historyItem startDateForType:[self recordTypeForGraphType:(ANGraphViewType)graphView.graphType]];
}

- (NSDate *)endDateForGraphView:(ANGraphView *)graphView {
    return [self.historyItem endDateForType:[self recordTypeForGraphType:(ANGraphViewType)graphView.graphType]];
}

- (CGFloat)widthForLineInGraphView:(ANGraphView *)graphView {
    return 1.0 / [UIScreen mainScreen].scale;
}

- (CGFloat)radiusForDotInGraphView:(ANGraphView *)graphView {
    return 1.5 / [UIScreen mainScreen].scale;
}

- (UIColor *)colorForDotInGraphView:(ANGraphView *)graphView {
    switch (graphView.graphType) {
        case ANHistoryRecordTypeOpticalWaveform1: {
            return UIColorFromRGB(0x518cff);
        } break;
        case ANHistoryRecordTypeOpticalWaveform2: {
            return UIColorFromRGB(0xccb0003);
        } break;
        case ANGraphViewTypeAccelerometer: {
            return UIColorFromRGB(0xf7a300);
        } break;
        default: {
            return [UIColor whiteColor];
        } break;
    }
}

- (UIColor *)colorForLineInGraphView:(ANGraphView *)graphView {
    switch (graphView.graphType) {
        case ANHistoryRecordTypeOpticalWaveform1: {
            return UIColorFromRGB(0x518cff);
        } break;
        case ANHistoryRecordTypeOpticalWaveform2: {
            return UIColorFromRGB(0xcb0003);
        } break;
        case ANGraphViewTypeAccelerometer: {
            return UIColorFromRGB(0xf7a300);
        } break;
        default: {
            return [UIColor whiteColor];
        } break;
    }
    
}

#pragma mark Data loading

- (void)loadData {
    self.historyItem = [[ANHistoryItem alloc] init];
    [[ANDataManager sharedManager] waveformDataWithOpticalHandler:^(NSArray *opticalResults, NSError *error) {
        if (opticalResults.count > 0 && !error) {
            for (NSInteger type = ANGraphViewTypeOpticalWaveform1; type <= ANGraphViewTypeOpticalWaveform2; type++) {
                [self.historyItem removeItemsForType:[self recordTypeForGraphType:(ANGraphViewType)type]];
                NSDate *currentDate = [NSDate date];
                for (ANHistoryRecord *record in [opticalResults objectAtIndex:type]) {
                    record.recordTimestamp = currentDate;
                    [self.historyItem addRecord:record];
                    currentDate = [currentDate dateByAddingTimeInterval:DEFAULT_TIME_STEP];
                }
                [[self.graphsContainer objectAtIndex:type] reloadData];
            }
        }
    } accelerometerHandler:^(NSArray *accelerometerResult, NSError *error) {
        if (accelerometerResult.count > 0 && !error) {
            [self.historyItem removeItemsForType:ANHistoryRecordTypeAccelerometer];
            NSDate *currentDate = [NSDate date];
            for (ANHistoryRecord *record in accelerometerResult) {
                record.recordTimestamp = currentDate;
                [self.historyItem addRecord:record];
                currentDate = [currentDate dateByAddingTimeInterval:DEFAULT_TIME_STEP];
            }
            [[self.graphsContainer objectAtIndex:ANGraphViewTypeAccelerometer] reloadData];
        }
    }];
}

- (void)stopReloadingData {
    [[ANDataManager sharedManager] stopRefreshingWaveform];
    [[[ANDataManager sharedManager] currentWristband] enabledWaveformSignalService:NO];
}

#pragma mark View lifeCycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[ANDataManager sharedManager] setIsLandscapeMode:YES];
    [[[ANDataManager sharedManager] currentWristband] enabledWaveformSignalService:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone];
    [self loadData];
    
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone];
    [self stopReloadingData];
    [[ANDataManager sharedManager] setIsLandscapeMode:NO];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutGraphViews];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createGraphViews];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
