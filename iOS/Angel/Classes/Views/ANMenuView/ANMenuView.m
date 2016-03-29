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


#import "ANMenuView.h"
#import "UIView+additions.h"

static CGFloat itemsPosition;

@interface ANMenuView ()

@property (nonatomic, strong) IBOutletCollection(UIButton) NSArray *itemsCollection;

@property (nonatomic, weak) IBOutlet UIButton *metricsButton;
@property (nonatomic, weak) IBOutlet UIButton *alarmButton;
@property (nonatomic, weak) IBOutlet UIButton *accountButton;
@property (nonatomic, weak) IBOutlet UIButton *playgroundButton;
@property (nonatomic, weak) IBOutlet UIButton *infoButton;

@property BOOL animating;

@end

@implementation ANMenuView

+ (id)sharedMenu {
    static dispatch_once_t onceToken;
    static ANMenuView *instance;
    dispatch_once(&onceToken, ^{
        instance = [UIView loadFromXibNamed:@"ANMenuView"];
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
}

- (void)awakeFromNib {
    [super awakeFromNib];
    itemsPosition = self.metricsButton.frame.origin.x;
    self.selectedItem = ANMenuViewItemMetrics;
}

- (void)setSelectedItem:(ANMenuViewItem)selectedItem {
    _selectedItem = selectedItem;
    
    for (UIButton *item in self.itemsCollection) {
        [item setSelected:NO];
    }
    
    switch (selectedItem) {
        case ANMenuViewItemMetrics: {
            [self.metricsButton setSelected:YES];
        } break;
        case ANMenuViewItemAlarm: {
            [self.alarmButton setSelected:YES];
        } break;
        case ANMenuViewItemAccount: {
            [self.accountButton setSelected:YES];
        } break;
        case ANMenuViewItemPlayground: {
             [self.metricsButton setSelected:YES];
//            [self.playgroundButton setSelected:YES];
        } break;
        case ANMenuViewItemInfo: {
            [self.infoButton setSelected:YES];
        } break;
    }
}

#pragma mark Interface Actions

- (IBAction)metricsButtonPressed:(id)sender {
    [self menuItemPressed:ANMenuViewItemMetrics];
}

- (IBAction)alarmButtonPressed:(id)sender {
    [self menuItemPressed:ANMenuViewItemAlarm];
}

- (IBAction)accountButtonPressed:(id)sender {
    [self menuItemPressed:ANMenuViewItemAccount];
}

- (IBAction)playgroundButtonPressed:(id)sender {
    [self menuItemPressed:ANMenuViewItemPlayground];
    [self menuItemPressed:ANMenuViewItemMetrics];

}

- (IBAction)infoButtonPressed:(id)sender {
    [self menuItemPressed:ANMenuViewItemInfo];
}

- (void)menuItemPressed:(ANMenuViewItem)item {
    if ([self.delegate respondsToSelector:@selector(menuView:menuItemPressed:)]) {
        [self.delegate menuView:self menuItemPressed:item];
    }
}

#pragma mark Appearance handling

- (void)showInView:(UIView *)superview animated:(BOOL)animated appearance:(void(^)(void))appearance completion:(void (^)(void))completion {
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
                
                for (UIButton *item in self.itemsCollection) {
                    item.frame = CGRectMake(- item.frame.size.width * (1.0f + 3.0 * drand48()), item.frame.origin.y, item.frame.size.width, item.frame.size.height);
                }
                
                innerAppearance();
                
                [UIView animateWithDuration:0.5f animations:^{
                    self.alpha = 1.0f;
                    for (UIButton *item in self.itemsCollection) {
                        item.frame = CGRectMake(itemsPosition, item.frame.origin.y, item.frame.size.width, item.frame.size.height);
                    }
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
                self.animating = NO;
                self.visible = NO;
                if (completion) completion();
            };
            
            if (animated) {
                [UIView animateWithDuration:0.5f animations:^{
                    self.alpha = 0.0f;
                    for (UIButton *item in self.itemsCollection) {
                        item.frame = CGRectMake(- item.frame.size.width * (1.0f + 3.0 * drand48()), item.frame.origin.y, item.frame.size.width, item.frame.size.height);
                    }
                } completion:^(BOOL finished) {
                    innerCompletion();
                }];
            } else {
                innerCompletion();
            }
        }
    }
}

@end
