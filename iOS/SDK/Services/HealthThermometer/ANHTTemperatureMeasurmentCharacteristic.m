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


#import "ANHTTemperatureMeasurmentCharacteristic.h"


@implementation ANHTTemperatureMeasurmentCharacteristic

+ (CBUUID *)UUID {
    return [CBUUID UUIDWithString:kHealthThermometerTemperatureMeasurmentCharacteristicUUIDString];;
}

- (instancetype)initWithCBCharacteristic:(CBCharacteristic *)characteristic {
    if (self = [super initWithCBCharacteristic:characteristic]) {
        _value = [[ANTemperatureValue alloc] initWithUnit:ANTemperatureUnitCelsius temperature:0 timeStamp:[NSDate date] type:ANTemperatureTypeUnknown];
    }
    return self;
}
- (void)processData {
    
//    [ANHelpers printBitsForData:self.characteristic.value];
    NSData * updatedValue = self.characteristic.value;
    if (updatedValue) {
        uint8_t* dataPointer = (uint8_t*)[updatedValue bytes];
        
        // flags
        uint8_t flags = dataPointer[0];
        dataPointer++;
        
        // temperature
        uint32_t tempData = (uint32_t)CFSwapInt32LittleToHost(*(uint32_t *)dataPointer);
        dataPointer += 4;
        
        int8_t  exponent = (int8_t)(tempData >> 24);
        int32_t mantissa = (int32_t)(tempData & 0x00FFFFFF);
        
        if (tempData == 0x007FFFFF) {
            return;
        }
        
        float tempValue = (float)(mantissa*pow(10, exponent));
        
        ANTemperatureUnit unit = ANTemperatureUnitCelsius;
        ANTemperatureType type = flags & 0x04;
        
        // measurement type
        if(flags & 0x01) {
            unit = ANTemperatureUnitFahrenheit;
        }
        else {
            unit = ANTemperatureUnitCelsius;
        }
        
        // timestamp
        NSDate *date = nil;
        if( flags & 0x02 )
        {
            uint16_t    year =  CFSwapInt16LittleToHost(*(uint16_t*)dataPointer); dataPointer += 2;
            uint8_t     month = *(uint8_t *)dataPointer; dataPointer++;
            uint8_t     day =   *(uint8_t *)dataPointer; dataPointer++;
            uint8_t     hour =  *(uint8_t *)dataPointer; dataPointer++;
            uint8_t     min =   *(uint8_t *)dataPointer; dataPointer++;
            uint8_t     sec =   *(uint8_t *)dataPointer; dataPointer++;
            
            NSString * dateString = [NSString stringWithFormat:@"%d %d %d %d %d %d", year, month, day, hour, min, sec];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat: @"yyyy MM dd HH mm ss"];
            date = [dateFormatter dateFromString:dateString];
        }
        
        _value = [[ANTemperatureValue alloc] initWithUnit:unit temperature:tempValue timeStamp:date type:type];
    }
    else {
        _value = [[ANTemperatureValue alloc] initWithUnit:ANTemperatureUnitCelsius temperature:0 timeStamp:[NSDate date] type:ANTemperatureTypeUnknown];
    }
}

@end


@implementation ANTemperatureValue

- (instancetype)initWithUnit:(ANTemperatureUnit)unit temperature:(Float32)temperature timeStamp:(NSDate *)timeStamp type:(ANTemperatureType)type {
    
    self = [super init];
    if (self) {
        _unit = unit;
        _temperature = temperature;
        _timeStamp = timeStamp;
        _type = type;
    }
    return self;
}

- (NSString *)description {
    NSMutableString *desc = [[super description] mutableCopy];
    [desc appendString:@"\n"];
    [desc appendFormat:@"unit: %@\n", _unit == 0 ? @"Celsius" : @"Fahrenheit"];
    [desc appendFormat:@"temperature: %.1f\n", _temperature];
    [desc appendFormat:@"timeStamp: %@\n", _timeStamp];
    [desc appendFormat:@"type: %d", _type];
    return [desc copy];
}

@end
