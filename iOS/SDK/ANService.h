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


#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CBUUID+stringExtraction.h"
#import "ANPeripheral.h"

@class ANService, ANCharacteristic;

@protocol ANServiceDelegate <NSObject>

- (void)service:(ANService *)service didUpdateValueForCharacterstic:(ANCharacteristic *)characteristic error:(NSError *)error;

@end

@interface ANService : NSObject <CBPeripheralDelegate> {
    
}

@property (nonatomic, weak) id<ANServiceDelegate>   delegate;

@property (nonatomic, readonly) CBService           *service;
@property (nonatomic, readonly) NSArray             *characteristicsUUIDs;

+ (CBUUID *)UUID;

- (instancetype)initWithCBService:(CBService *)service;
- (void)peripheral:(ANPeripheral *)peripheral discoveredCharacteristicsForService:(ANService *)service error:(NSError *)error;
- (void)valueUpdatedForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
- (void)setCharacteristicsNotifyValue:(BOOL)notify;

@end
