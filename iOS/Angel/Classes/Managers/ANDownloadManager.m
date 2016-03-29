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


#import "ANDownloadManager.h"
#import <AFNetworking/AFHTTPRequestOperation.h>

@interface ANDownloadManager ()

@property (nonatomic, strong) AFHTTPRequestOperation *downloadOperation;

@end

@implementation ANDownloadManager

#pragma mark Initialization

- (id)init {
    self = [super init];
    if (self) {
    
    }
    return self;
}

+ (instancetype)sharedManager {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)downloadContentFrom:(NSURL *)originURL completion:(ContentCompletionBlock)completion {
    [self stopDownloading];
    if (originURL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:originURL];
        self.downloadOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [self.downloadOperation setResponseSerializer:[AFJSONResponseSerializer serializer]];
        [self.downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (completion) {
                if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
                    completion((NSDictionary *)responseObject, nil);
                } else {
                    completion(nil, [NSError errorWithDomain:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__] code:1 userInfo:nil]);
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (completion) {
                completion(nil, error);
            }
        }];
        
        [self.downloadOperation start];
        
    } else {
        if (completion) {
            completion(nil, [NSError errorWithDomain:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__] code:1 userInfo:nil]);
        }
    }
}

- (void)downloadFileFrom:(NSURL *)originURL progress:(DownloadProgressBlock)progress completion:(DownloadCompletionBlock)completion {
    if (originURL) {
        [self downloadFileFrom:originURL to:[NSTemporaryDirectory() stringByAppendingPathComponent:[originURL lastPathComponent]] progress:progress completion:completion];
    } else {
        if (completion) {
            completion(nil, [NSError errorWithDomain:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__] code:1 userInfo:nil]);
        }
    }
}
- (void)downloadFileFrom:(NSURL *)originURL to:(NSString *)filePath progress:(DownloadProgressBlock)progress completion:(DownloadCompletionBlock)completion {
    
    [self stopDownloading];
    
    if (originURL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:originURL];
        self.downloadOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [self.downloadOperation setOutputStream:[NSOutputStream outputStreamToFileAtPath:filePath append:NO]];
        
        //_weak typeof(self) wself = self;
        [self.downloadOperation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            if (totalBytesExpectedToRead > 0) {
                if (progress) {
                    progress(@(100 * totalBytesRead / (double)totalBytesExpectedToRead));
                }
            }
        }];

        [self.downloadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (completion) {
                completion(filePath, nil);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (completion) {
                completion(nil, error);
            }
        }];
        
        [self.downloadOperation start];
        
    } else {
        if (completion) {
            completion(nil, [NSError errorWithDomain:[NSString stringWithFormat:@"%s:%d", __func__, __LINE__] code:1 userInfo:nil]);
        }
    }
}

- (void)stopDownloading {
    if (self.downloadOperation) {
        [self.downloadOperation cancel];
        self.downloadOperation = nil;
    }
}

@end
