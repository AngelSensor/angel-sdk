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


#import "ANGraphContainerView.h"
#import "ANGraphView.h"
#import "UIView+additions.h"
#import "NSDate+Utilities.h"

typedef enum {
    ANGraphViewTypeHeart,
    ANGraphViewTypeOxygen,
    ANGraphViewTypeTemp,
    ANGraphViewTypeSteps,
    numberOfGraphs
} ANGraphViewType;

#define kGraphMargin 5.0f
#define kIntervalStep 3 * D_HOUR
#define kScrollTimerInterval 1.0f

@interface ANGraphContainerView () <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet ANSliderView *sliderView;

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *containerView;

@property (nonatomic, weak) IBOutlet UIView *selectionView;
@property (nonatomic, weak) IBOutlet UIButton *selectionTime;

@property (nonatomic, weak) IBOutlet UIView *headerView;

@property (nonatomic, strong) NSMutableArray *graphsContainer;
@property (nonatomic, strong) NSMutableArray *separatorsContainer;
@property (nonatomic, strong) NSMutableDictionary *labelsContainer;

@property (nonatomic, strong) NSTimer *scrollTimer;

@end

@implementation ANGraphContainerView

#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.shouldShowLabels = NO;
    self.labelsContainer = [NSMutableDictionary new];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.scrollView setContentSize:self.containerView.frame.size];
    
    self.graphsContainer = [NSMutableArray new];
    self.separatorsContainer = [NSMutableArray new];
    
    void (^createSeparatorView)(CGFloat y) = ^(CGFloat y) {
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, self.scrollView.frame.origin.y + self.containerView.frame.origin.y + y, self.scrollView.frame.size.width, 1.0 / [UIScreen mainScreen].scale)];
        [separator setUserInteractionEnabled:NO];
        [separator setBackgroundColor:UIColorFromRGB(0xd2d7ce)];
        
        [self insertSubview:separator belowSubview:self.sliderView];
        
        [self.separatorsContainer addObject:separator];
    };
    
    for (NSInteger graphType = 0; graphType < numberOfGraphs; graphType++) {
        
        ANGraphView *graph = [[ANGraphView alloc] initWithFrame:CGRectIntegral(CGRectMake(0, self.containerView.frame.size.height / numberOfGraphs * graphType + kGraphMargin, self.containerView.frame.size.width, self.containerView.frame.size.height / numberOfGraphs - 2 * kGraphMargin))];
        [graph setGraphType:(ANGraphViewType)graphType];
        [graph setDelegate:self];
        [graph setDataSource:self];
        [graph reloadData];
        
        [self.containerView addSubview:graph];
        [self.graphsContainer addObject:graph];
        
        createSeparatorView(self.containerView.frame.size.height / numberOfGraphs * graphType);
    }
    
    createSeparatorView(self.containerView.frame.size.height - 1);
    
    [self.selectionView setWidth:1.0 / [UIScreen mainScreen].scale];
    [self.selectionTime setCenterX:self.selectionView.frame.origin.x + 0.7 * [UIScreen mainScreen].scale];
    self.sliderView.delegate = self;
    
    [self setCurrentSlidePoint:self.selectionView.frame.origin animated:NO];
}

