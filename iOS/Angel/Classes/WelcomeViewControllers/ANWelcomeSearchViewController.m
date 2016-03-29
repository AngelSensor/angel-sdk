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


#import "ANWelcomeSearchViewController.h"
#import "ANRootNavigationController.h"
#import "ANPeripheral.h"
#import "ANSearchResultCell.h"
#import "ANAccount.h"

typedef enum {
    ViewModeNone,
    ViewModeSearching,
    ViewModeResults,
    ViewModeConnecting
} ViewMode;

@interface ANWelcomeSearchViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *searchContainer;

@property (nonatomic, weak) IBOutlet UIButton *backButton;

@property (nonatomic, weak) IBOutlet UIImageView *searchBraceletView;
@property (nonatomic, weak) IBOutlet UIImageView *searchActivityView;

@property (nonatomic, weak) IBOutlet UIView *resultsContainer;

@property (nonatomic, weak) IBOutlet UILabel *resultsHeaderLabel;
@property (nonatomic, weak) IBOutlet UITableView *resultsTableView;
@property (nonatomic, strong) NSArray *resultsDataContainer;

@property (nonatomic, weak) IBOutlet UIView *connectingContainer;
@property (nonatomic, weak) IBOutlet UILabel *connectingBraceletNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *connectingBraceletNumberLabel;
@property (nonatomic, weak) IBOutlet UIView *connectingBorderView;
@property (nonatomic, weak) IBOutlet UIImageView *connectingActivityView;
@property (nonatomic, weak) IBOutlet UIButton *connectingFoundButton;

@property (nonatomic, weak) IBOutlet UIView *keepSearchingContainer;
@property (nonatomic, weak) IBOutlet UIButton *keepSearchingButton;
@property (nonatomic, weak) IBOutlet UILabel *keepSearchingLabel;

@property (nonatomic, weak) ANPeripheral *selectedDevice;

@property (nonatomic) ViewMode viewMode;
@property BOOL animating;

@end

