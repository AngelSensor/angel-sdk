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


#import "NSData+bleDate.h"

@implementation NSData (bleDate)

- (NSDate *)date {
    
    uint8_t* dataPointer = (uint8_t*)[self bytes];
    uint16_t    year =  CFSwapInt16LittleToHost(*(uint16_t*)dataPointer); dataPointer += 2;
    uint8_t     month = *(uint8_t *)dataPointer; dataPointer++;
    uint8_t     day =   *(uint8_t *)dataPointer; dataPointer++;
    uint8_t     hour =  *(uint8_t *)dataPointer; dataPointer++;
    uint8_t     min =   *(uint8_t *)dataPointer; dataPointer++;
    uint8_t     sec =   *(uint8_t *)dataPointer; dataPointer++;
    
    NSString * dateString = [NSString stringWithFormat:@"%d %d %d %d %d %d", year, month, day, hour, min, sec];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy MM dd HH mm ss"];
    return [dateFormatter dateFromString:dateString];
}

+ (NSData *)dataFromDate:(NSDate *)date {
    
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *components = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:date];
    
    uint16_t    year = (uint16_t)components.year;
    uint8_t     month = (uint8_t)components.month;
    uint8_t     day = (uint8_t)components.day;
    uint8_t     hour = (uint8_t)components.hour;
    uint8_t     min = (uint8_t)components.minute;
    uint8_t     sec = (uint8_t)components.second;
    
    NSMutableData *data = [NSMutableData dataWithBytes:&year length:2];
    [data appendBytes:&month length:1];
    [data appendBytes:&day length:1];
    [data appendBytes:&hour length:1];
    [data appendBytes:&min length:1];
    [data appendBytes:&sec length:1];
    
    return [data copy];
}

@end