- (void)setHistoryItem:(ANHistoryItem *)historyItem {
    _historyItem = historyItem;
    
    [self.headerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSDate *begin = [historyItem.startDate dateAtStartOfDay];
    NSDate *end = [historyItem.endDate dateAtEndOfDay];
    
    NSDate *current = begin;
    
    NSInteger numberOfHeaders = ceil((double)[end timeIntervalSinceDate:begin] / ((double)kIntervalStep));
    
    CGFloat xMargin = 5.0f;
    CGFloat xOffset = 0.0f;
    
    for (NSInteger header = 0; header <= numberOfHeaders; header++) {
        
        NSDate *date = current;
        
        if (header == 0) {
            date = [current dateByAddingMinutes:1];
        } else if (header == numberOfHeaders) {
            date = [current dateBySubtractingMinutes:1];
        }
        
        UILabel *label = [[UILabel alloc] init];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setFont:[UIFont fontWithName:@"Asap-Regular" size:7]];
        [label setText:[[[ANDataManager sharedManager] hmaFormatter] stringFromDate:date]];
        [label sizeToFit];
        
        CGFloat x = xOffset - label.frame.size.width / 2;
    
        if (header == 0) {
            x = xMargin;
        }
        
        if (x + label.frame.size.width / 2 >= self.headerView.frame.size.width) {
            x = self.headerView.frame.size.width - label.frame.size.width - xMargin;
        }
        
        [label setOrigin:CGPointMake(x, (self.headerView.frame.size.height - label.frame.size.height) / 2)];
        
        [self.headerView addSubview:label];
        
        xOffset += self.headerView.frame.size.width / (numberOfHeaders);
        
        current = [current dateByAddingTimeInterval:kIntervalStep];
    }
    
    [self reloadGraphs];
    
    [self handleTouchPoint:self.currentSlidePoint touchEnabled:YES];
}

- (void)reloadGraphs {
    for (ANGraphView *graphView in self.graphsContainer) {
        [graphView reloadData];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.scrollView setContentSize:self.containerView.frame.size];
    for (NSInteger graphType = 0; graphType < numberOfGraphs; graphType++) {
        [[self.graphsContainer objectAtIndex:graphType] setFrame:CGRectIntegral(CGRectMake(0, self.containerView.frame.size.height / numberOfGraphs * graphType + kGraphMargin, self.containerView.frame.size.width, self.containerView.frame.size.height / numberOfGraphs - 2 * kGraphMargin))];
        [[self.separatorsContainer objectAtIndex:graphType] setFrame:CGRectMake(0, self.scrollView.frame.origin.y + self.containerView.frame.origin.y + self.containerView.frame.size.height / numberOfGraphs * graphType, self.scrollView.frame.size.width, 1.0 / [UIScreen mainScreen].scale)];
    }
}

- (NSDate *)dateForXOffset:(CGFloat)xOffset {
    NSDate *begin = [self.historyItem.startDate dateAtStartOfDay];
    NSDate *end = [self.historyItem.endDate dateAtEndOfDay];
    
    NSTimeInterval interval = [end timeIntervalSinceDate:begin];
    NSTimeInterval offsetInterval = ceil(xOffset / self.containerView.frame.size.width * interval);
    
    return [begin dateByAddingTimeInterval:offsetInterval];
}

- (CGFloat)xOffsetForDate:(NSDate *)date {
    NSDate *begin = [self.historyItem.startDate dateAtStartOfDay];
    NSDate *end = [self.historyItem.endDate dateAtEndOfDay];
    
    NSTimeInterval interval = [end timeIntervalSinceDate:begin];
    NSTimeInterval offsetInterval = [date timeIntervalSinceDate:begin];
    
    return self.containerView.frame.size.width / interval * offsetInterval;

}

- (void)setCurrentSlidePoint:(CGPoint)currentSlidePoint {
    [self setCurrentSlidePoint:currentSlidePoint animated:YES];
    
}

- (void)setCurrentSlidePoint:(CGPoint)currentSlidePoint animated:(BOOL)animated {
    _currentSlidePoint = currentSlidePoint;
    [self handleTouchPoint:currentSlidePoint touchEnabled:NO];
    void (^innerAnimationBlock)(void) = ^{
        [self.selectionView setX:currentSlidePoint.x];
        [self.selectionTime setCenterX:currentSlidePoint.x + 0.7 * [UIScreen mainScreen].scale];
        [self.sliderView setSlideItemCenterX:currentSlidePoint.x];
    };
    
    if (animated) {
        [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
            innerAnimationBlock();
        } completion:nil];
    } else {
        innerAnimationBlock();
    }
}

