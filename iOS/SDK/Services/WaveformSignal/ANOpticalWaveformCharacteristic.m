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


#import "ANOpticalWaveformCharacteristic.h"

@implementation ANOpticalWaveformCharacteristic

+ (CBUUID *)UUID {
    return [CBUUID UUIDWithString:kOpticalWaveformCharacteristicUUIDString];
}

- (void)processData {
    
    NSData * updatedValue = self.characteristic.value;
    
    if (updatedValue) {
        
        int arrayLength = ([updatedValue length] % 3 == 0) ? (int)[updatedValue length] / 3 : ((int)[updatedValue length] / 3) + 1;
        int integerArray[arrayLength];
        int value = 0;
        for (int i = 0; i < arrayLength; i++) {
            if (([updatedValue length]-(i*3))>=3) {
                //Start form i and length = integer length = 4-bytes
                [updatedValue getBytes:&value range:NSMakeRange(i*3, 3)];
            }else {
                [updatedValue getBytes:&value range:NSMakeRange(i*3, ([updatedValue length]-(i*3)))];
            }
            integerArray[i]= value;
        }
        
        NSMutableArray *wave1Arr = [@[] mutableCopy];
        NSMutableArray *wave2Arr = [@[] mutableCopy];
        for (int i = 0; i < arrayLength; i++) {
            if (i % 2 == 0) {
                [wave1Arr addObject:@(integerArray[i])];
            }
            else {
                [wave2Arr addObject:@(integerArray[i])];
            }
        }
        
        _values = @[wave1Arr, wave2Arr];
//        int arrayLength = ((int)updatedValue.length % 2 == 0) ? (int)updatedValue.length / 2 : ((int)updatedValue.length / 2) + 1;
//        NSMutableArray *integerArray = [@[] mutableCopy];
//        SInt32 value = 0;
        
//        for (int i = 0; i < arrayLength; i++) {
//            if ((updatedValue.length - (i * 2)) >= 2) {
//                //Start form i and length = integer length = 4-bytes
//                [updatedValue getBytes:&value range:NSMakeRange(i * 2, 2)];
//            }
//            else {
//                [updatedValue getBytes:&value range:NSMakeRange(i * 2, (updatedValue.length - (i * 2)))];
//            }
//            integerArray[i]= @(CFSwapInt16LittleToHost(value));
//        }
//        _values = integerArray;
    }
}

@end
