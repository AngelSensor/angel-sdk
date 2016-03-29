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


#import "ANGaugeView.h"

@interface ANGaugeView () <UIScrollViewDelegate>

@property GaugeViewType viewType;

@property NSInteger minValue;
@property NSInteger maxValue;

@property CGSize shortLineSize;
@property CGSize longLineSize;

@property NSInteger shortLineHeight;
@property NSInteger longLineHeight;

@property UIColor *longLineColor;
@property UIColor *shortLineColor;

@property NSInteger lineStep;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *containerView;

@end

@implementation ANGaugeView

#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    self.step = GaugeStepDefault;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    
    self.scrollView.backgroundColor = [UIColor clearColor];
    
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    self.containerView.backgroundColor = [UIColor clearColor];
    
    self.centerPoint = self.frame.size.width / 2;
    
    [self.scrollView addSubview:self.containerView];
    [self addSubview:self.scrollView];
}

#pragma mark Data reloading

- (void)reloadData {
    
    self.viewType = [self.dataSource typeForGaugeView:self];
    
    if ([self.dataSource respondsToSelector:@selector(minValueForGaugeView:)]) {
        self.minValue = [self.dataSource minValueForGaugeView:self];
    } else {
        self.minValue = 0;
    }
    
    if ([self.dataSource respondsToSelector:@selector(maxValueForGaugeView:)]) {
        self.maxValue = [self.dataSource maxValueForGaugeView:self];
    } else {
        self.maxValue = 100;
    }
    
    if ([self.dataSource respondsToSelector:@selector(shortLineSizeForGaugeView:)]) {
        self.shortLineSize = [self.dataSource shortLineSizeForGaugeView:self];
    } else {
        if (self.viewType == GaugeViewTypeHorizontal) {
            self.shortLineSize = CGSizeMake(1.0f / [UIScreen mainScreen].scale, self.frame.size.height * 0.4f);
        } else {
            self.shortLineSize = CGSizeMake(self.frame.size.width / 3, 1.0f / [UIScreen mainScreen].scale);
        }
    }
    
    if ([self.dataSource respondsToSelector:@selector(longLineSizeForGaugeView:)]) {
        self.longLineSize = [self.dataSource longLineSizeForGaugeView:self];
    } else {
        if (self.viewType == GaugeViewTypeHorizontal) {
            self.longLineSize = CGSizeMake(1.0f / [UIScreen mainScreen].scale, self.frame.size.height * 0.7f);
        } else {
            self.longLineSize = CGSizeMake(self.frame.size.width / 3 * 2, 1.0f / [UIScreen mainScreen].scale);
        }
    }
    
    if ([self.dataSource respondsToSelector:@selector(lineStepForGaugeView:)]) {
        self.lineStep = [self.dataSource lineStepForGaugeView:self];
    } else {
        self.lineStep = 6;
    }
    
    if ([self.dataSource respondsToSelector:@selector(longLineColorForGaugeView:)]) {
        self.longLineColor = [self.dataSource longLineColorForGaugeView:self];
    } else {
        self.longLineColor = [UIColor whiteColor];
    }
    
    if ([self.dataSource respondsToSelector:@selector(shortLineColorForGaugeView:)]) {
        self.shortLineColor = [self.dataSource shortLineColorForGaugeView:self];
    } else {
        self.shortLineColor = [UIColor whiteColor];
    }
    
    __block NSInteger currentPosition = 0;
    
    void (^addOffsetToCurrentPosition)(void) = ^{
        if (self.viewType == GaugeViewTypeHorizontal) {
            currentPosition += self.scrollView.frame.size.width / 2;
        } else {
            currentPosition += self.scrollView.frame.size.height/ 2;
        }
    };
    
    addOffsetToCurrentPosition();
    
    [self.containerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.containerView.frame = self.scrollView.bounds;
    
    for (NSInteger i = self.minValue; i <= self.maxValue; i++) {
        
        void (^addLine)(CGSize size, UIColor *color) = ^(CGSize size, UIColor *color){
            UIView *line = [[UIView alloc] initWithFrame:CGRectZero];
            
            if (self.viewType == GaugeViewTypeHorizontal) {
                [line setFrame:CGRectMake(currentPosition, self.longLineSize.height - size.height, size.width, size.height)];
            } else {
                [line setFrame:CGRectMake(self.scrollView.frame.size.width - size.width, currentPosition, size.width, size.height)];
            }

            line.backgroundColor = color;
            
            [self.containerView addSubview:line];
        };
        
        void (^addLabel)(NSInteger value) = ^(NSInteger value){
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.font = [UIFont fontWithName:@"Asap-Regular" size:14.0f];
            if (self.step == GaugeStepDefault) {
                label.text = [NSString stringWithFormat:@"%ld", (long)value];
            } else {
                label.text = [NSString stringWithFormat:@"%d'%d\"", (int)value / GaugeStepInches, (int)value % GaugeStepInches];
            }
            label.textAlignment = NSTextAlignmentCenter;
            [label sizeToFit];
            
            if (self.viewType == GaugeViewTypeHorizontal) {
                [label setFrame:CGRectMake(currentPosition - label.frame.size.width / 2, self.longLineSize.height, label.frame.size.width, self.scrollView.frame.size.height - self.longLineSize.height)];
            } else {
                [label setFrame:CGRectMake(self.scrollView.frame.size.width - self.longLineSize.width, currentPosition, self.scrollView.frame.size.width - self.longLineSize.width, label.frame.size.height)];
            }
            
            label.textColor = self.longLineColor;
            label.backgroundColor = [UIColor clearColor];
            
            [self.containerView addSubview:label];
        };
        
        if ((i == self.minValue) || (i == self.maxValue) || (i % self.step == 0)) {
            addLine(self.longLineSize, self.longLineColor);
            addLabel(i);
        } else {
            addLine(self.shortLineSize, self.shortLineColor);
        }
        
        if (i != self.maxValue) {
            currentPosition += self.lineStep;
        }
    }
    
    addOffsetToCurrentPosition();
    
    if (self.viewType == GaugeViewTypeHorizontal) {
        [self.containerView setFrame:CGRectMake(0, 0, currentPosition, self.scrollView.frame.size.height)];
    } else {
        [self.containerView setFrame:CGRectMake(0, 0, self.scrollView.frame.size.width, currentPosition)];
    }
    
    [self.scrollView setContentSize:self.containerView.frame.size];
    
}

- (void)setCurrentValue:(NSInteger)currentValue {
    if (currentValue >= self.minValue && currentValue <= self.maxValue) {
        _currentValue = currentValue;
    } else if (currentValue < self.minValue) {
        _currentValue = self.minValue;
    } else {
        _currentValue = self.maxValue;
    }
    [self.scrollView setContentOffset:[self offsetForValue:_currentValue] animated:YES];
}

- (CGPoint)offsetForValue:(NSInteger)value {
    
    NSInteger contentSize = 0;
    
    if (self.viewType == GaugeViewTypeHorizontal) {
        contentSize = self.scrollView.contentSize.width - self.scrollView.frame.size.width;
    } else {
        contentSize = self.scrollView.contentSize.height - self.scrollView.frame.size.height;
    }
    
    NSInteger offset = ((double)(value - self.minValue)) / (double)(self.maxValue - self.minValue) * (double)contentSize;
    
    CGPoint contentOffset = CGPointZero;
    
    if (self.viewType == GaugeViewTypeHorizontal) {
        contentOffset = CGPointMake(offset, 0);
    } else {
        contentOffset = CGPointMake(0, offset);
    }
    
    return contentOffset;
}

- (NSInteger)valueForOffset:(CGPoint)offset {
    NSInteger contentOffset = 0;
    NSInteger contentSize = 0;
    
    if (self.viewType == GaugeViewTypeHorizontal) {
        contentOffset = offset.x;
        contentSize = self.scrollView.contentSize.width - self.scrollView.frame.size.width;
    } else {
        contentOffset = offset.y;
        contentSize = self.scrollView.contentSize.height - self.scrollView.frame.size.height;
    }
    
    if (contentOffset >= 0 && contentOffset <= contentSize) {
        return (self.minValue + ((double)(self.maxValue - self.minValue)) / ((double)contentSize) * contentOffset);
    } else {
        return NSNotFound;
    }
}

#pragma mark UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSInteger value = [self valueForOffset:self.scrollView.contentOffset];
    if (value != NSNotFound) {
        _currentValue = value;
        [self.delegate gaugeView:self valueChanged:self.currentValue];
    }
}

@end
