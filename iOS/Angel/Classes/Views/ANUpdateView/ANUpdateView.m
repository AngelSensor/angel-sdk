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


#import "ANUpdateView.h"
#import "UIView+additions.h"

@interface ANUpdateView () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIView *containerView;

@property (nonatomic, weak) IBOutlet UIView *readyToUpdateView;
@property (nonatomic, weak) IBOutlet UILabel *readyToUpdateLabel;
@property (nonatomic, weak) IBOutlet UIButton *updateButton;

@property (nonatomic, weak) IBOutlet UIView *updatingView;

@property (nonatomic, weak) IBOutlet UIView *updatingTopContainer;
@property (nonatomic, weak) IBOutlet UIView *updatingMiddleContainer;
@property (nonatomic, weak) IBOutlet UIView *updatingBottomContainer;

@property (nonatomic, weak) IBOutlet UIScrollView *updatingScrollView;
@property (nonatomic, weak) IBOutlet UILabel *updatingLabel;
@property (nonatomic, weak) IBOutlet UILabel *updatingProgressLabel;
@property (nonatomic, weak) IBOutlet UILabel *updatingMarkLabel;
@property (nonatomic, weak) IBOutlet UILabel *updatingWhatsNewLabel;

@property (nonatomic, weak) IBOutlet UIView *updatingDoNotTouchContainer;
@property (nonatomic, weak) IBOutlet UIView *updatingPleaseWaitContainer;

@property (nonatomic, weak) IBOutletCollection(UIButton) NSArray *promoNewApps;

@property BOOL animating;

@end

@implementation ANUpdateView

+ (id)sharedView {
    static dispatch_once_t onceToken;
    static ANUpdateView *instance;
    dispatch_once(&onceToken, ^{
        instance = [UIView loadFromXibNamed:@"ANUpdateView"];
    });
    return instance;
}

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
    self.animating = NO;
    self.visible = NO;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeView)];
    [tap setCancelsTouchesInView:NO];
    [tap setDelegate:self];
    [self addGestureRecognizer:tap];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.updateButton.layer.masksToBounds = YES;
    self.updateButton.layer.cornerRadius = 3.0f;
    
    self.updatingMarkLabel.layer.masksToBounds = YES;
    self.updatingMarkLabel.layer.cornerRadius = self.updatingMarkLabel.frame.size.width / 2;
}

#pragma mark Tap handling

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return ![touch.view isKindOfClass:[UIControl class]];
}

- (void)closeView {
    if (self.viewMode == ViewModeReadyToUpdate) {
        [self.delegate updateViewShouldClose:self];
    }
}

#pragma mark Interface actions

- (IBAction)updateButtonPressed:(id)sender {
    [self.delegate updateViewUpdateButtonPressed:self];
}

