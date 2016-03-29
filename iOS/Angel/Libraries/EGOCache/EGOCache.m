//
//  EGOCache.m
//  enormego
//
//  Created by Shaun Harrison on 7/4/09.
//  Copyright (c) 2009-2012 enormego
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGOCache.h"

#if DEBUG
#define CHECK_FOR_EGOCACHE_PLIST() if([key isEqualToString:@"EGOCache.plist"]) { \
NSLog(@"EGOCache.plist is a reserved key and can not be modified."); \
return; }
#else
#define CHECK_FOR_EGOCACHE_PLIST() if([key isEqualToString:@"EGOCache.plist"]) return;
#endif

static inline NSString* cachePathForKey(NSString* directory, NSString* key) {
	return [directory stringByAppendingPathComponent:key];
}

static NSString * const kvalue = @"value";
static NSString * const kdate = @"date";

#pragma mark -

@interface EGOCache () {
	dispatch_queue_t _cacheInfoQueue;
	dispatch_queue_t _frozenCacheInfoQueue;
	dispatch_queue_t _diskQueue;
	NSMutableDictionary* _cacheInfo;
    NSString* _directory;
	BOOL _needsSave;
}

@property(nonatomic,copy) NSDictionary* frozenCacheInfo;

@end

@implementation EGOCache

+ (instancetype)currentCache {
	return [self globalCache];
}

+ (instancetype)globalCache {
	static id instance;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[[self class] alloc] init];
	});
	
	return instance;
}

- (id)init {
	NSString* cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
	NSString* oldCachesDirectory = [[[cachesDirectory stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]] stringByAppendingPathComponent:@"EGOCache"] copy];

	if([[NSFileManager defaultManager] fileExistsAtPath:oldCachesDirectory]) {
		[[NSFileManager defaultManager] removeItemAtPath:oldCachesDirectory error:NULL];
	}
	
	cachesDirectory = [[[cachesDirectory stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]] stringByAppendingPathComponent:@"EGOCache"] copy];
	return [self initWithCacheDirectory:cachesDirectory];
}

- (id)initWithCacheDirectory:(NSString*)cacheDirectory {
	if((self = [super init])) {
		_cacheInfoQueue = dispatch_queue_create("com.enormego.egocache.info", DISPATCH_QUEUE_SERIAL);
		dispatch_queue_t priority = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
		dispatch_set_target_queue(priority, _cacheInfoQueue);
		
		_frozenCacheInfoQueue = dispatch_queue_create("com.enormego.egocache.info.frozen", DISPATCH_QUEUE_SERIAL);
		priority = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
		dispatch_set_target_queue(priority, _frozenCacheInfoQueue);
		
		_diskQueue = dispatch_queue_create("com.enormego.egocache.disk", DISPATCH_QUEUE_CONCURRENT);
		priority = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
		dispatch_set_target_queue(priority, _diskQueue);
		
		
		_directory = cacheDirectory;

		_cacheInfo = [[NSDictionary dictionaryWithContentsOfFile:cachePathForKey(_directory, @"EGOCache.plist")] mutableCopy];
		
		if(!_cacheInfo) {
			_cacheInfo = [[NSMutableDictionary alloc] init];
		}
    
		[[NSFileManager defaultManager] createDirectoryAtPath:_directory withIntermediateDirectories:YES attributes:nil error:NULL];
		
		NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
		NSMutableArray* removedKeys = [[NSMutableArray alloc] init];
		
		for(NSString* key in _cacheInfo) {
			if([_cacheInfo[key][kdate] timeIntervalSinceReferenceDate] <= now) {
				[[NSFileManager defaultManager] removeItemAtPath:cachePathForKey(_directory, key) error:NULL];
				[removedKeys addObject:key];
			}
		}
		
		[_cacheInfo removeObjectsForKeys:removedKeys];
		 
		self.frozenCacheInfo = _cacheInfo;
        
		[self setDefaultTimeoutInterval:86400 * 100];
	}
	
	return self;
}

+ (BOOL)containsCacheDirectory:(NSString *)cacheDirectory {
    BOOL isDir = YES;
    return [[NSFileManager defaultManager] fileExistsAtPath:[[EGOCache rootCacheDirectory] stringByAppendingPathComponent:cacheDirectory] isDirectory:&isDir];
}

+ (NSString *)rootCacheDirectory {
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
}

