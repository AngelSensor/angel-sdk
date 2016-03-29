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

#import "BSHelperFunctions.h"

void BSDispatchCompletionBlockToMainQueue(BSCompletionBlock block, NSError *error)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) block(error);
    });
}

BSCompletionBlock BSMainQueueCompletionFromCompletion(BSCompletionBlock block)
{
    if (!block) return NULL;
    return ^(NSError *error) {
        BSDispatchBlockToMainQueue(^{
           block(error);
        });
    };
}

void BSDispatchBlockToMainQueue(BSCodeBlock block)
{
    if ([NSThread isMainThread])
    {
        if (block) block();
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) block();
        });
    }
}

BSCodeBlock BSMainQueueBlockFromCompletion(BSCodeBlock block)
{
    if (!block) return NULL;
    return ^{
        
        BSDispatchBlockToMainQueue(^{
            block();
        });
    };
}

void BSDispatchBlockAfter(CGFloat time, BSCodeBlock block)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

void BSDispatchBlockToBackgroundQueue(BSCodeBlock block)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (block) block();
    });
}


#pragma mark - Objects

BOOL BSIsEmpty(id thing)
{
    return ((thing == nil) || ([thing isEqual:[NSNull null]]) ||
            ([thing respondsToSelector:@selector(length)] && [(NSData *)thing length] == 0) ||
            ([thing respondsToSelector:@selector(count)] && [(NSArray *)thing count] == 0));
}

BOOL BSIsEmptyStringByTrimmingWhitespaces(NSString* string)
{
    if (string)
    {
        string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return ((string == nil) ||
            ([string respondsToSelector:@selector(length)] && [string length] == 0));
}
