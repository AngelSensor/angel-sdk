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


#import "ANGraphView.h"

#pragma mark GraphItem implementation

@interface ANGraphItem ()

@property CGPoint point;

@end

@implementation ANGraphItem

@end

@implementation ANRangePath

+ (ANRangePath *)rangePathForRange:(NSInteger)range index:(NSInteger)index {
    if (range > -1 && index > -1) {
        ANRangePath *instance = [[ANRangePath alloc] init];
        instance.range = range;
        instance.index = index;
        return instance;
    }
    return nil;
}

@end

#pragma mark GraphView implementation

@interface ANGraphView ()

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@property (nonatomic, strong) NSArray *dataContainer;

@property (nonatomic, strong) UIColor *lineColor;
@property CGFloat lineWidth;

@property (nonatomic, strong) UIColor *dotColor;
@property CGFloat dotRadius;

@property CAShapeLayer *graphLayer;
@property CAShapeLayer *dotLayer;

@end

@implementation ANGraphView

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
    [self setBackgroundColor:[UIColor clearColor]];
    
    self.dotPoint = CGPointZero;
}

#pragma mark Data reloading

- (void)reloadData {
    
    [self.dotLayer removeFromSuperlayer];
    [self.graphLayer removeFromSuperlayer];
    
    self.dotLayer = nil;
    self.graphLayer = nil;
    
    NSMutableArray *mutableGraphData = [NSMutableArray array];
    
    NSInteger numberOfRanges = [self.dataSource numberOfRangesInGraphView:self];
    
    for (NSInteger range = 0; range < numberOfRanges; range++) {
        NSInteger numberOfItems = [self.dataSource graphView:self numberOfItemsInRange:range];
        NSMutableArray *rangeItems = [NSMutableArray new];
        for (NSInteger index = 0; index < numberOfItems; index++) {
            ANGraphItem *graphItem = [self.dataSource graphView:self graphItemAtRangePath:[ANRangePath rangePathForRange:range index:index]];
            [rangeItems addObject:graphItem];
        }
        [mutableGraphData addObject:rangeItems];
    }
    
    self.startDate = [self.dataSource startDateForGraphView:self];
    self.endDate = [self.dataSource endDateForGraphView:self];
    
    if ([self.dataSource respondsToSelector:@selector(colorForLineInGraphView:)]) {
        self.lineColor = [self.dataSource colorForLineInGraphView:self];
    } else {
        self.lineColor = [UIColor blackColor];
    }
    
    if ([self.dataSource respondsToSelector:@selector(colorForDotInGraphView:)]) {
        self.dotColor = [self.dataSource colorForDotInGraphView:self];
    } else {
        self.dotColor = [UIColor blackColor];
    }
    
    if ([self.dataSource respondsToSelector:@selector(radiusForDotInGraphView:)]) {
        self.dotRadius = [self.dataSource radiusForDotInGraphView:self];
    } else {
        self.dotRadius = 2.0f / [UIScreen mainScreen].scale;
    }
    
    if ([self.dataSource respondsToSelector:@selector(widthForLineInGraphView:)]) {
        self.lineWidth = [self.dataSource widthForLineInGraphView:self];
    } else {
        self.lineWidth = 1.0f / [UIScreen mainScreen].scale;
    }
    
    self.dataContainer = mutableGraphData;
    [self calculatePointsForItems:self.dataContainer];
    
    [self setNeedsDisplay];
    
}

- (void)calculatePointsForItems:(NSArray *)items {
    double minValue = MAXFLOAT;
    double maxValue = 0;
    
    for (NSArray *range in self.dataContainer) {
        
        for (ANGraphItem *graphItem in range) {
            if (graphItem.value.doubleValue < minValue) {
                minValue = graphItem.value.doubleValue;
            }
            if (graphItem.value.doubleValue > maxValue) {
                maxValue = graphItem.value.doubleValue;
            }
        }
    }
    NSTimeInterval graphInterval = [self.endDate timeIntervalSinceDate:self.startDate];
    
    for (NSArray *range in self.dataContainer) {
        for (ANGraphItem *graphItem in range) {
            CGFloat x = ceil(([graphItem.date timeIntervalSinceDate:self.startDate]) / graphInterval * self.frame.size.width);
            CGFloat y;
            if (minValue == maxValue) {
                y = self.frame.size.height / 2;
            } else {
                y = self.frame.size.height - ceil((graphItem.value.doubleValue - minValue) / (maxValue - minValue) * self.frame.size.height);
            }
            
            graphItem.point = CGPointMake(x, y);
        }
    }
    
}

