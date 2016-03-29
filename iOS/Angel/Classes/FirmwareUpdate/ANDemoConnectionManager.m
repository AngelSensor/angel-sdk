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


#import "ANDemoConnectionManager.h"
#import "ANDemoPeripheral.h"

@implementation ANDemoConnectionManager

+ (ANConnectionManager *)sharedInstance {
    static ANDemoConnectionManager *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[ANDemoConnectionManager alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self ) {
        
    }
    return self;
}

- (BOOL)connectToStoredPeripheralWithUUID:(CBUUID *)UUID {
    NSArray *peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:@[UUID]];
    
    // found, trying to connect
    if (peripherals.count) {
        CBPeripheral *peripheral = peripherals[0];
        self.currentPeripheral = [[ANDemoPeripheral alloc] initWithCBPeripheral:peripheral];
        [self.centralManager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey : @(YES)}];
        return YES;
    }
    
    return NO;
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    /* Add only Angel peripherals */
    if ([[peripheral.name lowercaseString] hasPrefix:@"angel"]) {
        ANPeripheral *anPeripheral = [[ANDemoPeripheral alloc] initWithCBPeripheral:peripheral];
        [self.discoveredPeripherals addObject:anPeripheral];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(connectionManager:didDiscoverPeripheral:)]) {
            [self.delegate connectionManager:self didDiscoverPeripheral:anPeripheral];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {

    self.currentPeripheral = [[ANDemoPeripheral alloc] initWithCBPeripheral:peripheral];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectionManager:didConnectPeripheral:)]) {
        [self.delegate connectionManager:self didConnectPeripheral:self.currentPeripheral];
    }
    
    [peripheral discoverServices:nil];
}

@end