- (void)clearCache {
	dispatch_sync(_cacheInfoQueue, ^{
		for(NSString* key in _cacheInfo) {
			[[NSFileManager defaultManager] removeItemAtPath:cachePathForKey(_directory, key) error:NULL];
		}
		
		[_cacheInfo removeAllObjects];
		
		dispatch_sync(_frozenCacheInfoQueue, ^{
			self.frozenCacheInfo = [_cacheInfo copy];
		});

		[self setNeedsSave];
	});
}

- (void)removeCacheForKey:(NSString*)key {
	CHECK_FOR_EGOCACHE_PLIST();

	dispatch_async(_diskQueue, ^{
		[[NSFileManager defaultManager] removeItemAtPath:cachePathForKey(_directory, key) error:NULL];
	});

	[self setCacheTimeoutInterval:0 forKey:key];
}

- (BOOL)hasCacheForKey:(NSString*)key {
    NSDate* date = [self dateForKey:key];
    if(!date) return NO;
	if([date compare:[NSDate date]] != NSOrderedDescending) return NO;
    return [[NSFileManager defaultManager] fileExistsAtPath:cachePathForKey(_directory, key)];
}

- (BOOL)hasCacheInPlistForKey:(NSString *)key {
    NSDate* date = [self dateForKey:key];
    if(!date) return NO;
	if([date compare:[NSDate date]] != NSOrderedDescending) return NO;
    return [_cacheInfo objectForKey:key] ? YES : NO;
}

- (NSDate*)dateForKey:(NSString*)key {
	__block NSDate* date = nil;

	dispatch_sync(_frozenCacheInfoQueue, ^{
		date = (self.frozenCacheInfo)[key][kdate];
	});
    return date;
}

- (NSArray*)allKeys {
    __block NSArray* keys = nil;

    dispatch_sync(_frozenCacheInfoQueue, ^{
        keys = [self.frozenCacheInfo allKeys];
    });

    return keys;
}

- (NSString *)pathForKey:(NSString *)key {
    return cachePathForKey(_directory, key);
}

- (void)setCacheTimeoutInterval:(NSTimeInterval)timeoutInterval forKey:(NSString*)key {
	NSDate* date = timeoutInterval > 0 ? [NSDate dateWithTimeIntervalSinceNow:timeoutInterval] : nil;
	
	[self setExpirationDate:date forKey:key];
}

- (void)setExpirationDate:(NSDate *)expirationDate forKey:(NSString*)key {
	
	// Temporarily store in the frozen state for quick reads
	dispatch_sync(_frozenCacheInfoQueue, ^{
		NSMutableDictionary* info = [self.frozenCacheInfo mutableCopy];
		if(expirationDate) {
            NSMutableDictionary *content = [NSMutableDictionary new];
            if (info[key]) {
                [content setDictionary:info[key]];
            }
			content[kdate] = expirationDate;
            info[key] = content;
		} else {
			[info removeObjectForKey:key];
		}
		
		self.frozenCacheInfo = info;
	});
	
	// Save the final copy (this may be blocked by other operations)
	dispatch_async(_cacheInfoQueue, ^{
		if(expirationDate) {
			NSMutableDictionary *content = [NSMutableDictionary new];
            if (_cacheInfo[key]) {
                [content setDictionary:_cacheInfo[key]];
            }
			content[kdate] = expirationDate;
            _cacheInfo[key] = content;
		} else {
			[_cacheInfo removeObjectForKey:key];
		}
		
		dispatch_sync(_frozenCacheInfoQueue, ^{
			self.frozenCacheInfo = [_cacheInfo copy];
		});
        
		[self setNeedsSave];
	});
}

#pragma mark -
#pragma mark Copy file methods

- (void)copyFilePath:(NSString*)filePath asKey:(NSString*)key {
	[self copyFilePath:filePath asKey:key withTimeoutInterval:self.defaultTimeoutInterval];
}

- (void)copyFilePath:(NSString*)filePath asKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
	dispatch_async(_diskQueue, ^{
		[[NSFileManager defaultManager] copyItemAtPath:filePath toPath:cachePathForKey(_directory, key) error:NULL];
	});
	
	[self setCacheTimeoutInterval:timeoutInterval forKey:key];
}

- (void)copyFilePath:(NSString*)filePath asKey:(NSString*)key withExpirationDate:(NSDate *)expirationDate {
	dispatch_async(_diskQueue, ^{
		[[NSFileManager defaultManager] copyItemAtPath:filePath toPath:cachePathForKey(_directory, key) error:NULL];
	});
	
	[self setExpirationDate:expirationDate forKey:key];
}

#pragma mark -
#pragma mark Data methods

- (void)setData:(NSData*)data forKey:(NSString*)key {
	[self setData:data forKey:key withTimeoutInterval:self.defaultTimeoutInterval];
}

