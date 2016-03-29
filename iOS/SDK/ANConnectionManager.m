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


#import "ANConnectionManager.h"
#import "ANDemoConnectionManager.h"

@interface ANConnectionManager()

@property (nonatomic, strong) NSMutableArray *discoveredPeripherals;

@end

@implementation ANConnectionManager 

+ (ANConnectionManager *)sharedInstance {
    static ANConnectionManager *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[ANConnectionManager alloc] init];
    });
    return _sharedInstance;
}

- (CBCentralManagerState)state {
    return _centralManager.state;
}

- (instancetype)init {
    self = [super init];
    if (self ) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        _discoveredPeripherals = [@[] mutableCopy];
    }
    return self;
}

- (BOOL)connectToStoredPeripheralWithUUID:(CBUUID *)UUID {
    NSArray *peripherals = [_centralManager retrievePeripheralsWithIdentifiers:@[UUID]];
    
    // found, trying to connect
    if (peripherals.count) {
        CBPeripheral *peripheral = peripherals[0];
        self.currentPeripheral = [[ANPeripheral alloc] initWithCBPeripheral:peripheral];
        [_centralManager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey : @(YES)}];
        return YES;
    }
    
    return NO;
}

- (void)startScanningForPeripheralsWithServiceUUIDs:(NSArray *)serviceUUIDs {
    if (_centralManager.state == CBCentralManagerStatePoweredOn) {
        _isScanning = YES;
        [_centralManager scanForPeripheralsWithServices:nil options:nil];
    }
}

- (void)stopScanning {
    [_centralManager stopScan];
    _isScanning = NO;
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    /* Add only Angel peripherals */
    if ([[peripheral.name lowercaseString] hasPrefix:@"angel"]) {
        ANPeripheral *anPeripheral = [[ANPeripheral alloc] initWithCBPeripheral:peripheral];
        [_discoveredPeripherals addObject:anPeripheral];
        
        if (_delegate && [_delegate respondsToSelector:@selector(connectionManager:didDiscoverPeripheral:)]) {
            [_delegate connectionManager:self didDiscoverPeripheral:anPeripheral];
        }
    }
}

- (void)connectPeripheral:(ANPeripheral *)peripheral {
    self.currentPeripheral = peripheral;
    [self.centralManager connectPeripheral:peripheral.peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey : @(YES)}];
}

- (void)disconnectPeripheral:(ANPeripheral *)peripheral {
    if (peripheral && peripheral.peripheral) {
        [self.centralManager cancelPeripheralConnection:peripheral.peripheral];
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if (_delegate && [_delegate respondsToSelector:@selector(connectionManager:didChangeState:)]) {
        [_delegate connectionManager:self didChangeState:central.state];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {

    self.currentPeripheral = [[ANPeripheral alloc] initWithCBPeripheral:peripheral];
    
    if (_delegate && [_delegate respondsToSelector:@selector(connectionManager:didConnectPeripheral:)]) {
        [_delegate connectionManager:self didConnectPeripheral:self.currentPeripheral];
    }
    
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"central failed to connect to peripheral");
    if (_delegate && [_delegate respondsToSelector:@selector(connectionManager:didFailConnectingPeripheral:error:)] && self.currentPeripheral.peripheral == peripheral) {
        [_delegate connectionManager:self didFailConnectingPeripheral:self.currentPeripheral error:error];
    }
    self.currentPeripheral = nil;
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPeripheralDisconnected object:nil userInfo:@{}];
    NSLog(@"peripheral disconnected");
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectionManager:disconnectedFromPeripheral:error:)]) {
        [self.delegate connectionManager:self disconnectedFromPeripheral:self.currentPeripheral error:error];
    }
    self.currentPeripheral = nil;
}

@end
