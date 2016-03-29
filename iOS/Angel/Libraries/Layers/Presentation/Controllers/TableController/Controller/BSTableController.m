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


#import "BSTableController.h"

@interface BSTableController ()
<
    BSTableViewFactoryDelegate,
    BSMemoryStorageDelegate
>

@end


@implementation BSTableController

@synthesize storage = _storage;

- (instancetype)initWithTableView:(UITableView*)tableView
{
    self = [super init];
    if (self)
    {
        self.tableView = tableView;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        [self _setupTableViewControllerDefaults];
    }
    return self;
}

- (void)dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.cellFactory.delegate = nil;
    if ([self.storage respondsToSelector:@selector(setDelegate:)])
    {
        [self.storage setDelegate:nil];
    }
}

- (void)_setupTableViewControllerDefaults
{
    _cellFactory = [BSTableViewFactory new];
    _cellFactory.delegate = self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        NSString * reason = [NSString stringWithFormat:@"You shouldn't init class %@ with method %@\n Please use initWithTableView method.",
                             NSStringFromSelector(_cmd), NSStringFromClass([self class])];
        NSException * exc =
        [NSException exceptionWithName:[NSString stringWithFormat:@"%@ Exception", NSStringFromClass([self class])]
                                reason:reason
                              userInfo:nil];
        [exc raise];
    }
    return self;
}


#pragma mark - getter/setter

- (BSMemoryStorage *)memoryStorage
{
    if ([self.storage isKindOfClass:[BSMemoryStorage class]])
    {
        return (BSMemoryStorage *)self.storage;
    }
    return nil;
}

- (id<BSMemoryStorageInterface>)storage
{
    if (!_storage)
    {
        _storage = [BSMemoryStorage storage];
        [self _attachStorage:_storage];
    }
    return _storage;
}

- (void)setStorage:(id <BSMemoryStorageInterface>)storage
{
    _storage = storage;
    [self _attachStorage:_storage];
}


#pragma mark - UITableView Class Registrations

- (void)registerCellClass:(Class)cellClass forModelClass:(Class)modelClass
{
    [self.cellFactory registerCellClass:cellClass forModelClass:modelClass];
}


#pragma mark - Private

- (void)_attachStorage:(id<BSMemoryStorageInterface>)storage
{
    storage.delegate = (id<BSMemoryStorageDelegate>)self;
   if ( self.memoryStorage.storageArray.count)
   {
       [self.tableView reloadData];
   }
}


#pragma mark - UITableView Protocols Implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self memoryStorage] storageArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* storageArray = [[self memoryStorage] storageArray];
    id model = [storageArray objectAtIndex:indexPath.row];
    
    return [self.cellFactory cellForModel:model atIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - BSMemoryStorageDelegate

- (void)reloadData
{
    [self.tableView reloadData];
}

- (void)addItemsToIndexPaths:(NSArray*)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)reloadItemsForIndexPaths:(NSArray*)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)removeItemsForIndexPaths:(NSArray*)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}


@end