- (void)setData:(NSData*)data forKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
	CHECK_FOR_EGOCACHE_PLIST();
	
	NSString* cachePath = cachePathForKey(_directory, key);
    
    dispatch_async(_diskQueue, ^{
		[data writeToFile:cachePath atomically:YES];
	});
	
	[self setCacheTimeoutInterval:timeoutInterval forKey:key];
}

- (void)setData:(NSData*)data forKey:(NSString*)key withExpirationDate:(NSDate *)expirationDate {
	CHECK_FOR_EGOCACHE_PLIST();
	
	NSString* cachePath = cachePathForKey(_directory, key);
	
	dispatch_async(_diskQueue, ^{
		[data writeToFile:cachePath atomically:YES];
	});
	
	[self setExpirationDate:expirationDate forKey:key];
}

- (void)setNeedsSave {
	dispatch_async(_cacheInfoQueue, ^{
		if(_needsSave) return;
		_needsSave = YES;
		
		double delayInSeconds = 0.5;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, _cacheInfoQueue, ^(void){
			if(!_needsSave) return;
			[_cacheInfo writeToFile:cachePathForKey(_directory, @"EGOCache.plist") atomically:YES];
			_needsSave = NO;
		});
	});
}

- (NSData*)dataForKey:(NSString*)key {
	if([self hasCacheForKey:key]) {
		return [NSData dataWithContentsOfFile:cachePathForKey(_directory, key) options:0 error:NULL];
	} else {
		return nil;
	}
}

#pragma mark -
#pragma mark Image methds

#if TARGET_OS_IPHONE

- (UIImage*)imageForKey:(NSString*)key {
	UIImage* image = nil;
	
	@try {
		image = [NSKeyedUnarchiver unarchiveObjectWithFile:cachePathForKey(_directory, key)];
	} @catch (NSException* e) {
		// Surpress any unarchiving exceptions and continue with nil
	}
	
	return image;
}

- (void)setImage:(UIImage*)anImage forKey:(NSString*)key {
	[self setImage:anImage forKey:key withTimeoutInterval:self.defaultTimeoutInterval];
}

- (void)setImage:(UIImage*)anImage forKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
	@try {
		// Using NSKeyedArchiver preserves all information such as scale, orientation, and the proper image format instead of saving everything as pngs
		[self setData:[NSKeyedArchiver archivedDataWithRootObject:anImage] forKey:key withTimeoutInterval:timeoutInterval];
	} @catch (NSException* e) {
		// Something went wrong, but we'll fail silently.
	}
}

- (void)setImage:(UIImage*)anImage forKey:(NSString*)key withExpirationDate:(NSDate *)expirationDate {
	@try {
		// Using NSKeyedArchiver preserves all information such as scale, orientation, and the proper image format instead of saving everything as pngs
		[self setData:[NSKeyedArchiver archivedDataWithRootObject:anImage] forKey:key withExpirationDate:expirationDate];
	} @catch (NSException* e) {
		// Something went wrong, but we'll fail silently.
	}
}

#else

- (NSImage*)imageForKey:(NSString*)key {
	return [[NSImage alloc] initWithData:[self dataForKey:key]];
}

- (void)setImage:(NSImage*)anImage forKey:(NSString*)key {
	[self setImage:anImage forKey:key withTimeoutInterval:self.defaultTimeoutInterval];
}

- (void)setImage:(NSImage*)anImage forKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
	[self setData:[[[anImage representations] objectAtIndex:0] representationUsingType:NSPNGFileType properties:nil]
		   forKey:key withTimeoutInterval:timeoutInterval];
}

- (void)setImage:(NSImage*)anImage forKey:(NSString*)key withExpirationDate:(NSDate *)expirationDate {
	[self setData:[[[anImage representations] objectAtIndex:0] representationUsingType:NSPNGFileType properties:nil]
		   forKey:key withExpirationDate:expirationDate];
}

#endif

#pragma mark -
#pragma mark Property List methods

- (NSData*)plistForKey:(NSString*)key; {  
	NSData* plistData = [self dataForKey:key];
	
	return [NSPropertyListSerialization propertyListFromData:plistData
											mutabilityOption:NSPropertyListImmutable
													  format:nil
											errorDescription:nil];
}

- (void)setPlist:(id)plistObject forKey:(NSString*)key {
	[self setPlist:plistObject forKey:key withTimeoutInterval:self.defaultTimeoutInterval];
}

