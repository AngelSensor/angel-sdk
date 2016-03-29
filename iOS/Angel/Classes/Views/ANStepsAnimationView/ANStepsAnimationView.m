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


#import "ANStepsAnimationView.h"

@interface ANStepsAnimationView ()

@property (nonatomic, weak) IBOutlet UIImageView *leftStepsView;
@property (nonatomic, weak) IBOutlet UIImageView *rightStepsView;

@end

@implementation ANStepsAnimationView

#pragma mark Animation handling

- (void)animationLoop {
    
    CABasicAnimation *leftAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    
    leftAnimation.duration = self.animationDuration / 2;
    leftAnimation.repeatCount = 1;
    leftAnimation.autoreverses = YES;
    leftAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    leftAnimation.fromValue = [NSNumber numberWithFloat:1.0f];
    leftAnimation.toValue = [NSNumber numberWithFloat:0.0f];
    
    [self.leftStepsView.layer addAnimation:leftAnimation forKey:[NSString stringWithFormat:@"%@-left", kAnimationKey]];
    
    CABasicAnimation *rightAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    
    rightAnimation.duration = self.animationDuration / 2;
    rightAnimation.repeatCount = 1;
    rightAnimation.autoreverses = YES;
    rightAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    rightAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    rightAnimation.toValue = [NSNumber numberWithFloat:1.0f];
    
    [self.rightStepsView.layer addAnimation:rightAnimation forKey:[NSString stringWithFormat:@"%@-right", kAnimationKey]];
}

@end
