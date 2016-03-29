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


#import "ANHistoryManager.h"
#import "ANHistoryRecord.h"
#import "NSDate+Utilities.h"
#import "FMDB.h"

#define DATABASE_NAME @"history.db"
#define DATABASE_LIMIT 1000

@interface ANHistoryManager ()

@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, strong) NSArray *databaseCache;

@end

@implementation ANHistoryManager

#pragma mark Initialization

- (id)init {
    self = [super init];
    if (self) {
    
    }
    return self;
}

+ (id)sharedManager {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark Database connection handling

- (FMDatabaseQueue *)databaseQueue {
    @synchronized(self) {
        if (!_databaseQueue) {
            _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:[self filePath:DATABASE_NAME]];
            [_databaseQueue inDatabase:^(FMDatabase *db) {
                #warning remove on prod
//                [db executeUpdate:@"DROP TABLE records"];
                [db executeUpdate:@"CREATE TABLE IF NOT EXISTS records (id INTEGER NOT NULL, type INTEGER NOT NULL, value NUMERIC(25), timestamp NUMERIC(13) NOT NULL, date NUMERIC(13) NOT NULL, PRIMARY KEY (id))"];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS columns ON records (type, timestamp, date)"];
            }];
        }
        return _databaseQueue;
    }
}

- (void)closeDatabase {
    @synchronized(self) {
        if (_databaseQueue) {
            [_databaseQueue close];
            _databaseQueue = nil;
        }
    }
}

#pragma mark Record from result

- (ANHistoryRecord *)recordFromResultSet:(FMResultSet *)resultSet {
    ANHistoryRecord *record = [[ANHistoryRecord alloc] init];
    record.recordType = [resultSet intForColumnIndex:0];
    record.recordValue = @([resultSet doubleForColumnIndex:1]);
    record.recordTimestamp = [NSDate dateWithTimeIntervalSince1970:([resultSet longLongIntForColumnIndex:2] / 1000)];
    return record;
}

#pragma mark Loading data handling

- (void)loadDatabaseWithCompletionHandler:(void (^)(NSArray *result, NSError *error))handler {
    //if (!self.databaseCache) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.databaseQueue inDatabase:^(FMDatabase *db) {
//            NSDate *start = [NSDate date];
            NSMutableArray *result = [[NSMutableArray alloc] init];
            FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT type, value, timestamp FROM records ORDER BY timestamp LIMIT %d", DATABASE_LIMIT];
            while ([resultSet next]) {
                ANHistoryRecord *record = [self recordFromResultSet:resultSet];
                if (record) {
                    [result addObject:record];
                }
            }
            [resultSet close];
            self.databaseCache = result;
//            NSLog(@"Loading execution time %f", [[NSDate date] timeIntervalSinceDate:start]);
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(result, nil);
                });
            }
        }];
    });
    /*} else {
        if (handler) {
            handler(self.databaseCache, nil);
        }
    }*/
}

#pragma mark Adding/removing data handling

- (void)addRecord:(ANHistoryRecord *)record uniquePerDay:(BOOL)uniquePerDay completionHandler:(void (^)(BOOL success, NSError *error))handler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.databaseQueue inDatabase:^(FMDatabase *db) {
            void (^innerCompletionHandler)(BOOL res) = ^(BOOL res){
                if (handler) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        handler(res, res ? nil : db.lastError);
                    });
                }
            };
            void (^executeUpdate)(NSInteger) = ^(NSInteger recordID){
                BOOL res = [db executeUpdate:@"UPDATE records SET value = (?), timestamp = (?) WHERE id = (?)", record.recordValue, @([record.recordTimestamp milliseconds]), @(recordID)];
                innerCompletionHandler(res);
            };
            void (^executeInsert)(void) = ^{
                BOOL res = [db executeUpdate:@"INSERT INTO records (type, value, timestamp, date) VALUES (?, ?, ?, ?)", @(record.recordType), record.recordValue, @([record.recordTimestamp milliseconds]), @([record.recordTimestamp millisecondsAtStartOfDay])];
                innerCompletionHandler(res);
            };
            if (uniquePerDay) {
                FMResultSet *resultSet = [db executeQuery:@"SELECT id FROM records WHERE date = (?) AND type = (?) LIMIT 1", @([record.recordTimestamp millisecondsAtStartOfDay]), @(record.recordType)];
                if ([resultSet next]) {
                    NSInteger recordID = [resultSet intForColumnIndex:0];
                    executeUpdate(recordID);
                } else {
                    executeInsert();
                }
                [resultSet close];
            } else {
                FMResultSet *resultSet = [db executeQuery:@"SELECT id FROM records WHERE timestamp = (?) AND type = (?) LIMIT 1", @([record.recordTimestamp milliseconds]), @(record.recordType)];
                if ([resultSet next]) {
                    innerCompletionHandler(NO);
                } else {
                    executeInsert();
                }
                [resultSet close];
            }
        }];
    });
}

- (void)addRecord:(ANHistoryRecord *)record completionHandler:(void (^)(BOOL success, NSError *error))handler {
    [self addRecord:record uniquePerDay:NO completionHandler:handler];
}

- (void)addUniquePerDayRecord:(ANHistoryRecord *)record completionHandler:(void (^)(BOOL, NSError *))handler {
    [self addRecord:record uniquePerDay:YES completionHandler:handler];
}

- (void)removeRecord:(ANHistoryRecord *)record completionHandler:(void (^)(BOOL success, NSError *error))handler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.databaseQueue inDatabase:^(FMDatabase *db) {
            BOOL res = [db executeUpdate:@"DELETE FROM records WHERE type = (?) AND date = (?) AND timestamp = (?)", @(record.recordType), @([record.recordTimestamp millisecondsAtStartOfDay]), @([record.recordTimestamp milliseconds])];
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(res, res ? nil : db.lastError);
                });
            }
        }];
    });
}

#pragma mark Misc methods

- (NSString *)filePath:(NSString *)fileName {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [documentsPath stringByAppendingPathComponent:fileName];
}
- (BOOL)fileExists:(NSString *)fileName {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self filePath:fileName]];
}

@end
