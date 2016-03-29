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


#import "ANTableViewItem.h"

const CGFloat kItemAnimationDuration = 0.3f;

@interface ANTableViewItem ()

@property (nonatomic) BOOL rasterizeSubviews;

@end

@implementation ANTableViewItem

#pragma mark Initialization

- (id)initItemWithType:(ANTableViewItemType)itemType closedView:(UIView *)closedView openedView:(UIView *)openedView {
    if (itemType == ANTableViewItemTypeClosed) {
        self = [super initWithFrame:closedView.frame];
    } else {
        self = [super initWithFrame:openedView.frame];
    }
    if (self) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        
        self.itemType = itemType;
        
        self.closedHeight = closedView.frame.size.height;
        self.openedHeight = openedView.frame.size.height;
        
        self.closedView = closedView;
        self.openedView = openedView;
        
        if (itemType == ANTableViewItemTypeClosed) {
            if ((openedView.autoresizingMask & UIViewAutoresizingFlexibleHeight) != 0) {
                openedView.frame = self.frame;
            }
            [self changeHeight:self.closedHeight];
            self.currentView = closedView;
        } else {
            if ((closedView.autoresizingMask & UIViewAutoresizingFlexibleHeight) != 0) {
                closedView.frame = self.frame;
            }
            [self changeHeight:self.openedHeight];
            self.currentView = openedView;
        }
    }
    return self;
}

#pragma mark Frame handling

- (CGFloat)currentHeight {
    return self.frame.size.height;
}

- (void)setCurrentHeight:(CGFloat)height {
    self.frame = CGRectIntegral(CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height));
}

- (void)setClosedView:(UIView *)closedView {
    [_closedView removeFromSuperview];
    _closedView = closedView;
    [self addSubview:_closedView];
}

- (void)setOpenedView:(UIView *)openedView {
    [_openedView removeFromSuperview];
    _openedView = openedView;
    [self addSubview:_openedView];
}

- (void)setRasterizeSubviews:(BOOL)rasterizeSubviews {
    if (_rasterizeSubviews != rasterizeSubviews) {
        self.closedView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.openedView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        
        self.closedView.layer.shouldRasterize = rasterizeSubviews;
        self.openedView.layer.shouldRasterize = rasterizeSubviews;
        
    }
    _rasterizeSubviews = rasterizeSubviews;
}

- (void)changeHeight:(CGFloat)height {
    CGFloat newHeight = MIN(self.openedHeight, MAX(height, self.closedHeight));
    
    BOOL isTransitionState = height != self.closedHeight && height != self.openedHeight;
    self.rasterizeSubviews = isTransitionState;
    
    self.currentHeight = ceil(newHeight);
    
    self.closedView.alpha = [self calculateAlphaForItemType:ANTableViewItemTypeClosed];
    self.openedView.alpha = [self calculateAlphaForItemType:ANTableViewItemTypeOpened];
}

#pragma mark Animation

- (void)openItemAnimated:(BOOL)animated completion:(void (^)(void))completion {
    [self handleAnimationForItemType:ANTableViewItemTypeOpened animated:animated completion:completion];
}

- (void)closeItemAnimated:(BOOL)animated completion:(void (^)(void))completion {
    [self handleAnimationForItemType:ANTableViewItemTypeClosed animated:animated completion:completion];
}

- (void)handleAnimationForItemType:(ANTableViewItemType)itemType animated:(BOOL)animated completion:(void (^)(void))completion {
    self.rasterizeSubviews = YES;
    
    void (^blockOpenAnimation)(void) = ^(void) {
        if (itemType == ANTableViewItemTypeOpened) {
            self.currentHeight = self.openedHeight;
            self.closedView.alpha = 0.f;
            self.openedView.alpha = 1.f;
        } else {
            self.currentHeight = self.closedHeight;
            self.closedView.alpha = 1.f;
            self.openedView.alpha = 0.f;
        }
    };
    
    void (^blockInternalCompletion)() = ^{
        self.rasterizeSubviews = NO;
        if (itemType == ANTableViewItemTypeOpened) {
            self.currentView = self.openedView;
        } else {
            self.currentView = self.closedView;
        }
            
        if (completion != nil) {
            completion();
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:kItemAnimationDuration animations:blockOpenAnimation completion:^(BOOL finished) {
            if (blockInternalCompletion) {
                blockInternalCompletion();
            }
        }];
    }
    else {
        blockOpenAnimation();
        blockInternalCompletion();
    }
}

#pragma mark Alpha calculations

- (CGFloat)calculateAlphaForItemType:(ANTableViewItemType)itemType {
    CGFloat diffViewsHeight = self.openedHeight - self.closedHeight;
    CGFloat diffCurrentHeight = self.frame.size.height - self.closedHeight;
    
    CGFloat heightTransitionMin;
    CGFloat heightTransitionMax;
    
    if (self.currentView == self.closedView) {
        heightTransitionMin = diffViewsHeight * 0.f;
        heightTransitionMax = diffViewsHeight * 0.3f;
    }
    else {
        heightTransitionMin = diffViewsHeight * 0.6f;
        heightTransitionMax = diffViewsHeight * 0.85f;
    }
    
    CGFloat alpha;
    
    if (itemType == ANTableViewItemTypeClosed) {
        alpha = MAX(0.f, MIN(1.f - (diffCurrentHeight - heightTransitionMin) / (heightTransitionMax - heightTransitionMin), 1.f));
    } else {
        alpha = MAX(0.f, MIN((diffCurrentHeight - heightTransitionMin) / (heightTransitionMax - heightTransitionMin), 1.f));
    }
    return alpha;
}

@end
