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

#import "BSMemoryStorage.h"

@implementation BSMemoryStorage


+ (instancetype)storage
{
    BSMemoryStorage* memoryStorage = [BSMemoryStorage new];
    return memoryStorage;
}

#pragma mark - Adding Items

#pragma mark - get Item

- (id)itemAtIndexPath:(NSIndexPath*)indexPath
{
    return [self.storageArray objectAtIndex:indexPath.row];
}

- (void)addItems:(NSArray*)items withRowAnimation:(UITableViewRowAnimation)animation
{
    if (!BSIsEmpty(items))
    {
        [self.storageArray addObjectsFromArray:items];
        NSMutableArray* indexArray = [NSMutableArray array];
        
        for (id item in items)
        {
            [indexArray addObject:[self _indexPathForItem:item]];
        }
        
        [self.delegate addItemsToIndexPaths:indexArray withRowAnimation:animation];
        return;
    }
    NSLog(@"Nil-objects not added to tableView");
}

- (void)addItems:(NSArray*)items
{
    [self addItems:items withRowAnimation:UITableViewRowAnimationNone];
}
    
- (void)addItem:(id)item
{
    [self addItems:@[item]];
}

- (void)addItem:(id)item atIndexPath:(NSIndexPath *)indexPath withRowAnimation:(UITableViewRowAnimation)animation
{
    if (BSIsEmpty(item) || indexPath.section > 0)
    {
        NSLog(@"Nil-object not added to tableView (section = %ld)",(long)indexPath.section);
        return;
    }
    
    if (indexPath.row > self.storageArray.count)
    {
        [self addItem:item];
    }
    else
    {
        [self.storageArray insertObject:item atIndex:indexPath.row];
    }
    
    [self.delegate addItemsToIndexPaths:@[indexPath] withRowAnimation:animation];
}

- (void)addItem:(id)item atIndexPath:(NSIndexPath *)indexPath
{
    [self addItem:item atIndexPath:indexPath withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark - Reloading Items

- (void)reloadItems:(NSArray*)items withRowAnimation:(UITableViewRowAnimation)animation
{
    NSMutableArray* indexPathArray = [NSMutableArray array];
    for (id item in items)
    {
        if (![self.storageArray containsObject:item])
        {
            NSLog(@"TableView not contained %@ item", item);
            continue;
        }
        [indexPathArray addObject:[self _indexPathForItem:item]];
    }
    [self.delegate reloadItemsForIndexPaths:indexPathArray withRowAnimation:animation];
}

- (void)reloadItems:(NSArray*)items
{
    [self reloadItems:items withRowAnimation:UITableViewRowAnimationNone];
}

- (void)reloadItem:(id)item
{
    if (BSIsEmpty(item))
    {
        NSLog(@"Nil-object not added to tableView");
        return;
    }
    [self reloadItems:@[item]];
}


#pragma mark - Removing Items

- (void)removeItem:(id)item
{
    [self removeItems:@[item]];
}

- (void)removeItems:(NSArray*)items withRowAnimation:(UITableViewRowAnimation)animation
{
    if (!BSIsEmpty(items))
    {
        NSMutableArray* indexArray = [NSMutableArray array];
        for (id item in items)
        {
            if ([self.storageArray containsObject:item])
            {
                [indexArray addObject:[self _indexPathForItem:item]];
                [self.storageArray removeObject:item];
                continue;
            }
            NSLog(@"TableView not contained %@ item", item);
        }
        
        [self.delegate removeItemsForIndexPaths:indexArray withRowAnimation:animation];
        return;
    }
    NSLog(@"Nil-objects not added to tableView");
}

- (void)removeItems:(NSArray*)items
{
    [self removeItems:items withRowAnimation:UITableViewRowAnimationNone];
}

- (void)removeAllItems
{
    [self.storageArray removeAllObjects];
    [self.delegate reloadData];
}


#pragma mark - Private

- (NSIndexPath*)_indexPathForItem:(id)item
{
    NSInteger row = [self.storageArray indexOfObject:item];
    return [NSIndexPath indexPathForRow:row inSection:0];
}


#pragma mark - Lazy Load

- (NSMutableArray*)storageArray
{
    if (!_storageArray)
    {
        _storageArray = [NSMutableArray array];
    }
    return _storageArray;
}

@end
