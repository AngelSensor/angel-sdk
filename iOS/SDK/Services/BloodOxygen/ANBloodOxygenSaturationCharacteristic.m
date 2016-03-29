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


#import "ANBloodOxygenSaturationCharacteristic.h"

@interface ANBloodOxygenSaturationCharacteristic()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation ANBloodOxygenSaturationCharacteristic

+ (CBUUID *)UUID {
    return [CBUUID UUIDWithString:kBloodOxygenSaturationCharacteristicUUIDString];
}

- (instancetype)initWithCBCharacteristic:(CBCharacteristic *)characteristic {
    if (self = [super initWithCBCharacteristic:characteristic]) {
        _value = [[ANOxygenValue alloc] initWithOxygenLevel:0 timeStamp:[NSDate date]];
    }
    return self;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

- (void)processData {
    
    NSData * updatedValue = self.characteristic.value;
    if (updatedValue) {
        uint8_t* dataPointer = (uint8_t *)[updatedValue bytes];
        
        // blood oxygen saturation
        int32_t tempData = (int32_t)CFSwapInt32LittleToHost(* (uint32_t *)dataPointer);
        dataPointer += 4;
        
        int8_t  exponent = (int8_t)(tempData >> 24);
        int32_t mantissa = (int32_t)(tempData & 0x00FFFFFF);
        
        float oxygenLevel = (float)(mantissa * pow(10, exponent));
        
        // timestamp
        uint16_t    year =  CFSwapInt16LittleToHost(* (uint16_t *)dataPointer); dataPointer += 2;
        uint8_t     month = *(uint8_t *)dataPointer; dataPointer++;
        uint8_t     day =   *(uint8_t *)dataPointer; dataPointer++;
        uint8_t     hour =  *(uint8_t *)dataPointer; dataPointer++;
        uint8_t     min =   *(uint8_t *)dataPointer; dataPointer++;
        uint8_t     sec =   *(uint8_t *)dataPointer; dataPointer++;
        
        NSString * dateString = [NSString stringWithFormat:@"%d %d %d %d %d %d", year, month, day, hour, min, sec];
        
        [self.dateFormatter setDateFormat: @"yyyy MM dd HH mm ss"];
        NSDate *date = [self.dateFormatter dateFromString:dateString];
        
        _value = [[ANOxygenValue alloc] initWithOxygenLevel:oxygenLevel timeStamp:date];
    }
    else {
        _value = [[ANOxygenValue alloc] initWithOxygenLevel:0 timeStamp:[NSDate date]];
    }
}

@end

@implementation ANOxygenValue

- (instancetype)initWithOxygenLevel:(Float32)level timeStamp:(NSDate *)timeStamp {
    self = [super init];
    if (self) {
        _oxygenLevel = level;
        _timeStamp = timeStamp;
    }
    return self;
}

- (NSString *)description {
    NSMutableString *desc = [[super description] mutableCopy];
    [desc appendString:@"\n"];
    [desc appendFormat:@"value: %.1f\n", _oxygenLevel];
    [desc appendFormat:@"timeStamp: %@\n", _timeStamp];
    return [desc copy];
}

@end
