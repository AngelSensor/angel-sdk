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


#import <UIKit/UIKit.h>

@class ANUpdateView;

@protocol ANUpdateViewDelegate <NSObject>

@optional

- (void)updateViewUpdateButtonPressed:(ANUpdateView *)updateView;
- (void)updateViewShouldClose:(ANUpdateView *)updateView;

@end

typedef enum {
    ViewModeNone,
    ViewModeReadyToUpdate,
    ViewModeDownloading,
    ViewModeUpdating,
    ViewModeUpdated
} ViewMode;

@interface ANUpdateView : UIView

@property (nonatomic, weak) id <ANUpdateViewDelegate> delegate;

@property (nonatomic) ViewMode viewMode;

@property (nonatomic, weak) NSDictionary *updateInfo;

@property BOOL visible;

+ (id)sharedView;

- (void)showInView:(UIView *)superview animated:(BOOL)animated appearance:(void(^)(void))appearance completion:(void(^)(void))completion;
- (void)hide:(BOOL)animated completion:(void(^)(void))completion;

- (void)setViewMode:(ViewMode)viewMode animated:(BOOL)animated completion:(void(^)(void))completion;
- (void)setProgress:(NSNumber *)progress;

@end
