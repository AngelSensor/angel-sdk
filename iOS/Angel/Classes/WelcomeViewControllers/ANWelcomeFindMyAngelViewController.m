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


#import "ANWelcomeFindMyAngelViewController.h"
#import "ANRootNavigationController.h"

typedef enum {
    ViewModeNone,
    ViewModeLetsStart,
    ViewModeLongPress
} ViewMode;

#define kFindMyAngelDelay 3.0f

@interface ANWelcomeFindMyAngelViewController ()

@property (nonatomic, weak) IBOutlet UIButton *findMyAngelButton;
@property (nonatomic, weak) IBOutlet UILabel *letsStartLabel;
@property (nonatomic, weak) IBOutlet UILabel *longPressLabel;

@property (nonatomic) ViewMode viewMode;
@property BOOL animating;

@property (nonatomic, strong) NSTimer *findMyAngelTimer;

@end

@implementation ANWelcomeFindMyAngelViewController

#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.viewMode = ViewModeNone;
        self.animating = NO;
    }
    return self;
}

#pragma mark View mode handling

- (void)setViewMode:(ViewMode)viewMode {
    [self setViewMode:viewMode animated:NO completion:nil];
}

- (void)setViewMode:(ViewMode)viewMode animated:(BOOL)animated completion:(void(^)(void))completion {
    if (viewMode != _viewMode) {
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
                    case ViewModeLetsStart: {
                        
                        self.findMyAngelButton.enabled = NO;
                        self.findMyAngelButton.backgroundColor = UIColorFromRGB(0x75863f);
                        
                        void (^setupTimerBlock)(void) = ^{
                            self.findMyAngelButton.enabled = NO;
                            
                            [self invalidateTimer:self.findMyAngelTimer];
                            self.findMyAngelTimer = [NSTimer scheduledTimerWithTimeInterval:kFindMyAngelDelay target:self selector:@selector(findMyAngelTimerFired) userInfo:nil repeats:NO];
                        };
                        
                        if (_viewMode != ViewModeNone) {
                            self.letsStartLabel.alpha = 0.0f;
                            self.longPressLabel.alpha = 1.0f;
                            
                            self.letsStartLabel.hidden = NO;
                            self.longPressLabel.hidden = NO;
                            
                            innerAnimationBlock = ^{
                                self.letsStartLabel.alpha = 1.0f;
                                self.longPressLabel.alpha = 0.0f;
                            };
                            
                            innerCompletionBlock = ^{
                                self.longPressLabel.hidden = YES;
                                setupTimerBlock();
                                defaultCompletionBlock();
                            };
                        } else {
                            innerCompletionBlock = ^{
                                setupTimerBlock();
                                defaultCompletionBlock();
                            };
                        }
                    } break;
                    case ViewModeLongPress: {
                        self.letsStartLabel.alpha = 1.0f;
                        self.longPressLabel.alpha = 0.0f;
                        
                        self.letsStartLabel.hidden = NO;
                        self.longPressLabel.hidden = NO;
                        
                        innerAnimationBlock = ^{
                            self.letsStartLabel.alpha = 0.0f;
                            self.longPressLabel.alpha = 1.0f;
                        };
                        
                        innerCompletionBlock = ^{
                            self.letsStartLabel.hidden = YES;
                            defaultCompletionBlock();
                        };
                        
                    } break;
                    default: {
                        innerCompletionBlock = defaultCompletionBlock;
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

#pragma mark Move to searching

- (void)moveToSearchScreen {
    [(ANRootNavigationController *)self.navigationController pushViewControllerWithIdentifier:@"welcomeSearchViewController" animated:YES];
}

#pragma mark Interface Actions

- (IBAction)findMyAngelButtonPressed:(id)sender {
//    switch (self.viewMode) {
//        case ViewModeLetsStart: {
//            [self setViewMode:ViewModeLongPress animated:YES completion:nil];
//        } break;
//        case ViewModeLongPress: {
            [self moveToSearchScreen];
//        }
//        default: {
//    
//        } break;
//    }
}

- (void)findMyAngelTimerFired {
    self.findMyAngelButton.enabled = YES;
    self.findMyAngelButton.backgroundColor = UIColorFromRGB(0xeedb1f);
    [self setViewMode:ViewModeLongPress animated:YES completion:nil];
}

- (void)invalidateTimer:(NSTimer *)timer {
    if ([timer isValid]) {
        [timer invalidate];
    }
    timer = nil;
}

#pragma mark View lifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setViewMode:ViewModeLetsStart];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.findMyAngelButton.layer.masksToBounds = YES;
    self.findMyAngelButton.layer.cornerRadius = 3.0f;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc {
    [self invalidateTimer:self.findMyAngelTimer];
}

@end
