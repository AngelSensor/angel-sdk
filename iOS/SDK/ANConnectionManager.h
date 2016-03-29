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
#import "ANPeripheral.h"
#import "CBUUID+stringExtraction.h"

@class ANConnectionManager;

@protocol ANConnectionDelegate <NSObject>

- (void)connectionManager:(ANConnectionManager *)manager didDiscoverPeripheral:(ANPeripheral *)peripheral;
- (void)connectionManager:(ANConnectionManager *)manager didConnectPeripheral:(ANPeripheral *)peripheral;
- (void)connectionManager:(ANConnectionManager *)manager disconnectedFromPeripheral:(ANPeripheral *)peripheral error:(NSError *)error;
- (void)connectionManager:(ANConnectionManager *)manager didFailConnectingPeripheral:(ANPeripheral *)peripheral error:(NSError *)error;
- (void)connectionManager:(ANConnectionManager *)manager didChangeState:(CBCentralManagerState)state;

@end

@interface ANConnectionManager : NSObject <CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *        centralManager;
@property (nonatomic, weak) id<ANConnectionDelegate>    delegate;
@property (nonatomic, strong) ANPeripheral *            currentPeripheral;
@property (nonatomic, strong) ANPeripheral *            lastSuccessPeripheral; // Used only for background transition
@property (nonatomic, readonly) NSMutableArray *        discoveredPeripherals;
@property (nonatomic, readonly) CBCentralManagerState   state;
@property (nonatomic, readonly) BOOL                    isScanning;

+ (ANConnectionManager *)sharedInstance;

/*!
 * This is a convenice method that is calling -retrievePeripheralsWithIdentifiers:
 * If the return array contains a periphal, it will try to connect it and return YES, even if the connection will fail
 * If the array is empty, the method returns NO and do nothing.
 *
 * @return - YES if a stored peripheral was found, NO if not.
 *
 */
- (BOOL)connectToStoredPeripheralWithUUID:(CBUUID *)UUID;

/**
 * This method is calling -scanForPeripheralsWithServices:options:
 * @param UUIDs - an array of CBUUID objects of the services to scan for.
 **/
- (void)startScanningForPeripheralsWithServiceUUIDs:(NSArray *)UUIDs;

- (void)stopScanning;

- (void)connectPeripheral:(ANPeripheral *)peripheral;
- (void)disconnectPeripheral:(ANPeripheral *)peripheral;


@end
