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


#import "ANBatteryLevelCharacteristic.h"
#import "ANUserDescriptionDescriptor.h"
#import "ANClientConfigurationDescriptor.h"

@implementation ANBatteryLevelCharacteristic

+ (CBUUID *)UUID {
    return [CBUUID UUIDWithString:kBatteryLevelCharacteristicUUIDString];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    NSArray *descriptors = [characteristic descriptors];
    CBDescriptor *descriptor;
    
    if (characteristic != self.characteristic) {
        return;
    }
    
    if (error != nil) {
        return;
    }
    
    for (descriptor in descriptors) {
        if ([[descriptor UUID] isEqual:[ANUserDescriptionDescriptor UUID]]) {
            _userDescriptionDescriptor = [[ANUserDescriptionDescriptor alloc] initWithCBDescriptor:descriptor];
            [peripheral readValueForDescriptor:descriptor];
            
        }
        else if ([[descriptor UUID] isEqual:[ANClientConfigurationDescriptor UUID]]) {
            _clientConfigurationDescriptor = [[ANClientConfigurationDescriptor alloc] initWithCBDescriptor:descriptor];
            [peripheral readValueForDescriptor:descriptor];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    
    ANDescriptor *aDescriptor = [self getANDescriptor:descriptor];
    [aDescriptor processData];
}

- (ANDescriptor *)getANDescriptor:(CBDescriptor *)descriptor {
    
    if ([descriptor.UUID isEqual:[ANClientConfigurationDescriptor UUID]]) {
        return self.clientConfigurationDescriptor;
    }
    else if ([descriptor.UUID isEqual:[ANUserDescriptionDescriptor UUID]]) {
        return self.userDescriptionDescriptor;
    }
    
    return nil;
}

- (void)valueUpdatedForDescriptor:(CBDescriptor *)descriptor {
    ANDescriptor *aDescriptor = [self getANDescriptor:descriptor];
    [aDescriptor processData];
}

- (void)processData {
    NSData * updatedValue = self.characteristic.value;
    if (updatedValue) {
        const uint8_t *bytes = [updatedValue bytes];
        _level = bytes[0];        
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Battery Level Characteristic: %@", self.characteristic];
}
@end
