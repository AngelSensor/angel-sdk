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


#import "ANFirmwareUpdateConrolPointCharacteristic.h"

@implementation ANFirmwareUpdateConrolPointCharacteristic

+ (CBUUID *)UUID {
    return [CBUUID UUIDWithString:kFirmwareUpdateControlPointCharacteristicUUIDString];
}

- (void)processData {
    
    NSData * updatedValue = self.characteristic.value;
    if (updatedValue) {
        uint8_t* dataPointer = (uint8_t *)[updatedValue bytes];
        _responseCode = *(uint8_t *)dataPointer; dataPointer++;
        _responseValue = (uint16_t)CFSwapInt16LittleToHost(*(uint16_t *)dataPointer);
    
     }
}

- (void)eraseStagingArea:(UInt16)accessKey {

    NSLog(@"eraseStagingArea accessKey %d", accessKey);
    
    ANFWOpCode opCode = ANFWOpCodeEraseStagingArea;

    NSMutableData *data = [NSMutableData dataWithBytes:&opCode length:1];
    [data appendBytes:&accessKey length:2];
    
    [self.characteristic.service.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

- (void)writeCodeBlock:(NSData *)codeBlock withAccessKey:(UInt16)accessKey {
    NSLog(@"writeCodeBlock ");

    ANFWOpCode opCode = ANFWOpCodeStoreCodeBlock;
    
    NSMutableData *data = [NSMutableData dataWithBytes:&opCode length:1];
    [data appendBytes:&accessKey length:2];
    [data appendData:codeBlock];
    [self.characteristic.service.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

- (void)readCRCForCodeBlockAtIndex:(UInt16)index {
    NSLog(@"readCRCForCodeBlockAtIndex");
    ANFWOpCode opCode = ANFWOpCodeReadCodeBlockCRC;
    
    NSMutableData *data = [NSMutableData dataWithBytes:&opCode length:1];
    [data appendBytes:&index length:2];

    [self.characteristic.service.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

- (void)initiateFirmwareUpdateFromStaging:(UInt16)accessKey {
    
    NSLog(@"initiateFirmwareUpdateFromStaging --- key --- %d", accessKey);
   
    ANFWOpCode opCode = ANFWOpCodeInitiateFirmwareUpdate;
    NSMutableData *data = [NSMutableData dataWithBytes:&opCode length:1];
    
    [data appendBytes:&accessKey length:2];
    
    [self.characteristic.service.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Firmware Update Control Point Characteristic: %@", self.characteristic];
}
@end