- (ANRangePath *)showDotAtLocation:(CGFloat)x {
    NSInteger index = -1;
    NSInteger range = -1;
    CGFloat y = [self calculatePointFromX:x range:&range index:&index];
    if (y >= 0) {
        self.dotPoint = CGPointMake(x, y);
    } else {
        self.dotPoint = CGPointZero;
    }
    [self setNeedsDisplay];
    return [ANRangePath rangePathForRange:range index:index];
}

- (CGFloat)calculatePointFromX:(CGFloat)x range:(NSInteger *)range index:(NSInteger *)index {
    ANGraphItem *v1;
    ANGraphItem *v2;
    
    float x1;
    float x2;
    float y1;
    float y2;
    
    for (NSInteger currentRange = 0; currentRange < self.dataContainer.count; currentRange++) {
        NSArray *rangeArray = [self.dataContainer objectAtIndex:currentRange];
        if (rangeArray.count > 1) {
            for (NSInteger currentIndex  = 0; currentIndex < rangeArray.count - 1; currentIndex++) {
                v1 = [rangeArray objectAtIndex:currentIndex];
                v2 = [rangeArray objectAtIndex:currentIndex + 1];
                
                if(fabs(x - [v1 point].x) < 0.5) {
                    *index = currentIndex;
                    *range = currentRange;
                    return [v1 point].y;
                }
                if(fabs(x - [v2 point].x) < 0.5) {
                    *index = currentIndex;
                    *range = currentRange;
                    return [v2 point].y;
                }
                
                if((x > [v1 point].x) && (x < [v2 point].x)) {
                    x1 = [v1 point].x;
                    x2 = [v2 point].x;
                    y1 = [v1 point].y;
                    y2 = [v2 point].y;
                    *index = currentIndex;
                    *range = currentRange;
                    return (x - x1) / (x2 - x1) * (y2 - y1) + y1;
                }
            }
        } else {
            v1 = rangeArray.firstObject;
            if(fabs(x - [v1 point].x) < 0.5) {
                *index = 0;
                *range = currentRange;
                return [v1 point].y;
            }
        }
    }
    *index = -1;
    *range = -1;
    return -1;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (!self.graphLayer) {
        
        CAShapeLayer *shapesContainerLayer = [CAShapeLayer layer];
        
        for (NSArray *range in self.dataContainer) {
            NSUInteger index = 0;
            
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.strokeColor = self.lineColor.CGColor;
            shapeLayer.fillColor = [UIColor clearColor].CGColor;
            shapeLayer.lineCap = kCALineCapButt;
            shapeLayer.lineJoin = kCALineJoinMiter;
            shapeLayer.lineWidth = self.lineWidth;
            
            UIBezierPath *path = [UIBezierPath bezierPath];
            
            if (range.count > 1) {
                shapeLayer.frame = self.bounds;
                for (ANGraphItem *graphItem in range) {
                    if (index == 0) {
                        [path moveToPoint:graphItem.point];
                    } else {
                        [path addLineToPoint:graphItem.point];
                    }
                    index++;
                }
            } else {
                shapeLayer.position = [(ANGraphItem *)range.firstObject point];
                [path addArcWithCenter:CGPointZero radius:self.dotRadius startAngle:0.0 endAngle:M_PI * 2.0 clockwise:YES];;
            }
            
            shapeLayer.path = path.CGPath;
            shapeLayer.anchorPoint = CGPointMake(0.5f, 0.5f);
            
            [shapesContainerLayer addSublayer:shapeLayer];
        }
    
        self.graphLayer = shapesContainerLayer;
        
        [self.layer addSublayer:shapesContainerLayer];
    } else {
        [self.layer addSublayer:self.graphLayer];
    }
    
    if (!CGPointEqualToPoint(CGPointZero, self.dotPoint)) {
        if (!self.dotLayer) {
            CAShapeLayer *circle = [CAShapeLayer layer];
            
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path addArcWithCenter:CGPointZero radius:self.dotRadius startAngle:0.0 endAngle:M_PI * 2.0 clockwise:YES];
            
            circle.path = path.CGPath;
            circle.position = self.dotPoint;
            
            CGColorRef color = self.dotColor.CGColor;
            circle.fillColor = color;
            circle.strokeColor = color;
            circle.lineWidth = 1;
            circle.anchorPoint = CGPointMake(0.5f, 0.5f);
            
            self.dotLayer = circle;
            
            [self.layer addSublayer:circle];
        } else {
            [CATransaction begin];
            [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
            self.dotLayer.position = self.dotPoint;
            [CATransaction commit];
            [self.layer addSublayer:self.dotLayer];
        }
    } else {
        [self.dotLayer removeFromSuperlayer];
    }
}

@end