- (void)showNonEmptySectionAnimated:(BOOL)animated {
    CGPoint offset = CGPointZero;
    
    NSDate *currentDate = [self dateForXOffset:self.scrollView.contentOffset.x + self.currentSlidePoint.x];
    
    NSTimeInterval minInterval = NSTimeIntervalSince1970;
    
    for (NSArray *rangeItems in self.historyItem.rangeItems.allValues) {
        for (NSArray *recordItems in rangeItems) {
            BOOL intervalChanged = NO;
            for (ANHistoryRecord *recordItem in recordItems) {
                if ([recordItem.recordTimestamp isLaterOrEqualThanDate:currentDate]) {
                    NSTimeInterval currentInterval = [recordItem.recordTimestamp timeIntervalSinceDate:currentDate];
                    if (minInterval > currentInterval) {
                        minInterval = currentInterval;
                        CGFloat xOffset = ceil([self xOffsetForDate:recordItem.recordTimestamp] - self.currentSlidePoint.x);
                        if (xOffset + self.scrollView.frame.size.width > self.scrollView.contentSize.width) {
                            xOffset = self.scrollView.contentSize.width - self.scrollView.frame.size.width;
                            [self setCurrentSlidePoint:CGPointMake(ceil([self xOffsetForDate:recordItem.recordTimestamp]) - xOffset, self.currentSlidePoint.y) animated:animated];
                            //[self handleTouchPoint:self.currentSlidePoint touchEnabled:NO];
                        }
                        offset = CGPointMake(xOffset, 0);
                        intervalChanged = YES;
                    }
                    break;
                }
            }
            if (intervalChanged) {
                break;
            }
        }
    }
    if (!CGPointEqualToPoint(offset, CGPointZero)) {
        [self.scrollView setContentOffset:offset animated:animated];
    }
}

