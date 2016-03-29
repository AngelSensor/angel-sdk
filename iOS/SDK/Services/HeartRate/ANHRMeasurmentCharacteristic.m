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


#import "ANHRMeasurmentCharacteristic.h"

@implementation ANHRMeasurmentCharacteristic

+ (CBUUID *)UUID {
    return [CBUUID UUIDWithString:kHeartRateMeasurmentCharacteristicUUIDString];;
}

- (instancetype)initWithCBCharacteristic:(CBCharacteristic *)characteristic {
    if ([super initWithCBCharacteristic:characteristic]) {
        _heartRate = 0;
    }
    return self;
}

- (void)processData {
    
    if (!self.characteristic.value) {
        return;
    }
    const uint8_t *reportData = [self.characteristic.value bytes];
    
    // heart rate value format
    uint16_t bpm = 0;
    if ((reportData[0] & 0x01) == 0) {
        bpm = reportData[1]; /* uint8 */
    }
    else {
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1])); /* uint16 */
    }
    _heartRate = bpm;
    
    // Energy Expended
    if ((reportData[0] & (1 << 3))) {
        //TODO: missing implementation
    }
    
    // RR Interval value
    if ((reportData[0] & (1 << 4))) {
        //TODO: missing implementation
    }
    
//    [ANHelpers printBitsForData:self.characteristic.value];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Heart Rate Measurement Characteristic: %@", self.characteristic];
}
@end
