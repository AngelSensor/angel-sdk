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


#import <UIKit/UIKit.h>
#import "NSDate+Utilities.h"
#import "ANGraphView.h"
#import "ANHistoryItem.h"
#import "ANSliderView.h"

@class ANGraphContainerView;

@protocol ANGraphContainerViewDelegate <NSObject>

- (void)graphContainerView:(ANGraphContainerView *)graphContainer touchBeganOrMovedOnItems:(NSArray *)items touchEnabled:(BOOL)enabled;
- (void)graphContainerViewTouchEndedOrCancelled:(ANGraphContainerView *)graphContainer;

@end

@interface ANGraphContainerView : UIView <ANGraphViewDataSource, ANGraphViewDelegate, ANSliderViewDelegate>

@property (nonatomic, weak) id <ANGraphContainerViewDelegate>delegate;

@property (nonatomic, strong) ANHistoryItem *historyItem;

@property (nonatomic) CGPoint currentSlidePoint;

@property BOOL shouldShowLabels;
@property BOOL empty;

- (void)commonInit;
- (void)handleTouchPoint:(CGPoint)point touchEnabled:(BOOL)enabled;
- (void)reloadGraphs;

@end
