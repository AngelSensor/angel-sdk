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


#import "ANCharacteristic.h"

#define kFirmwareUpdateControlPointCharacteristicUUIDString @"1761d84e-542a-481d-90e8-6db098bdbb60"

typedef NS_ENUM(UInt8, ANFWOpCode) {
    ANFWOpCodeEraseStagingArea          = 0x01,
    ANFWOpCodeStoreCodeBlock            = 0x02,
    ANFWOpCodeReadCodeBlockCRC          = 0x03,
    ANFWOpCodeInitiateFirmwareUpdate    = 0x04
};

typedef NS_ENUM(UInt8, ANFWResponseCode) {
    ANFWResponseCodeSuccess                         = 0x01,
    ANFWResponseCodeNotSupported                    = 0x02,
    ANFWResponseCodeInvalidOperator                 = 0x03,
    ANFWResponseCodeInvalidCRC                      = 0x04,
    ANFWResponseCodeInvalidCodeBlock                = 0x05,
    ANFWResponseCodeStagingAreaValidationFailure    = 0x06,
    ANFWResponseCodeNotConnectedToCharger           = 0x07,
    ANFWResponseCodeDeviceDisconnected              = 0x08
};

@interface ANFirmwareUpdateConrolPointCharacteristic : ANCharacteristic

@property (nonatomic) ANFWResponseCode  responseCode;
@property (nonatomic) UInt16            responseValue;

//@property (nonatomic, weak) id<ANFirmwareUpdateControlPointCharacteristicDelegate> delegate;

- (void)eraseStagingArea:(UInt16)accessKey;
- (void)writeCodeBlock:(NSData *)codeBlock withAccessKey:(UInt16)accessKey;
- (void)readCRCForCodeBlockAtIndex:(UInt16)index;
- (void)initiateFirmwareUpdateFromStaging:(UInt16)accessKey;

@end
