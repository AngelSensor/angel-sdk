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

#import "ANUpdateFirmwareContentView.h"
#import "ANUpdateViewDomainModel.h"

@interface ANUpdateFirmwareContentView ()

@property (nonatomic, strong) UIImageView* logoImage;
@property (nonatomic, strong) UIImageView* warningImage;
@property (nonatomic, strong) UILabel* warningMessage;
@property (nonatomic, strong) UIView* separator;

@end

static NSString* const kButtonBackground = @"21272A";

@implementation ANUpdateFirmwareContentView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background_image"]];
        self.titleLabel.text = NSLocalizedString(@"update", nil);
        self.progressLable.text = NSLocalizedString(@"progress", nil);
        
        self.warningMessage.text = NSLocalizedString(@"Please keep Angel connected to a power source while updating", nil);
        [self separator];
        
    }
    return self;
}

- (void)updateWithModel:(ANUpdateViewDomainModel *)model
{
    self.titleLabel.text = [NSString stringWithFormat:@"%@ %@",model.updateMode, NSLocalizedString(@"update", nil)];
    self.progressLable.text = [NSString stringWithFormat:@"%@ %@%%",NSLocalizedString(@"Progress", nil), model.progress];
}

#pragma mark - Lazy Load

- (UIImageView*)logoImage
{
    if (!_logoImage)
    {
        _logoImage = [UIImageView new];
        _logoImage.image = [UIImage imageNamed:@"icn_menu"];
        [self addSubview:_logoImage];
        
        [_logoImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(45);
            make.left.equalTo(self).offset(5);
            make.height.width.equalTo(@46);
        }];
    }
    return _logoImage;
}

- (UILabel*)titleLabel
{
    if (!_titleLabel)
    {
        _titleLabel = [UILabel new];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.textColor = [UIColor yellowColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:26];
        [self addSubview:_titleLabel];
        
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(60);
            make.left.equalTo(self).offset(40);
            make.right.equalTo(self).offset(-40);
        }];
    }
    return _titleLabel;
}

- (UILabel*)progressLable
{
    if (!_progressLable)
    {
        _progressLable = [UILabel new];
        _progressLable.textColor = [UIColor whiteColor];
        _progressLable.textAlignment = NSTextAlignmentCenter;
        _progressLable.adjustsFontSizeToFitWidth = YES;
        _progressLable.font = [UIFont systemFontOfSize:16];
        [self addSubview:_progressLable];
        
        [_progressLable mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
            make.left.equalTo(self).offset(40);
            make.right.equalTo(self).offset(-40);
        }];
    }
    return _progressLable;
}

- (UIButton*)cancelButton
{
    if (!_cancelButton)
    {
        _cancelButton = [UIButton new];
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        _cancelButton.backgroundColor = [UIColor bs_colorWithHexString:kButtonBackground];
        _cancelButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        _cancelButton.layer.cornerRadius = 5;
        _cancelButton.layer.borderColor = [UIColor yellowColor].CGColor;
        _cancelButton.layer.borderWidth = 2;
        [_cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [self addSubview:_cancelButton];
        
        [_cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.progressLable.mas_bottom).offset(20);
            make.right.equalTo(self.mas_centerX).offset(-15);
            make.height.equalTo(@34);
            make.width.equalTo(@110);
        }];
    }
    return _cancelButton;
}

- (UIButton*)pauseButton
{
    if (!_pauseButton)
    {
        _pauseButton = [UIButton new];
        [_pauseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_pauseButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [_pauseButton setTitle:NSLocalizedString(@"Continue", nil) forState:UIControlStateSelected];
        
        _pauseButton.backgroundColor = [UIColor bs_colorWithHexString:kButtonBackground];
        _pauseButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        _pauseButton.layer.cornerRadius = 5;
        _pauseButton.layer.borderColor = [UIColor yellowColor].CGColor;
        _pauseButton.layer.borderWidth = 2;
        _pauseButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        [_pauseButton setTitle:NSLocalizedString(@"Pause", nil) forState:UIControlStateNormal];
        [self addSubview:_pauseButton];
        
        [_pauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.progressLable.mas_bottom).offset(20);
            make.left.equalTo(self.mas_centerX).offset(15);
            make.height.equalTo(@34);
            make.width.equalTo(@110);
        }];
    }
    return _pauseButton;
}

- (UIImageView*)warningImage
{
    if (!_warningImage)
    {
        _warningImage = [UIImageView new];
        _warningImage.image = [UIImage imageNamed:@"icn_info_selected"];
        _warningImage.layer.borderWidth = 2;
        _warningImage.layer.borderColor = [UIColor bs_colorWithHexString:@"EEDB1F"].CGColor;
        _warningImage.layer.cornerRadius = 20;
        
        [self addSubview:_warningImage];
        
        [_warningImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.cancelButton.mas_bottom).offset(30);
            make.left.equalTo(self).offset(20);
            make.width.height.equalTo(@40);
        }];
    }
    return _warningImage;
}

- (UILabel*)warningMessage
{
    if (!_warningMessage)
    {
        _warningMessage = [UILabel new];
        _warningMessage.textColor = [UIColor whiteColor];
        _warningMessage.numberOfLines = 2;
        _warningMessage.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_warningMessage];
        
        [_warningMessage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.warningImage);
            make.left.equalTo(self.warningImage.mas_right).offset(10);
            make.right.equalTo(self).offset(-20);
        }];
    }
    return _warningMessage;
}

- (UIView*)separator
{
    if (!_separator)
    {
        _separator = [UIView new];
        _separator.backgroundColor = [UIColor whiteColor];
        [self addSubview:_separator];
        
        [_separator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.warningImage.mas_bottom).offset(20);
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            make.height.equalTo(@1);
        }];
    }
    return _separator;
}

- (UITableView*)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.scrollEnabled = NO;
        [self addSubview:_tableView];
        
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.warningImage.mas_bottom).offset(40);
            make.bottom.equalTo(self).offset(-40);
            make.left.equalTo(self).offset(35);
            make.right.equalTo(self).offset(-35);
        }];
    }
    return _tableView;
}

@end
