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


#import "ANSliderView.h"
#import "UIView+additions.h"

@interface ANSliderView ()

@property (nonatomic, weak) IBOutlet UIImageView *slideItemView;

@property (nonatomic, strong) NSTimer *slideTimer;

@end

@implementation ANSliderView

- (void)touchBeganOrMoved:(CGPoint)origin {
    CGPoint modifiedOrigin = origin;
    if (origin.x < 0) {
        modifiedOrigin.x = 0;
    } else if (origin.x > self.frame.size.width) {
        modifiedOrigin.x = self.frame.size.width;
    }
    [self.delegate sliderView:self touchBeganOrMoved:modifiedOrigin];
}

- (void)touchEndedOrCancelled:(CGPoint)origin {
    [self.delegate sliderView:self touchEndedOrCancelled:origin];
}

#pragma mark Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchBeganOrMoved:[[touches anyObject] locationInView:self]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint location = [[touches anyObject] locationInView:self];
    [self touchBeganOrMoved:location];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchEndedOrCancelled:[[touches anyObject] locationInView:self]];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchEndedOrCancelled:[[touches anyObject] locationInView:self]];
}

- (void)setSlideItemCenterX:(CGFloat)x {
    [self.slideItemView setCenter:CGPointMake(x, self.slideItemView.center.y)];
}

@end
