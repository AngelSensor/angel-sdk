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


#import "ANAlarmClockControlPointCharacteristic.h"
#import "NSData+bleDate.h"

@implementation ANAlarmClockControlPointCharacteristic

+ (CBUUID *)UUID {
    return [CBUUID UUIDWithString:kAlarmClockControlPointCharacteristicUUIDString];
}

- (void)processData {
    
    NSData * updatedValue = self.characteristic.value;
    if (updatedValue) {
        uint8_t* dataPointer = (uint8_t *)[updatedValue bytes];
        _responseCode = *(uint8_t *)dataPointer; dataPointer++;
        _responseValue = (uint16_t)CFSwapInt16LittleToHost(*(uint16_t *)dataPointer);
    }
}

- (void)getMaxSupportedAlarms {
    
    ANAlarmClockOpCode opCode = ANAlarmClockOpCodeGetMaxAlarms;
    
    NSData *data = [NSMutableData dataWithBytes:&opCode length:1];
    [self.characteristic.service.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

- (void)getNumberOfAlarmsDefined {
    
    ANAlarmClockOpCode opCode = ANAlarmClockOpCodeGetCurrentAlarms;
    
    NSData *data = [NSMutableData dataWithBytes:&opCode length:1];
    [self.characteristic.service.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

- (void)readAlarm:(UInt8)alarmID {
    
    ANAlarmClockOpCode opCode = ANAlarmClockOpCodeReadAlarm;
    
    NSMutableData *data = [NSMutableData dataWithBytes:&opCode length:1];
    [data appendBytes:&alarmID length:1];
    
    [self.characteristic.service.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

- (void)addAlarm:(NSDate *)date {
    
    ANAlarmClockOpCode opCode = ANAlarmClockOpCodeAddAlarm;
    
    NSMutableData *data = [NSMutableData dataWithBytes:&opCode length:1];
    [data appendData:[NSData dataFromDate:date]];
    
    [self.characteristic.service.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];

}

- (void)removeAlarm:(UInt8)alarmID {
    
    ANAlarmClockOpCode opCode = ANAlarmClockOpCodeRemoveAlarm;
    
    NSMutableData *data = [NSMutableData dataWithBytes:&opCode length:1];
    [data appendBytes:&alarmID length:1];
    
    [self.characteristic.service.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];

}

- (void)removeAllAlarms {
    
    ANAlarmClockOpCode opCode = ANAlarmClockOpCodeRemoveAllAlarms;
    
    NSMutableData *data = [NSMutableData dataWithBytes:&opCode length:1];
    
    [self.characteristic.service.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];

}

- (void)setAlarmClockDateTime:(NSDate *)date {
    
    ANAlarmClockOpCode opCode = ANAlarmClockOpCodeSetClock;
    
    NSMutableData *data = [NSMutableData dataWithBytes:&opCode length:1];
    [data appendData:[NSData dataFromDate:date]];
    
    [self.characteristic.service.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

@end