- (void)setPlist:(id)plistObject forKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
	// Binary plists are used over XML for better performance
	NSData* plistData = [NSPropertyListSerialization dataFromPropertyList:plistObject 
																   format:NSPropertyListBinaryFormat_v1_0
														 errorDescription:NULL];
	
	[self setData:plistData forKey:key withTimeoutInterval:timeoutInterval];
}

- (void)setPlist:(id)plistObject forKey:(NSString*)key withExpirationDate:(NSDate *)expirationDate {
	// Binary plists are used over XML for better performance
	NSData* plistData = [NSPropertyListSerialization dataFromPropertyList:plistObject
																   format:NSPropertyListBinaryFormat_v1_0
														 errorDescription:NULL];
	
	[self setData:plistData forKey:key withExpirationDate:expirationDate];
}

#pragma mark -
#pragma mark Object methods

- (id<NSCoding>)objectForKey:(NSString*)key {
	if([self hasCacheForKey:key]) {
		return [NSKeyedUnarchiver unarchiveObjectWithData:[self dataForKey:key]];
	} else {
		return nil;
	}
}

- (void)setObject:(id<NSCoding>)anObject forKey:(NSString*)key {
	[self setObject:anObject forKey:key withTimeoutInterval:self.defaultTimeoutInterval];
}

- (void)setObject:(id<NSCoding>)anObject forKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
	[self setData:[NSKeyedArchiver archivedDataWithRootObject:anObject] forKey:key withTimeoutInterval:timeoutInterval];
}

- (void)setObject:(id<NSCoding>)anObject forKey:(NSString*)key withExpirationDate:(NSDate *)expirationDate {
	[self setData:[NSKeyedArchiver archivedDataWithRootObject:anObject] forKey:key withExpirationDate:expirationDate];
}

- (id<NSCoding>)objectFromPlistForKey:(NSString*)key {
    if([self hasCacheInPlistForKey:key]) {
        id savedObject = self.frozenCacheInfo[key][kvalue];
        if ([self objectSupportedByPlist:savedObject]) {
            return savedObject;
        } else if  ([savedObject isKindOfClass:[NSData class]]) {
            return [NSKeyedUnarchiver unarchiveObjectWithData:[self dataForKey:key]];
        } else {
            return nil;
        }
	} else {
		return nil;
	}
}

- (void)setObjectToPlist:(id<NSCoding>)anObject forKey:(NSString*)key {
    [self setObjectToPlist:anObject forKey:key withTimeoutInterval:self.defaultTimeoutInterval];
}

- (void)setObjectToPlist:(id<NSCoding>)anObject forKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
    NSDate* date = timeoutInterval > 0 ? [NSDate dateWithTimeIntervalSinceNow:timeoutInterval] : nil;
    [self setObjectToPlist:anObject forKey:key withExpirationDate:date];
}

- (void)setObjectToPlist:(id<NSCoding>)anObject forKey:(NSString*)key withExpirationDate:(NSDate *)expirationDate {
    dispatch_sync(_frozenCacheInfoQueue, ^{
		NSMutableDictionary* info = [self.frozenCacheInfo mutableCopy];
		if(anObject) {
            NSMutableDictionary *content = [NSMutableDictionary new];
            if (info[key]) {
                [content setDictionary:info[key]];
            }
            if ([self objectSupportedByPlist:anObject] && expirationDate) {
                content[kvalue] = anObject;
            } else {
                content[kvalue] = [NSKeyedArchiver archivedDataWithRootObject:anObject];
            }
            if (expirationDate) content[kdate] = expirationDate;
            info[key] = content;
		} else {
			[info removeObjectForKey:key];
		}
		
		self.frozenCacheInfo = info;
	});
	
	dispatch_async(_cacheInfoQueue, ^{
		if(anObject) {
            NSMutableDictionary *content = [NSMutableDictionary new];
            if (_cacheInfo[key]) {
                [content setDictionary:_cacheInfo[key]];
            }
            if ([self objectSupportedByPlist:anObject] && expirationDate) {
                content[kvalue] = anObject;
            } else {
                content[kvalue] = [NSKeyedArchiver archivedDataWithRootObject:anObject];
            }
            if (expirationDate) content[kdate] = expirationDate;
            _cacheInfo[key] = content;
		} else {
			[_cacheInfo removeObjectForKey:key];
		}
		
		dispatch_sync(_frozenCacheInfoQueue, ^{
			self.frozenCacheInfo = [_cacheInfo copy];
		});
        
		[self setNeedsSave];
	});

}

- (BOOL)objectSupportedByPlist:(id)object {
    return ([object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSNumber class]] || [object isKindOfClass:[NSDate class]] || [object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]]);
}

#pragma mark -

- (void)dealloc {

}

@end