- (ANHistoryRecordType)recordTypeForGraphType:(ANGraphViewType)graphType {
    switch (graphType) {
        case ANGraphViewTypeHeart: {
            return ANHistoryRecordTypeHeartRate;
        } break;
        case ANGraphViewTypeOxygen: {
            return ANHistoryRecordTypeOxygen;
        } break;
        case ANGraphViewTypeSteps: {
            return ANHistoryRecordTypeSteps;
        } break;
        case ANGraphViewTypeTemp: {
            return ANHistoryRecordTypeTemperature;
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
    return self.historyItem.startDate;
}

- (NSDate *)endDateForGraphView:(ANGraphView *)graphView {
    return self.historyItem.endDate;
}

- (CGFloat)widthForLineInGraphView:(ANGraphView *)graphView {
    return 1.0 / [UIScreen mainScreen].scale;
}

- (CGFloat)radiusForDotInGraphView:(ANGraphView *)graphView {
    return 1.5 / [UIScreen mainScreen].scale;
}

- (UIColor *)colorForDotInGraphView:(ANGraphView *)graphView {
    switch (graphView.graphType) {
        case ANGraphViewTypeHeart: {
            return UIColorFromRGB(0x518cff);
        } break;
        case ANGraphViewTypeOxygen: {
            return UIColorFromRGB(0xccb0003);
        } break;
        case ANGraphViewTypeTemp: {
            return UIColorFromRGB(0xf7a300);
        } break;
        case ANGraphViewTypeSteps: {
            return UIColorFromRGB(0x71cf00);
        } break;
        default: {
            return [UIColor whiteColor];
        } break;
    }
}

- (UIColor *)colorForLineInGraphView:(ANGraphView *)graphView {
    switch (graphView.graphType) {
        case ANGraphViewTypeHeart: {
            return UIColorFromRGB(0x518cff);
        } break;
        case ANGraphViewTypeOxygen: {
            return UIColorFromRGB(0xcb0003);
        } break;
        case ANGraphViewTypeTemp: {
            return UIColorFromRGB(0xf7a300);
        } break;
        case ANGraphViewTypeSteps: {
            return UIColorFromRGB(0x71cf00);
        } break;
        default: {
            return [UIColor whiteColor];
        } break;
    }
    
}

#pragma mark ANGraphView delegate

#pragma mark Touched items handling

- (NSArray *)touchedItemsAtPoint:(CGPoint)point {
    NSMutableArray *items = [NSMutableArray new];
    self.empty = YES;
    for (ANGraphView *graphView in self.graphsContainer) {
        ANRangePath *rangePath = [graphView showDotAtLocation:self.scrollView.contentOffset.x + point.x];
        if (rangePath) {
            [items addObject:[[[self.historyItem.rangeItems objectForKey:@([self recordTypeForGraphType:(ANGraphViewType)graphView.graphType])] objectAtIndex:rangePath.range] objectAtIndex:rangePath.index]];
            self.empty = NO;
        } else {
            [items addObject:[NSNull null]];
        }
    }
    return items;
}

#pragma mark Slider delegate

- (void)sliderView:(ANSliderView *)sliderView touchBeganOrMoved:(CGPoint)origin {
    [self setCurrentSlidePoint:origin animated:NO];
    [self invalidateScrollTimer];
}

- (void)sliderView:(ANSliderView *)sliderView touchEndedOrCancelled:(CGPoint)origin {
    [self.delegate graphContainerViewTouchEndedOrCancelled:self];
    [self handleEmptyData];
}

#pragma mark ScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self handleTouchPoint:self.currentSlidePoint touchEnabled:NO];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self handleEmptyData];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self handleEmptyData];
}

- (void)handleEmptyData {
    [self invalidateScrollTimer];
    if (self.empty) {
        self.scrollTimer = [NSTimer scheduledTimerWithTimeInterval:kScrollTimerInterval target:self selector:@selector(scrollTimerFired) userInfo:nil repeats:NO];
    }
}

#pragma mark Scroll timer handling

- (void)scrollTimerFired {
    [self showNonEmptySectionAnimated:YES];
}

- (void)invalidateScrollTimer {
    if (self.scrollTimer) {
        [self.scrollTimer invalidate];
    }
    self.scrollTimer = nil;
}

#pragma mark Touch handling

- (void)handleTouchPoint:(CGPoint)point touchEnabled:(BOOL)enabled {
    NSArray *items = [self touchedItemsAtPoint:point];
    
    [self.selectionTime setTitle:[[[ANDataManager sharedManager] hmaFormatter] stringFromDate:[self dateForXOffset:self.scrollView.contentOffset.x + point.x]] forState:UIControlStateNormal];
    [self.delegate graphContainerView:self touchBeganOrMovedOnItems:items touchEnabled:enabled];
    
    if (self.shouldShowLabels) {
        for (ANGraphView *graph in self.graphsContainer) {
            UILabel *label = [self labelForGraph:graph];
            [label setCenter:CGPointMake(graph.dotPoint.x, graph.frame.origin.y + graph.dotPoint.y)];
            ANHistoryRecord *recordItem = (ANHistoryRecord *)[items objectAtIndex:[self.graphsContainer indexOfObject:graph]];
            if (recordItem && ![recordItem isKindOfClass:[NSNull class]]) {
                [label setText:[NSString stringWithFormat:@"%0.2f", recordItem.recordValue.doubleValue]];
                if (!label.superview) {
                    [self.containerView addSubview:label];
                }
            } else {
                [label removeFromSuperview];
            }
        }
    } else {
        [self.labelsContainer removeAllObjects];
    }
}

- (UILabel *)labelForGraph:(ANGraphView *)graph {
    if (![self.labelsContainer objectForKey:@(graph.graphType)]) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 12)];
        [label setBackgroundColor:[self colorForDotInGraphView:graph]];
        [label setFont:[UIFont fontWithName:@"Asap-Bold" size:8]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setTextColor:[UIColor whiteColor]];
        [label setMinimumScaleFactor:0.5f];
        label.layer.cornerRadius = label.frame.size.height / 2;
        label.layer.masksToBounds = YES;
        [self.labelsContainer setObject:label forKey:@(graph.graphType)];
        return label;
    } else {
        return [self.labelsContainer objectForKey:@(graph.graphType)];
    }
}

@end
