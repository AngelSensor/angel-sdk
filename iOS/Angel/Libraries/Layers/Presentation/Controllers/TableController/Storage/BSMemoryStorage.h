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


@protocol BSMemoryStorageDelegate <NSObject>

- (void)reloadData;
- (void)addItemsToIndexPaths:(NSArray*)indexPaths withRowAnimation:(UITableViewRowAnimation)animation;
- (void)reloadItemsForIndexPaths:(NSArray*)indexPaths withRowAnimation:(UITableViewRowAnimation)animation;
- (void)removeItemsForIndexPaths:(NSArray*)indexPaths withRowAnimation:(UITableViewRowAnimation)animation;

@end


@protocol BSMemoryStorageInterface <NSObject>

@property (nonatomic, weak) id<BSMemoryStorageDelegate> delegate;

@end


@interface BSMemoryStorage : NSObject <BSMemoryStorageInterface>

@property (nonatomic, strong) NSMutableArray* storageArray;
@property (nonatomic, weak) id<BSMemoryStorageDelegate> delegate;

+ (instancetype)storage;

#pragma mark - get Item

- (id)itemAtIndexPath:(NSIndexPath*)indexPath;

#pragma mark - Adding Items

// Add item to section 0.
- (void)addItem:(id)item;

- (void)addItems:(NSArray*)items;
- (void)addItems:(NSArray*)items withRowAnimation:(UITableViewRowAnimation)animation;

- (void)addItem:(id)item atIndexPath:(NSIndexPath *)indexPath withRowAnimation:(UITableViewRowAnimation)animation;
- (void)addItem:(id)item atIndexPath:(NSIndexPath *)indexPath;


#pragma mark - Reloading Items

- (void)reloadItem:(id)item;

- (void)reloadItems:(NSArray*)items withRowAnimation:(UITableViewRowAnimation)animation;
- (void)reloadItems:(NSArray*)items;


#pragma mark - Removing Items

- (void)removeItem:(id)item;

- (void)removeItems:(NSArray*)items withRowAnimation:(UITableViewRowAnimation)animation;
- (void)removeItems:(NSArray*)items;
- (void)removeAllItems;

@end
