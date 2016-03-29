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


#import "ANHeightViewController.h"
#import "ANGaugeView.h"

@interface ANHeightViewController () <ANGaugeViewDataSource, ANGaugeViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton *cmButton;
@property (nonatomic, weak) IBOutlet UIButton *inButton;

@property (nonatomic, weak) IBOutlet UILabel *heightLabel;

@end

@implementation ANHeightViewController

#pragma mark Custom setters

- (void)setHeightMetrics:(HeightMetrics)heightMetrics {
    HeightMetrics prevMetrics = self.heightMetrics;
    _heightMetrics = heightMetrics;
    
    self.cmButton.selected = NO;
    self.inButton.selected = NO;
    
    switch (heightMetrics) {
        case HeightMetricsCm: {
            self.cmButton.selected = YES;
        } break;
        case HeightMetricsIn: {
            self.inButton.selected = YES;
        } break;
    }
    
    NSInteger currentValue = self.gaugeView.currentValue;
    
    if (prevMetrics != heightMetrics) {
        currentValue = round(currentValue * ((self.heightMetrics == HeightMetricsCm) ? 2.54f : 0.393701f));
    }
    
    self.gaugeView.step = (self.heightMetrics == HeightMetricsCm) ? GaugeStepDefault : GaugeStepInches;
    
    [self.gaugeView reloadData];
    [self.gaugeView setCurrentValue:currentValue];
}

#pragma mark Interface Actions

- (IBAction)cmButtonPressed:(id)sender {
    [self setHeightMetrics:HeightMetricsCm];
}

- (IBAction)inButtonPressed:(id)sender {
    [self setHeightMetrics:HeightMetricsIn];
}

#pragma mark ANGaugeView dataSource

- (GaugeViewType)typeForGaugeView:(ANGaugeView *)gaugeView {
    return GaugeViewTypeVertical;
}

- (NSInteger)minValueForGaugeView:(ANGaugeView *)gaugeView {
    return round(40 * (self.heightMetrics == HeightMetricsCm ? 1.0f : 0.393701f));
}

- (NSInteger)maxValueForGaugeView:(ANGaugeView *)gaugeView {
    return round(240 * (self.heightMetrics == HeightMetricsCm ? 1.0f : 0.393701f));;
}

- (UIColor *)longLineColorForGaugeView:(ANGaugeView *)gaugeView {
    return UIColorFromRGB(0xeedb1f);
}

- (UIColor *)shortLineColorForGaugeView:(ANGaugeView *)gaugeView {
    return UIColorFromRGBA(0xfcfcfc, 0.71);
}

#pragma mark ANGaugeView delegate

- (void)gaugeView:(ANGaugeView *)gaugeView valueChanged:(NSInteger)value {
    if (self.heightMetrics == HeightMetricsCm) {
        self.heightLabel.text = [NSString stringWithFormat:@"%d", (int)value];
    } else {
        self.heightLabel.text = [NSString stringWithFormat:@"%d'%d\"", (int)value / 12, (int)value % 12];
    }
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