@implementation ANWelcomeSearchViewController

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
                    case ViewModeSearching: {
                        self.backButton.hidden = YES;
                        if (_viewMode != ViewModeNone) {
                            self.searchContainer.alpha = 0.0f;
                            self.searchContainer.hidden = NO;
                            
                            innerAnimationBlock = ^{
                                self.searchContainer.alpha = 1.0f;
                                self.resultsContainer.alpha = 0.0f;
                                self.connectingContainer.alpha = 0.0f;
                                self.keepSearchingContainer.alpha = 0.0f;
                            };
                            
                            innerCompletionBlock = ^{
                                self.resultsContainer.hidden = YES;
                                self.connectingContainer.hidden = YES;
                                self.keepSearchingContainer.hidden = YES;
                                defaultCompletionBlock();
                            };
                        } else {
                            innerCompletionBlock = defaultCompletionBlock;
                        }
                    } break;
                    case ViewModeResults: {
                        self.backButton.hidden = NO;
                        self.resultsContainer.alpha = 0.0f;
                        self.resultsContainer.hidden = NO;
                        
                        self.keepSearchingContainer.alpha = 0.0f;
                        self.keepSearchingContainer.hidden = NO;
                        
                        [self.searchActivityView.layer removeAllAnimations];
                        
                        innerAnimationBlock = ^{
                            self.searchContainer.alpha = 0.0f;
                            self.resultsContainer.alpha = 1.0f;
                            self.connectingContainer.alpha = 0.0f;
                            self.keepSearchingContainer.alpha = 1.0f;
                        };
                        
                        innerCompletionBlock = ^{
                            self.searchContainer.hidden = YES;
                            self.connectingContainer.hidden = YES;
                            defaultCompletionBlock();
                        };
                        
                    } break;
                    case ViewModeConnecting: {
                        self.backButton.hidden = NO;
                        self.connectingContainer.alpha = 0.0f;
                        self.connectingContainer.hidden = NO;
                        
                        self.connectingBraceletNameLabel.text = self.selectedDevice.name;
                        self.connectingBraceletNumberLabel.text = self.selectedDevice.identifier;
                        
                        [self addRotationAnimationForView:self.connectingActivityView];
                        
                        innerAnimationBlock = ^{
                            self.searchContainer.alpha = 0.0f;
                            self.resultsContainer.alpha = 0.0f;
                            self.connectingContainer.alpha = 1.0f;
                        };
                        
                        innerCompletionBlock = ^{
                            self.searchContainer.hidden = YES;
                            self.resultsContainer.hidden = YES;
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

- (void)startSearching {
    [self setViewMode:ViewModeSearching];
    
    [self addRotationAnimationForView:self.searchActivityView];
    
    [[ANDataManager sharedManager] searchPeripheralWithCompletionHandler:^(NSArray *result, NSError *error) {
        if (result && !error) {
            self.resultsDataContainer = result;
            [self.resultsTableView reloadData];
        }
        [self setViewMode:ViewModeResults animated:YES completion:nil];
    }];
}

- (void)stopSearching {
    [self.searchActivityView.layer removeAllAnimations];
    [[ANDataManager sharedManager] stopScanningForPeripherals];
}

- (void)addRotationAnimationForView:(UIView *)view {
    [view.layer removeAllAnimations];
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotation.fromValue = [NSNumber numberWithFloat:0];
    rotation.toValue = [NSNumber numberWithFloat:(2 * M_PI)];
    rotation.duration = 1.0f;
    rotation.repeatCount = HUGE_VALF;
    [view.layer addAnimation:rotation forKey:@"Spin"];
}

#pragma mark Interface Actions

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)foundButtonPressed:(id)sender {
    [[ANAccount currentAccount] save];
    [(ANRootNavigationController *)self.navigationController moveToMainScreen];
    /*if ([ANAccount accountExists]) {
        [(ANRootNavigationController *)self.navigationController moveToMainScreen];
    } else {
        [(ANRootNavigationController *)self.navigationController pushViewControllerWithIdentifier:@"welcomeWeightGenderMetricsViewController" animated:YES];
    }*/
}

- (IBAction)keepSearchingPressed:(id)sender {
    self.resultsDataContainer = nil;
    [self.resultsTableView reloadData];
    [self startSearching];
}

- (void)connectDevice:(ANPeripheral *)peripheral {
    self.selectedDevice = peripheral;
    [self setViewMode:ViewModeConnecting animated:YES completion:nil];
    ANDataManager *dMgr = [ANDataManager sharedManager];
    
    self.connectingFoundButton.enabled = NO;
    self.connectingFoundButton.backgroundColor = UIColorFromRGB(0x75863f);
    
    [dMgr connectPeripheral:peripheral completionHandler:^(BOOL success, NSError *error) {
        if (success && !error) {
            self.connectingFoundButton.enabled = YES;
            self.connectingFoundButton.backgroundColor = UIColorFromRGB(0xeedb1f);
            [[ANAccount currentAccount] save];
            [(ANRootNavigationController *)self.navigationController moveToMainScreen];
        }
    }];
}

#pragma mark UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [self.resultsHeaderLabel setText:[NSString stringWithFormat:@"%lu devices\r\nhave been found", (unsigned long)self.resultsDataContainer.count]];
    return self.resultsDataContainer.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ANSearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    ANPeripheral *bracelet = [self.resultsDataContainer objectAtIndex:indexPath.row];
    
    cell.nameLabel.text = bracelet.name;
    cell.idLabel.text = bracelet.identifier;
    
    return cell;
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self connectDevice:[self.resultsDataContainer objectAtIndex:indexPath.row]];
}

#pragma mark View lifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startSearching];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopSearching];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.connectingBorderView.layer.cornerRadius = 3.0f;
    self.connectingBorderView.layer.borderColor = UIColorFromRGB(0xeedb1f).CGColor;
    self.connectingBorderView.layer.borderWidth = 1.0f;
    
    self.connectingFoundButton.layer.cornerRadius = 3.0f;
    self.connectingFoundButton.layer.masksToBounds = YES;
    
    self.keepSearchingButton.layer.cornerRadius = 3.0f;
    self.keepSearchingButton.layer.masksToBounds = YES;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
