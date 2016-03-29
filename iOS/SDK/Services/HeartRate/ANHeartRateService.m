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


#import "ANHeartRateService.h"
#import "ANBodySensorLocationCharacteristic.h"
#import "ANHRMeasurmentCharacteristic.h"
#import "ANHRControlPointCharacteristic.h"

@interface ANHeartRateService() {
    
}

@end


@implementation ANHeartRateService

- (instancetype)initWithCBService:(CBService *)service {
    
    self = [super initWithCBService:service];
    if (self) {
        
    }
    return self;
}

+ (CBUUID *)UUID {
    return [CBUUID UUIDWithString:kHeartRateServiceUUIDString];;
}

- (NSArray *)characteristicsUUIDs {
    return @[[ANBodySensorLocationCharacteristic UUID],
             [ANHRMeasurmentCharacteristic UUID],
             [ANHRControlPointCharacteristic UUID]];
}

- (void)peripheral:(ANPeripheral *)peripheral discoveredCharacteristicsForService:(ANService *)service error:(NSError *)error {
    
    NSArray *characteristics = [service.service characteristics];
	CBCharacteristic *characteristic;
    
	if (service.service != self.service) {
		return ;
	}
    
    if (error != nil) {
		return ;
	}
    
	for (characteristic in characteristics) {
        
		if ([[characteristic UUID] isEqual:[ANHRMeasurmentCharacteristic UUID]]) {
            _heartRateChar = [[ANHRMeasurmentCharacteristic alloc] initWithCBCharacteristic:characteristic];
            [peripheral.peripheral setNotifyValue:YES forCharacteristic:characteristic];
		}
        else if ([[characteristic UUID] isEqual:[ANBodySensorLocationCharacteristic UUID]]) {
            _locationChar = [[ANBodySensorLocationCharacteristic alloc] initWithCBCharacteristic:characteristic];
			[peripheral.peripheral readValueForCharacteristic:characteristic];
		}
        else if ([[characteristic UUID] isEqual:[ANHRControlPointCharacteristic UUID]]) {
            _controlPointChar = [[ANHRControlPointCharacteristic alloc] initWithCBCharacteristic:characteristic];
		}
	}
}

- (void)setCharacteristicsNotifyValue:(BOOL)notify {
    if (_heartRateChar && _heartRateChar.characteristic) {
        [self.service.peripheral setNotifyValue:notify forCharacteristic:_heartRateChar.characteristic];
    }
}

- (void)valueUpdatedForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    ANCharacteristic *aCharacteristic = [self getANCharacteristic:characteristic];
    [aCharacteristic processData];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(service:didUpdateValueForCharacterstic:error:)]) {
        [self.delegate service:self didUpdateValueForCharacterstic:aCharacteristic error:error];
    }
}

- (ANCharacteristic *)getANCharacteristic:(CBCharacteristic *)characteristic {
    
    if ([characteristic.UUID isEqual:[ANHRMeasurmentCharacteristic UUID]]) {
        return self.heartRateChar;
    }
    else if ([characteristic.UUID isEqual:[ANBodySensorLocationCharacteristic UUID]]) {
        return self.locationChar;
    }
    else if ([characteristic.UUID isEqual:[ANHRControlPointCharacteristic UUID]]) {
        return self.controlPointChar;
    }
    
    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Heart Rate service: %@", self.service];
}
@end
