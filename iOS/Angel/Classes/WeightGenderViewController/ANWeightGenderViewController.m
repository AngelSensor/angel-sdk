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


#import "ANWeightGenderViewController.h"
#import "ANGaugeView.h"

NSInteger const defaultMaleWeight = 100;
NSInteger const defaultFemaleWeight = 85;

@interface ANWeightGenderViewController () <ANGaugeViewDataSource, ANGaugeViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton *maleButton;
@property (nonatomic, weak) IBOutlet UIButton *femaleButton;

@property (nonatomic, weak) IBOutlet UIButton *kgButton;
@property (nonatomic, weak) IBOutlet UIButton *lbButton;

@property (nonatomic, weak) IBOutlet UILabel *weightLabel;

@end

@implementation ANWeightGenderViewController


#pragma mark Custom setters

- (void)setWeightMetrics:(WeightMetrics)weightMetrics {
    WeightMetrics prevMetrics = self.weightMetrics;
    _weightMetrics = weightMetrics;
    
    self.kgButton.selected = NO;
    self.lbButton.selected = NO;
    
    switch (weightMetrics) {
        case WeightMetricsKg: {
            self.kgButton.selected = YES;
        } break;
        case WeightMetricsLb: {
            self.lbButton.selected = YES;
        } break;
    }
    
    NSInteger currentValue = self.gaugeView.currentValue;
    
    if (prevMetrics != weightMetrics) {
        currentValue = round(currentValue * ((self.weightMetrics == WeightMetricsKg) ? 0.453592f : 2.20462f));
    }
    
    [self.gaugeView reloadData];
    [self.gaugeView setCurrentValue:currentValue];
}

- (void)setGender:(Gender)gender {
    _gender = gender;
    
    [self.gaugeView reloadData];
    
    self.maleButton.selected = NO;
    self.femaleButton.selected = NO;
    
    switch (gender) {
        case GenderMale: {
            self.maleButton.selected = YES;
        } break;
        case GenderFemale: {
            self.femaleButton.selected = YES;
        } break;
    }

    NSInteger currentValue;
    if (self.gender == GenderMale) {
        currentValue = defaultMaleWeight;
    } else {
        currentValue = defaultFemaleWeight;
    }
    [self.gaugeView setCurrentValue:round(currentValue * (self.weightMetrics == WeightMetricsKg ? 1.0f : 2.20462))];

}

#pragma mark Interface Actions

- (IBAction)maleButtonPressed:(id)sender {
    [self setGender:GenderMale];
}

- (IBAction)femaleButtonPressed:(id)sender {
    [self setGender:GenderFemale];
}

- (IBAction)kgButtonPressed:(id)sender {
    [self setWeightMetrics:WeightMetricsKg];
}

- (IBAction)lbButtonPressed:(id)sender {
    [self setWeightMetrics:WeightMetricsLb];
}

#pragma mark ANGaugeView dataSource

- (GaugeViewType)typeForGaugeView:(ANGaugeView *)gaugeView {
    return GaugeViewTypeHorizontal;
}

- (NSInteger)minValueForGaugeView:(ANGaugeView *)gaugeView {
    return round(20 * ((self.weightMetrics == WeightMetricsKg) ? 1.0f : 2.20462));
}

- (NSInteger)maxValueForGaugeView:(ANGaugeView *)gaugeView {
    return round(200 * ((self.weightMetrics == WeightMetricsKg) ? 1.0f : 2.20462));
}

- (UIColor *)longLineColorForGaugeView:(ANGaugeView *)gaugeView {
    return UIColorFromRGB(0xeedb1f);
}

- (UIColor *)shortLineColorForGaugeView:(ANGaugeView *)gaugeView {
    return UIColorFromRGBA(0xfcfcfc, 0.71);
}

#pragma mark ANGaugeView delegate

- (void)gaugeView:(ANGaugeView *)gaugeView valueChanged:(NSInteger)value {
    self.weightLabel.text = [NSString stringWithFormat:@"%ld", (long)value];
}

#pragma mark View lifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.gaugeView.dataSource = self;
    self.gaugeView.delegate = self;
    
    [self.gaugeView reloadData];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
