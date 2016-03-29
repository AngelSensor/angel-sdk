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

#import "BSTableViewFactory.h"
#import "BSBaseTableViewCell.h"
#import "BSRuntimeHelper.h"

@interface BSTableViewFactory ()

@property (nonatomic,strong) NSMutableDictionary* cellMappingsDictionary;

@end

@implementation BSTableViewFactory

- (NSMutableDictionary *)cellMappingsDictionary
{
    if (!_cellMappingsDictionary)
    {
        _cellMappingsDictionary = [NSMutableDictionary new];
    }
    return _cellMappingsDictionary;
}

- (void)registerCellClass:(Class)cellClass forModelClass:(Class)modelClass
{
    NSParameterAssert([cellClass isSubclassOfClass:[UITableViewCell class]]);
    NSParameterAssert([cellClass conformsToProtocol:@protocol(BSModelTransfer)]);
    NSParameterAssert(modelClass);
    
    NSString * reuseIdentifier = [BSRuntimeHelper classStringForClass:cellClass];
    
    NSParameterAssert(reuseIdentifier);
    reuseIdentifier = reuseIdentifier ? : @"";
    
    [[self.delegate tableView] registerClass:cellClass
                      forCellReuseIdentifier:reuseIdentifier];
    
    [self.cellMappingsDictionary setObject:[BSRuntimeHelper classStringForClass:cellClass]
                                    forKey:[BSRuntimeHelper modelStringForClass:modelClass]];
}

- (UITableViewCell *)cellForModel:(id)model atIndexPath:(NSIndexPath *)indexPath
{
    NSString * reuseIdentifier = [self _cellReuseIdentifierForModel:model];
    NSParameterAssert(reuseIdentifier);
    reuseIdentifier = reuseIdentifier ? : @"";
    
    UITableViewCell <BSModelTransfer> * cell;
    if (reuseIdentifier)
    {
        cell = [[self.delegate tableView] dequeueReusableCellWithIdentifier:reuseIdentifier
                                                               forIndexPath:indexPath];
        [cell updateWithModel:model];
    }
    else
    {
        cell = [BSBaseTableViewCell new];
    }
    return cell;
}

- (NSString *)_cellReuseIdentifierForModel:(id)model
{
    NSString* modelClassName = [BSRuntimeHelper modelStringForClass:[model class]];
    NSString* cellClassString = [self.cellMappingsDictionary objectForKey:modelClassName];
    NSAssert(cellClassString, @"%@ does not have cell mapping for model class: %@",[self class], [model class]);
    
    return cellClassString;
}


@end
