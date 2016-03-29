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


#import "ANTempAnimationView.h"

@interface ANTempAnimationView ()

@property (nonatomic, weak) IBOutlet UIImageView *tempUpperView;
@property (nonatomic, weak) IBOutlet UIImageView *tempBottomView;

@property CGRect originalFrame;

@end

@implementation ANTempAnimationView

- (void)awakeFromNib {
    self.originalFrame = self.tempUpperView.frame;
    self.tempUpperView.layer.anchorPoint = CGPointMake(0.5f, 1.0f);
    self.tempUpperView.layer.position = CGPointMake(self.tempUpperView.center.x, self.originalFrame.origin.y + self.originalFrame.size.height);
    [super awakeFromNib];
}

#pragma mark Animation handling

- (void)animationLoop {
    
    CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds.size.height"];
    
    boundsAnimation.duration = self.animationDuration / 2;
    boundsAnimation.repeatCount = 1;
    boundsAnimation.autoreverses = YES;
    boundsAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    boundsAnimation.fromValue = @(self.originalFrame.size.height);
    boundsAnimation.toValue = @(15.0f);
    
    [self.tempUpperView.layer addAnimation:boundsAnimation forKey:[NSString stringWithFormat:@"%@-bounds", kAnimationKey]];
}

@end
