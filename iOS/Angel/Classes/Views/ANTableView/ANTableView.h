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
#import "ANTableViewItem.h"

@class ANTableView;

@protocol ANTableViewDataSource <NSObject>

- (NSUInteger)numberOfItemsInTableView:(ANTableView *)tableView;
- (UIView *)tableView:(ANTableView *)tableView openedViewAtIndex:(NSUInteger)index;
- (UIView *)tableView:(ANTableView *)tableView closedViewAtIndex:(NSUInteger)index;

@end

@protocol ANTableViewDelegate <NSObject>

@optional

- (BOOL)tableView:(ANTableView *)tableView shouldOpenItemAtIndex:(NSUInteger)index sourceHeight:(CGFloat)sourceHeight targetHeight:(CGFloat)targetHeight;
- (void)tableView:(ANTableView *)tableView didSelectItemAtIndex:(NSUInteger)index;

@end

@interface ANTableView : UIView

@property (nonatomic, assign) id<ANTableViewDataSource> dataSource;
@property (nonatomic, assign) id<ANTableViewDelegate> delegate;

@property (nonatomic, assign) BOOL isOpenedState;
@property NSInteger indexOfOpenedItem;

@property (nonatomic, strong) UITableView *tableView;

@property BOOL scrollEnabled;

- (void)reloadData;

- (void)openItemAtIndex:(NSUInteger)index animated:(BOOL)animated completion:(void(^)(void))completion;
- (void)closeItemAtIndex:(NSUInteger)index animated:(BOOL)animated completion:(void(^)(void))completion;

- (NSUInteger)indexOfItem:(ANTableViewItem *)item;
- (ANTableViewItem *)itemAtIndex:(NSUInteger)index;

@end
