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


#import "ANAccount.h"
#import "EGOCache.h"

#define kAccountID @"accountID"
#define kAccountName @"accountName"
#define kAccountWeight @"accountWeight"
#define kAccountHeight @"accountHeight"
#define kAccountBirthdate @"accountBirthdate"
#define kAccountEmail @"accountEmail"

#define kAccountGender @"accountGender"
#define kAccountWeightMetrics @"accountWeightMetrics"
#define kAccountHeightMetrics @"accountHeightMetrics"

@interface ANAccount ()

@end

@implementation ANAccount

@synthesize accountImage = _accountImage;

+ (instancetype)currentAccount {
    static ANAccount *instance = nil;
    if (!instance) {
        instance = (ANAccount *)[[ANAccount cacheManager] objectForKey:kCurrentAccount];
        if (!instance) {
            instance = [[ANAccount alloc] init];
        }
    }
    return instance;
}

+ (BOOL)accountExists {
    return [[ANAccount cacheManager] hasCacheForKey:kCurrentAccount];
}

+ (EGOCache *)cacheManager {
    static dispatch_once_t onceToken;
    static EGOCache *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[EGOCache alloc] initWithCacheDirectory:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"storage"]];
    });
    return instance;
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.accountID = [aDecoder decodeObjectForKey:kAccountID];
        self.accountName = [aDecoder decodeObjectForKey:kAccountName];
        self.accountWeight = [aDecoder decodeObjectForKey:kAccountWeight];
        self.accountHeight = [aDecoder decodeObjectForKey:kAccountHeight];
        self.accountBirthdate = [aDecoder decodeObjectForKey:kAccountBirthdate];
        self.accountEmail = [aDecoder decodeObjectForKey:kAccountEmail];
        
        self.accountGender = (Gender)[aDecoder decodeIntegerForKey:kAccountGender];
        self.accountWeightMetrics = (WeightMetrics)[aDecoder decodeIntegerForKey:kAccountWeightMetrics];
        self.accountHeightMetrics = (HeightMetrics)[aDecoder decodeIntegerForKey:kAccountHeightMetrics];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.accountID forKey:kAccountID];
    [aCoder encodeObject:self.accountName forKey:kAccountName];
    [aCoder encodeObject:self.accountWeight forKey:kAccountWeight];
    [aCoder encodeObject:self.accountHeight forKey:kAccountHeight];
    [aCoder encodeObject:self.accountBirthdate forKey:kAccountBirthdate];
    [aCoder encodeObject:self.accountEmail forKey:kAccountEmail];
    
    [aCoder encodeInteger:self.accountGender forKey:kAccountGender];
    [aCoder encodeInteger:self.accountWeightMetrics forKey:kAccountWeightMetrics];
    [aCoder encodeInteger:self.accountHeightMetrics forKey:kAccountHeightMetrics];
}

#pragma mark Image handling

- (void)setAccountImage:(UIImage *)accountImage {
    if (accountImage) {
        [[ANAccount cacheManager] setImage:accountImage forKey:kAccountImage];
    } else {
        [[ANAccount cacheManager] removeCacheForKey:kAccountImage];
    }
    _accountImage = accountImage;
}

- (UIImage *)accountImage {
    if (!_accountImage) {
        _accountImage = [[ANAccount cacheManager] imageForKey:kAccountImage];
    }
    return _accountImage;
}

#pragma mark Saving

- (void)save {
    [[ANAccount cacheManager] setObject:self forKey:kCurrentAccount];
}

@end