- (IBAction)newAppPressed:(UIButton *)sender {
    NSString *stringURL = [[[self.updateInfo objectForKey:kNewApps] objectAtIndex:sender.tag] objectForKey:kAppURL];
    if (stringURL) {
        NSURL *url = [NSURL URLWithString:stringURL];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

#pragma mark Appearance handling

- (void)showInView:(UIView *)superview animated:(BOOL)animated appearance:(void(^)(void))appearance completion:(void (^)(void))completion {
    [self setViewMode:ViewModeReadyToUpdate];
    @synchronized(self) {
        if (!self.animating) {
            self.animating = YES;
            [self setFrame:superview.bounds];
            
            void (^innerAppearance)(void) = ^{
                [superview addSubview:self];
                if (appearance) {
                    appearance();
                }
            };
            
            void (^innerCompletion)(void) = ^{
                self.animating = NO;
                self.visible = YES;
                if (completion) completion();
            };
            
            if (animated) {
                self.alpha = 0.0f;
                
                innerAppearance();
                
                [UIView animateWithDuration:0.5f animations:^{
                    self.alpha = 1.0f;
                } completion:^(BOOL finished) {
                    innerCompletion();
                }];
            } else {
                self.alpha = 1.0f;
                innerAppearance();
                innerCompletion();
            }
        }
    }
}

- (void)hide:(BOOL)animated completion:(void(^)(void))completion {
    @synchronized(self) {
        if (!self.animating) {
            self.animating = YES;
            void (^innerCompletion)(void) = ^{
                [self removeFromSuperview];
                _viewMode = ViewModeNone;
                self.animating = NO;
                self.visible = NO;
                if (completion) completion();
            };
            
            if (animated) {
                [UIView animateWithDuration:0.5f animations:^{
                    self.alpha = 0.0f;
                } completion:^(BOOL finished) {
                    innerCompletion();
                }];
            } else {
                innerCompletion();
            }
        }
        else if (completion) {
            completion();
        }
    }
}

#pragma mark View type handling

- (void)setViewMode:(ViewMode)viewMode {
    [self setViewMode:viewMode animated:NO completion:nil];
}

- (void)setViewMode:(ViewMode)viewMode animated:(BOOL)animated completion:(void(^)(void))completion {
    if (self.viewMode != viewMode) {
        @synchronized(self) {
            if (!self.animating) {
                self.animating = YES;
                
                void (^innerAnimationBlock)(void);
                void (^innerCompletionBlock)(void);
                
                void (^defaultCompletionBlock)(void) = ^{
                    self.animating = NO;
                    _viewMode = viewMode;
                    if (completion) completion();
                };
                
                switch (viewMode) {
                    case ViewModeReadyToUpdate: {
                        self.readyToUpdateView.alpha = 0.0f;
                        self.readyToUpdateView.hidden = NO;
                        
                        self.readyToUpdateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ is ready for download", nil), [self.updateInfo objectForKey:kName]];
                        
                        innerAnimationBlock = ^{
                            self.readyToUpdateView.alpha = 1.0f;
                            self.updatingView.alpha = 0.0f;
                            
                            [self.containerView setFrame:CGRectMake(self.containerView.frame.origin.x, self.containerView.frame.origin.y, self.readyToUpdateView.frame.size.width, self.readyToUpdateView.frame.size.height)];
                        };
                        
                        innerCompletionBlock = ^{
                            self.updatingView.hidden = YES;
                            defaultCompletionBlock();
                        };
                    } break;
                    case ViewModeDownloading: {
                        self.updatingProgressLabel.text = nil;
                        self.updatingLabel.text = NSLocalizedString(@"Downloading update", nil);
                        self.updatingWhatsNewLabel.text = [self.updateInfo objectForKey:kWhatsNew];
                        [self.updatingWhatsNewLabel sizeToFit];
                        
                        self.updatingMiddleContainer.frame = CGRectMake(self.updatingMiddleContainer.frame.origin.x, self.updatingMiddleContainer.frame.origin.y, self.updatingMiddleContainer.frame.size.width, self.updatingWhatsNewLabel.frame.origin.y + self.updatingWhatsNewLabel.frame.size.height);
                        self.updatingBottomContainer.frame = CGRectMake(self.updatingBottomContainer.frame.origin.x, self.updatingMiddleContainer.frame.origin.y + self.updatingMiddleContainer.frame.size.height, self.updatingBottomContainer.frame.size.width, self.updatingBottomContainer.frame.size.height);
                        
                        self.updatingScrollView.contentSize = CGSizeMake(self.updatingBottomContainer.frame.size.width, self.updatingBottomContainer.frame.origin.y + self.updatingBottomContainer.frame.size.height);
                        
                        for (UIButton *newApp in self.promoNewApps) {
                            [newApp setImage:[UIImage imageNamed:[[[self.updateInfo objectForKey:kNewApps] objectAtIndex:newApp.tag] objectForKey:kAppIconURL]] forState:UIControlStateNormal];
                        }
                        
                        if (self.updatingView.hidden) {
                            self.updatingView.alpha = 0.0f;
                            self.updatingView.hidden = NO;
                        }
                        
                        if (self.updatingDoNotTouchContainer.hidden) {
                            self.updatingDoNotTouchContainer.alpha = 0.0f;
                            self.updatingDoNotTouchContainer.hidden = NO;
                        }
                        
                        if (self.updatingBottomContainer.hidden) {
                            self.updatingBottomContainer.alpha = 0.0f;
                            self.updatingBottomContainer.hidden = NO;
                        }
                        
                        if (self.updatingMiddleContainer.hidden) {
                            self.updatingMiddleContainer.alpha = 0.0f;
                            self.updatingMiddleContainer.hidden = NO;
                        }
                        
                        innerAnimationBlock = ^{
                            self.updatingView.alpha = 1.0f;
                            self.readyToUpdateView.alpha = 0.0f;
                            
                            self.updatingDoNotTouchContainer.alpha = 1.0f;
                            self.updatingPleaseWaitContainer.alpha = 0.0f;
                            
                            self.updatingBottomContainer.alpha = 1.0f;
                            self.updatingMiddleContainer.alpha = 1.0f;
                            
                            [self.containerView setFrame:CGRectMake(self.containerView.frame.origin.x, self.containerView.frame.origin.y, self.updatingView.frame.size.width, self.updatingView.frame.size.height)];
                        };
                        
                        innerCompletionBlock = ^{
                            self.readyToUpdateView.hidden = YES;
                            self.updatingPleaseWaitContainer.hidden = YES;
                            defaultCompletionBlock();
                        };
                    } break;
                    case ViewModeUpdating: {
                        self.updatingLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Updating %@", nil), [self.updateInfo objectForKey:kName]];
                        self.updatingProgressLabel.text = nil;
                        innerCompletionBlock = ^{
                            defaultCompletionBlock();
                        };
                    } break;
                    case ViewModeUpdated: {
                        
                        if (self.updatingView.hidden) {
                            self.updatingView.alpha = 0.0f;
                            self.updatingView.hidden = NO;
                        }
                        
                        self.updatingPleaseWaitContainer.alpha = 0.0f;
                        self.updatingPleaseWaitContainer.hidden = NO;
                        
                        self.updatingLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ is now updated", nil), [self.updateInfo objectForKey:kName]];
                        
                        self.updatingScrollView.contentSize = self.updatingTopContainer.frame.size;
                        
                        innerAnimationBlock = ^{
                            
                            self.updatingView.alpha = 1.0f;
                            self.readyToUpdateView.alpha = 0.0f;
                            
                            self.updatingDoNotTouchContainer.alpha = 0.0f;
                            self.updatingPleaseWaitContainer.alpha = 1.0f;
                            
                            self.updatingBottomContainer.alpha = 0.0f;
                            self.updatingMiddleContainer.alpha = 0.0f;
                        };
                        
                        innerCompletionBlock = ^{
                            self.readyToUpdateView.hidden = YES;
                            self.updatingBottomContainer.hidden = YES;
                            self.updatingMiddleContainer.hidden = YES;
                            self.updatingDoNotTouchContainer.hidden = YES;
                            
                            defaultCompletionBlock();
                        };
                    } break;
                    default: {
                    } break;
                }
                
                if (animated) {
                    [UIView animateWithDuration:0.5f animations:^{
                        if (innerAnimationBlock) innerAnimationBlock();
                    } completion:^(BOOL finished) {
                        if (innerCompletionBlock) innerCompletionBlock();
                    }];
                } else {
                    if (innerAnimationBlock) innerAnimationBlock();
                    if (innerCompletionBlock) innerCompletionBlock();
                }
            }
        }
    }
}

#pragma mark Update handling

- (void)setUpdateInfo:(NSDictionary *)updateInfo {
    _updateInfo = updateInfo;
}

- (void)setProgress:(NSNumber *)progress {
    self.updatingProgressLabel.text = [NSString stringWithFormat:@"%d%%", progress.intValue];
}

@end
