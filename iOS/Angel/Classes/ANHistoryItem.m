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


#import "ANHistoryItem.h"

#define DEFAULT_RANGE_INTERVAL 60

@implementation ANHistoryItem

- (NSDictionary *)rangeItems {
    if (!_rangeItems) {
        _rangeItems = @{@(ANHistoryRecordTypeTemperature) : [NSMutableArray new],
                        @(ANHistoryRecordTypeHeartRate) : [NSMutableArray new],
                        @(ANHistoryRecordTypeOxygen) : [NSMutableArray new],
                        @(ANHistoryRecordTypeSteps) : [NSMutableArray new],
                        @(ANHistoryRecordTypeOpticalWaveform1) : [NSMutableArray new],
                        @(ANHistoryRecordTypeOpticalWaveform2) : [NSMutableArray new],
                        @(ANHistoryRecordTypeAccelerometer) : [NSMutableArray new]};
    }
    return _rangeItems;
}

- (void)addRecord:(ANHistoryRecord *)record {
    NSMutableArray *container = [self.rangeItems objectForKey:@(record.recordType)];
    if (container) {
        NSMutableArray *range = [container lastObject];
        if (!range) {
            range = [NSMutableArray new];
            [container addObject:range];
        }
        ANHistoryRecord *lastRecord = [range lastObject];
        if (lastRecord) {
            if (fabs([record.recordTimestamp timeIntervalSinceDate:lastRecord.recordTimestamp]) > DEFAULT_RANGE_INTERVAL) {
                NSMutableArray *newRange = [NSMutableArray new];
                [newRange addObject:record];
                [container addObject:newRange];
            } else {
                [range addObject:record];
            }
        } else {
            [range addObject:record];
        }
    }
    double value = record.recordValue.doubleValue;
    switch (record.recordType) {
        case ANHistoryRecordTypeHeartRate: {
            if (!self.minHeartNumber || (value < self.minHeartNumber.doubleValue)) {
                self.minHeartNumber = @(value);
            }
            if (!self.maxHeartNumber || (value > self.maxHeartNumber.doubleValue)) {
                self.maxHeartNumber = @(value);
            }
        } break;
        case ANHistoryRecordTypeSteps: {
            self.stepsNumber = self.stepsNumber ?  @(self.stepsNumber.doubleValue + value) : @(value);
        } break;
        case ANHistoryRecordTypeEnergy: {
            self.energyNumber = self.energyNumber ?  @(self.energyNumber.doubleValue + value) : @(value);
        } break;
        default:
            break;
    }
}

- (void)removeItemsForType:(ANHistoryRecordType)type {
    [[self.rangeItems objectForKey:@(type)] removeAllObjects];
}

- (void)removeAllItems {
    for (NSMutableArray *items in self.rangeItems.allValues) {
        [items removeAllObjects];
    }
}

- (NSDate *)startDateForType:(ANHistoryRecordType)type {
    ANHistoryRecord *firstRecord = [[[self.rangeItems objectForKey:@(type)] firstObject] firstObject];
    return firstRecord.recordTimestamp;
}

- (NSDate *)endDateForType:(ANHistoryRecordType)type {
    ANHistoryRecord *lastRecord = [[[self.rangeItems objectForKey:@(type)] lastObject] lastObject];
    return lastRecord.recordTimestamp;
}

@end
