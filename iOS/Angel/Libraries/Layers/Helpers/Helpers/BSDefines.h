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

#pragma mark - iPhone Device Number


#define IS_IPHONE_5             ([[UIScreen mainScreen] bounds].size.height == 568.0f)
#define IS_IPHONE_6             ([[UIScreen mainScreen] bounds].size.height == 667.f)
#define IS_IPHONE_6_PLUS        ([[UIScreen mainScreen] bounds].size.height == 736.f)
#define IS_IPHONE_5_OR_HIGHER   ([[UIScreen mainScreen] bounds].size.height >= 568.0f)


#pragma mark - iPad Constants

#define IS_IPAD                 (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)


#pragma mark - Screen scale

#define IS_RETINA               ([UIScreen mainScreen].scale >= 2)
#define IS_EXTRA_RETINA         ([UIScreen mainScreen].scale == 3)


#pragma mark - IOS Version

#define SYSTEM_VERSION          ([[[UIDevice currentDevice] systemVersion] floatValue])
#define IOS7                    (7.0 <= SYSTEM_VERSION && SYSTEM_VERSION < 8.0)
#define IOS8                    (8.0 <= SYSTEM_VERSION && SYSTEM_VERSION < 9.0)
#define IOS7_OR_HIGHER          (7.0 <= SYSTEM_VERSION)
#define IOS8_OR_HIGHER          (8.0 <= SYSTEM_VERSION)


#pragma mark - Device Orientation

#define IS_PORTRAIT     UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])

#pragma mark Callbacks

typedef void (^BSCodeBlock)(void);
typedef void (^BSCompletionBlock)(NSError *error);
typedef BOOL (^BSValidationBlock)();
