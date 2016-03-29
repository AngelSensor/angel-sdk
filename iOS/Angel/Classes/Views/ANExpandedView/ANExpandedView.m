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


#import "ANExpandedView.h"
#import "ANGraphContainerView.h"
#import "ANGraphView.h"
#import "ANTableView.h"
#import "NSDate+Utilities.h"

@interface ANExpandedView () <ANGraphContainerViewDelegate>

@property CGRect titleFrame;

@end

@implementation ANExpandedView

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
    
}

- (void)setShouldShowLabels:(BOOL)shouldShowLabels {
    [self.graphContainerView setShouldShowLabels:shouldShowLabels];
}

- (void)setTitleInset:(CGFloat)inset {
    CGRect frame = self.titleFrame;
    frame.origin.x += inset;
    frame.size.width -= inset;
    [self.titleLabel setFrame:frame];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.titleFrame = self.titleLabel.frame;
    self.graphContainerView.delegate = self;
}

- (void)setHistoryItem:(ANHistoryItem *)historyItem {
    _historyItem = historyItem;
    
    ANDataManager *dMgr = [ANDataManager sharedManager];
    
    self.titleLabel.text = [dMgr.mdFormatter stringFromDate:historyItem.startDate];
    self.stepsLabel.text = [dMgr.numberFormatter stringFromNumber:historyItem.stepsNumber];
    self.energyLabel.text = [dMgr.numberFormatter stringFromNumber:historyItem.energyNumber];
    
    self.prevMonthLabel.text = [dMgr.mdFormatter stringFromDate:[historyItem.startDate dateYesterday]];
    self.nextMonthLabel.text = [dMgr.mdFormatter stringFromDate:[historyItem.endDate dateTomorrow]];

    self.graphContainerView.historyItem = historyItem;
}

#pragma mark Graph Container delegate

- (void)graphContainerView:(ANGraphContainerView *)graphContainer touchBeganOrMovedOnItems:(NSArray *)items touchEnabled:(BOOL)enabled {
    
    static NSString *noDataString = @"no\r\ndata";
    
    if (items.count == 4) {
        ANHistoryRecord *heartItem = [items objectAtIndex:0];
        ANHistoryRecord *oxygenItem = [items objectAtIndex:1];
        ANHistoryRecord *tempItem = [items objectAtIndex:2];
        ANHistoryRecord *stepsItem = [items objectAtIndex:3];
        
        if (![heartItem isKindOfClass:[NSNull class]]) {
            self.heartLabel.text = [NSString stringWithFormat:@"%0.1f", heartItem.recordValue.floatValue];
        } else {
            self.heartLabel.text = noDataString;
        }
        
        if (![oxygenItem isKindOfClass:[NSNull class]]) {
            self.oxygenLabel.text = [NSString stringWithFormat:@"%0.1f", oxygenItem.recordValue.floatValue];
        } else {
            self.oxygenLabel.text = noDataString;
        }
        
        if (![tempItem isKindOfClass:[NSNull class]]) {
            self.temperatureLabel.text = [NSString stringWithFormat:@"%0.1f", tempItem.recordValue.floatValue];
        } else {
            self.temperatureLabel.text = noDataString;
        }
        
        if (![stepsItem isKindOfClass:[NSNull class]]) {
            self.otherLabel.text = [NSString stringWithFormat:@"%0.1f", stepsItem.recordValue.floatValue];
        } else {
            self.otherLabel.text = noDataString;
        }
            
    }
    
    [self.tableView setScrollEnabled:enabled];
}

- (void)graphContainerViewTouchEndedOrCancelled:(ANGraphContainerView *)graphContainer {
    [self.tableView setScrollEnabled:YES];
}

@end
