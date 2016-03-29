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


#import "ANRightNowViewController.h"
#import "ANAnimationView.h"
#import "ANTempAnimationView.h"
#import "ANConnectionManager.h"

@interface ANRightNowViewController ()

@property (nonatomic, weak) IBOutlet UILabel *heartRateLabel;
@property (nonatomic, weak) IBOutlet UILabel *temperatureLabel;
@property (nonatomic, weak) IBOutlet UILabel *oxygenRateLabel;
@property (nonatomic, weak) IBOutlet UILabel *stepsRateLabel;
@property (nonatomic, weak) IBOutlet UILabel *energyRateLabel;

@property (nonatomic, weak) IBOutlet ANAnimationView *heartAnimationView;
@property (nonatomic, weak) IBOutlet ANAnimationView *tempAnimationView;
@property (nonatomic, weak) IBOutlet ANAnimationView *oxygenAnimationView;
@property (nonatomic, weak) IBOutlet ANAnimationView *stepsAnimationView;
@property (nonatomic, weak) IBOutlet ANAnimationView *energyAnimationView;

@end

@implementation ANRightNowViewController

#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

#pragma mark String composing

- (NSAttributedString *)attributedStringForString:(NSString *)sourceString small:(NSString *)small {
    UIFont *largeFont = [UIFont fontWithName:@"Asap-Regular" size:34.0f];
    UIFont *smallFont = [UIFont fontWithName:@"Asap-Regular" size:20.0f];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:sourceString];
    
    [attributedString addAttribute:NSFontAttributeName value:largeFont range:NSMakeRange(0, [attributedString length])];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, [attributedString length])];
    
    if (small) {
        [attributedString addAttribute:NSFontAttributeName value:smallFont range:[attributedString.string rangeOfString:small]];
    }
    
    return attributedString;
}

#pragma mark Data loading

- (void)reloadData {
    
    ANDataManager *dMgr = [ANDataManager sharedManager];
    
    [dMgr heartRateDataWithRefreshHandler:^(NSNumber *result) {
        if (result) {
            self.heartRateLabel.attributedText = [self attributedStringForString:[NSString stringWithFormat:@"%d BPM", result.intValue] small:@"BPM"];
            [self.heartAnimationView animateOnce];
        }
    }];
    
    [dMgr temperatureDataWithRefreshHandler:^(NSNumber *result) {
        if (result) {
            self.temperatureLabel.attributedText = [self attributedStringForString:[NSString stringWithFormat:@"%0.1f°C", result.floatValue] small:nil];
            [self.tempAnimationView animateOnce];
        }
    }];
    
    [dMgr oxygenDataWithRefreshHandler:^(NSNumber *result) {
        if (result) {
            self.oxygenRateLabel.attributedText = [self attributedStringForString:[NSString stringWithFormat:@"%0.1f %%", result.floatValue] small:nil];
            [self.oxygenAnimationView animateOnce];
        }
    }];
    
    [dMgr energyDataWithRefreshHandler:^(NSNumber *result) {
        if (result) {
            self.energyRateLabel.attributedText = [self attributedStringForString:[NSString stringWithFormat:@"%0.0f g/sec", result.floatValue] small:@"g/sec"];
            [self.energyAnimationView animateOnce];
        }
    }];
    
    [dMgr stepsDataWithRefreshHandler:^(NSNumber *result) {
        if (result) {
            self.stepsRateLabel.attributedText = [self attributedStringForString:[NSString stringWithFormat:@"%d Steps", result.intValue] small:@"Steps"];
            [self.stepsAnimationView animateOnce];
        }
    }];
}

- (void)stopReloading {
    [[ANDataManager sharedManager] stopRefreshingData];
}

#pragma mark View lifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopReloading];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
