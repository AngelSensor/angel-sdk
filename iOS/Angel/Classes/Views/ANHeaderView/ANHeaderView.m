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


#import "ANHeaderView.h"
#import "NSObject+MTKObserving.h"

#define kAnimationDuration 0.5f

@interface ANHeaderView ()

@property (nonatomic, weak) IBOutlet UIButton *menuButton;
@property (nonatomic, weak) IBOutlet UIButton *backButton;

@property (nonatomic, weak) IBOutlet UIImageView *signalView;
@property (nonatomic, weak) IBOutlet UIImageView *batteryView;
@property (weak, nonatomic) IBOutlet UIImageView *iconMenu;

@property (nonatomic, weak) ANDataManager *dataManager;

@end

@implementation ANHeaderView

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
    self.dataManager = [ANDataManager sharedManager];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.updateButton.layer.cornerRadius = self.updateButton.frame.size.width / 2;
    self.updateButton.layer.masksToBounds = YES;
    
    [self setupObservations];
}

- (void)setHeaderMode:(HeaderMode)headerMode {
    if (_headerMode != headerMode) {
        _headerMode = headerMode;
        self.menuButton.hidden = YES;
        self.backButton.hidden = YES;
        self.iconMenu.hidden = YES;
        switch (headerMode) {
            case HeaderModeBack: {
                self.backButton.hidden = NO;
            } break;
            case HeaderModeMenu: {
                self.menuButton.hidden = NO;
            } break;
            case HeaderModeIcon:
            {
                self.iconMenu.hidden = NO;
            } break;
            default: {
                
            } break;
        }
    }
}

- (void)showUpdateButtonWithText:(NSString *)text animated:(BOOL)animated {
    if (self.updateButton.hidden) {
        void (^innerAnimationBlock)(void) = ^{
            [self.updateButton setAlpha:1.0f];
        };
        
        [self.updateButton setTitle:text forState:UIControlStateNormal];
        [self.updateButton setAlpha:0.0f];
        [self.updateButton setHidden:NO];
        
        if (animated) {
            [UIView animateWithDuration:kAnimationDuration animations:^{
                innerAnimationBlock();
            } completion:^(BOOL finished) {
                [self scheduleHeartbeatAnimation];
            }];
        } else {
            innerAnimationBlock();
            [self scheduleHeartbeatAnimation];
        }
    }
}

- (void)hideUpdateButtonAnimated:(BOOL)animated {
    if (!self.updateButton.hidden) {
        void (^innerAnimationBlock)(void) = ^{
            [self.updateButton setAlpha:0.0f];
        };
        
        void (^innerCompletionBlock)(void) = ^{
            [self.updateButton setHidden:YES];
        };
        
        [self.updateButton setAlpha:1.0f];
        [self.updateButton setHidden:NO];
        
        [self stopHeartbeatAnimation];
        
        if (animated) {
            [UIView animateWithDuration:kAnimationDuration animations:^{
                innerAnimationBlock();
            } completion:^(BOOL finished) {
                innerCompletionBlock();
            }];
        } else {
            innerAnimationBlock();
            innerCompletionBlock();
        }
    }
}

#pragma mark Animation

- (void)scheduleHeartbeatAnimation {
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.duration = 10.0f;
    animationGroup.repeatCount = INFINITY;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    
    animation.duration = 0.5f;
    animation.repeatCount = 1;
    animation.autoreverses = YES;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.fromValue = [NSNumber numberWithFloat:1.0f];
    animation.toValue = [NSNumber numberWithFloat:0.8f];
    
    animationGroup.animations = @[animation];
    
    [self.updateButton.layer addAnimation:animationGroup forKey:@"heartbeat"];
}

- (void)stopHeartbeatAnimation {
    [self.updateButton.layer removeAllAnimations];
}

#pragma mark Interface actions

- (IBAction)menuButtonPressed:(id)sender {
    [self.delegate menuButtonPressedOnHeaderView:self];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.delegate backButtonPressedOnHeaderView:self];
}

- (IBAction)updateButtonPressed:(id)sender {
    [self.delegate updateButtonPressedOnHeaderView:self];
}

#pragma mark Pass touches through

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL pointInside = NO;
    
    if (CGRectContainsPoint(self.menuButton.frame, point) || CGRectContainsPoint(self.backButton.frame, point) || (!self.updateButton.hidden && CGRectContainsPoint(self.updateButton.frame, point))) {
        pointInside = YES;
    }
    
    return pointInside;
}

#pragma mark Observations

- (void)setupObservations {
    
    [self removeAllObservations];
    
    __weak typeof(self) wself = self;
    
    void (^updateSignalStrength)(NSInteger strength) = ^(NSInteger strength) {
        [wself.signalView setImage:[wself imageForSignalStrength:strength]];
        [wself.signalLabel setText:[NSString stringWithFormat:@"%lddb", (long)strength]];
    };
    
    void (^updateBatteryStatus)(NSInteger status) = ^(NSInteger status) {
        [wself.batteryView setImage:[wself imageForBatteryLevel:status]];
        [wself.batteryLabel setText:[NSString stringWithFormat:@"%ld%%", (long)status]];
    };
    
    [self observeProperty:@"dataManager.batteryStatus" withBlock:^(__weak typeof(self) self, NSNumber *oldValue, NSNumber *newValue) {
        if (oldValue && newValue) {
            updateBatteryStatus(newValue.intValue);
        }
    }];
    
    [self observeProperty:@"dataManager.signalStrength" withBlock:^(__weak typeof(self) self, NSNumber *oldValue, NSNumber *newValue) {
        if (oldValue && newValue) {
            updateSignalStrength(newValue.intValue);
        }
    }];
}

- (UIImage *)imageForSignalStrength:(NSInteger)strength {
    
    NSString *imageName = @"";
    if (strength > -70) {
        imageName = @"icn_reception_4";
    }
    else if (strength > -80) {
        imageName = @"icn_reception_3";
    }
    else if (strength > -85) {
        imageName = @"icn_reception_2";
    }
    else if (strength > -87) {
        imageName = @"icn_reception_1";
    }
    else {
        imageName = @"icn_reception_0";
    }
    
    return [UIImage imageNamed:imageName];
}

- (UIImage *)imageForBatteryLevel:(NSInteger)level {
    if (level <= 0) {
        return [UIImage imageNamed:@"icn_battery_0"];
    } else if (level > 0 && level <= 25) {
        return [UIImage imageNamed:@"icn_battery_1"];
    } else if (level > 25 && level <= 50) {
        return [UIImage imageNamed:@"icn_battery_2"];
    } else if (level > 50 && level <= 75) {
        return [UIImage imageNamed:@"icn_battery_3"];
    } else if (level > 75) {
        return [UIImage imageNamed:@"icn_battery_4"];
    }
    return nil;
}

- (void)dealloc {
    [self removeAllObservations];
}

@end
