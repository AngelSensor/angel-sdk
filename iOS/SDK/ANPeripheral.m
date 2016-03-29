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


#import "ANPeripheral.h"

#import "ANHeartRateService.h"
#import "ANDeviceInfoService.h"
#import "ANHealthThermometerService.h"
#import "ANAlarmClockService.h"
#import "ANBloodOxygenService.h"
#import "ANActivityService.h"
#import "ANBatteryService.h"
#import "ANWaveformSignalService.h"

@interface ANPeripheral ()

@property (nonatomic, strong) NSMutableDictionary    *services;
@property (nonatomic, strong) ANWaveformSignalService*  waveformSignalService;
@end

@implementation ANPeripheral

- (instancetype)initWithCBPeripheral:(CBPeripheral *)peripheral {
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _peripheral.delegate = self;
        _services = [@{} mutableCopy];
    }
    return self;
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    for (CBService *service in peripheral.services) {
        
        // create the service
        ANService *anService = [self createANServiceForService:service];
        
        // add the service to the list
        [self.services setValue:anService forKey:[service.UUID getString]];
        
        // notify the delegate
        if (anService && self.delegate && [self.delegate respondsToSelector:@selector(peripheral:didDiscoverService:)]) {
            [self.delegate peripheral:self didDiscoverService:anService];
        }
        
        // search for characteristics
        NSArray *uuids = anService.characteristicsUUIDs;
        [peripheral discoverCharacteristics:uuids forService:service];
    }
    [peripheral readRSSI];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    ANService *aService = self.services[[[service UUID] getString]];
    
    // forward the callback to be handled by the service
    if (aService && [aService respondsToSelector:@selector(peripheral:discoveredCharacteristicsForService:error:)]) {
        [aService peripheral:self discoveredCharacteristicsForService:aService error:error];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(peripheral:discoveredCharacteristicsForService:)]) {
        [_delegate peripheral:self discoveredCharacteristicsForService:aService];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    ANService *aService = self.services[[[characteristic.service UUID] getString]];
    // forward the callback to be handled by the service
    if (aService && [aService respondsToSelector:@selector(peripheral:didDiscoverDescriptorsForCharacteristic:error:)]) {
        [aService peripheral:peripheral didDiscoverDescriptorsForCharacteristic:characteristic error:error];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    ANService *aService = self.services[[[characteristic.service UUID] getString]];
    
    // forward the callback to be handled by the service
    if (aService) {
        [aService valueUpdatedForCharacteristic:characteristic error:error];
    }
    else {
        // the service is not included in our list, doing nothing
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    ANService *aService = self.services[[[descriptor.characteristic.service UUID] getString]];
    
    if (aService && [aService respondsToSelector:@selector(peripheral:didUpdateValueForDescriptor:error:)]) {
        [aService peripheral:peripheral didUpdateValueForDescriptor:descriptor error:error];
    }
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    
    if (_delegate && [_delegate respondsToSelector:@selector(peripheral:didUpdateRSSI:)]) {
        [_delegate peripheral:self didUpdateRSSI:peripheral.RSSI];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [peripheral readRSSI];
    });
}

- (ANService *)createANServiceForService:(CBService *)service {
    
    ANService *anService = nil;
    
    // HEART RATE
    if ([service.UUID isEqual:[ANHeartRateService UUID]]) {
        anService = [[ANHeartRateService alloc] initWithCBService:service];
    }
    // HEALTH THERMOMETER
    else if ([service.UUID isEqual:[ANHealthThermometerService UUID]]) {
        anService = [[ANHealthThermometerService alloc] initWithCBService:service];
    }
    // DEVICE INFO
    else if ([service.UUID isEqual:[ANDeviceInfoService UUID]]) {
        anService = [[ANDeviceInfoService alloc] initWithCBService:service];
    }
    // BLOOD OXYGEN SATURATION
    else if ([service.UUID isEqual:[ANBloodOxygenService UUID]]) {
       // anService = [[ANBloodOxygenService alloc] initWithCBService:service];
    }
    // ACTIVITY
    else if ([service.UUID isEqual:[ANActivityService UUID]]) {
        anService = [[ANActivityService alloc] initWithCBService:service];
    }
    // BATTERY
    else if ([service.UUID isEqual:[ANBatteryService UUID]]) {
        anService = [[ANBatteryService alloc] initWithCBService:service];
    }
    // ALARM CLOCK
    else if ([service.UUID isEqual:[ANAlarmClockService UUID]]) {
        anService = [[ANAlarmClockService alloc] initWithCBService:service];
    }
    // WAVEFORM SIGNAL
    else if ([service.UUID isEqual:[ANWaveformSignalService UUID]]) {
    
        anService = [[ANWaveformSignalService alloc] initWithCBService:service];
        self.waveformSignalService = (ANWaveformSignalService*)anService;
    }
    // UNKNOWN..
    else {
        anService = [[ANService alloc] initWithCBService:service];
    }
    NSLog(@"service: %@", anService.description);
    return anService;
}

#pragma mark Service enable mode handling

- (void)enableServices:(BOOL)enable except:(NSArray *)except {
    for (NSString *key in self.services.allKeys) {
        ANService *service = [self.services objectForKey:key];
        NSString *serviceClass = NSStringFromClass([service class]);
        [service setCharacteristicsNotifyValue: enable ? ![except containsObject:serviceClass] : [except containsObject:serviceClass]];
    }
}

- (void)enabledWaveformSignalService:(BOOL)enable
{
    if (self.waveformSignalService)
    {
        [self.waveformSignalService setCharacteristicsNotifyValue:enable];
    }
}

#pragma mark Temp methods
#pragma warning - ONLY FOR DEV PHASE

- (NSString *)name {
    if (self.peripheral) {
        return self.peripheral.name;
    } else {
        return [NSString stringWithFormat:@"Wristband %@", [self randomStringOfLength:2]];
    }
}

- (NSString *)identifier {
    if (self.peripheral) {
        return self.peripheral.identifier.UUIDString;
    } else {
        return[self randomStringOfLength:16];
    }
}

- (NSString *)randomStringOfLength:(NSInteger)length {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    for (NSInteger i = 0; i < length; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((unsigned int)[letters length]) % [letters length]]];
    }
    return randomString;
}

@end
