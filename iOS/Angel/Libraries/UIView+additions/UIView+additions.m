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

#import "UIView+additions.h"

@implementation UIView (additions)

- (void)setOrigin:(CGPoint)origin {
    self.frame = CGRectMake(origin.x, origin.y, self.frame.size.width, self.frame.size.height);
}

- (void)setY:(CGFloat)yValue {
    self.frame = CGRectMake(self.frame.origin.x, yValue, self.frame.size.width, self.frame.size.height);
}

- (void)setX:(CGFloat)xValue {
    self.frame = CGRectMake(xValue, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}

- (void)setCenterX:(CGFloat)xValue {
    self.center = CGPointMake(xValue, self.center.y);
}

- (void)setCenterY:(CGFloat)yValue {
    self.center = CGPointMake(self.center.x, yValue);
}

- (void)setSize:(CGSize)size {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, size.width, size.height);
}

- (void)setHeight:(CGFloat)height {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
}

- (void)setWidth:(CGFloat)width {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, self.frame.size.height);
}

- (CGPoint)getOrigin {
    return self.frame.origin;
}

- (CGFloat)getX {
    return self.frame.origin.x;
}

- (CGFloat)getY {
    return self.frame.origin.y;
}

- (CGSize)getSize {
    return self.frame.size;
}

- (CGFloat)getWidth {
    return self.frame.size.width;
}

- (CGFloat)getHeight {
    return self.frame.size.height;
}

- (UIImage *)screenshot {
    CGFloat scale = [[UIScreen mainScreen] scale];
    UIImage *screenshot;
    
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, scale); {
        if(UIGraphicsGetCurrentContext()) {
            if ([self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
                [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
            } else {
                [self.layer.presentationLayer renderInContext:UIGraphicsGetCurrentContext()];
            }
            screenshot = UIGraphicsGetImageFromCurrentImageContext();
        }
        else {
//            NSLog(@"UIGraphicsGetCurrentContext is nil. You may have a UIView (%@) with no really frame (%@)", [self class], NSStringFromCGRect(self.frame));
        }
    }
    UIGraphicsEndImageContext();
    
    /*if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
     CGSize statusSize = [[UIApplication sharedApplication] statusBarFrame].size;
     return [self imageByCropping:screenshot toRect:CGRectMake(0, statusSize.height * scale, screenshot.size.width * scale, screenshot.size.height * scale - statusSize.height * scale)];
     }*/
    return screenshot;
}


+ (id) loadFromXibNamed:(NSString *) xibName {
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:xibName owner:nil options:nil];
    for(id currentObject in topLevelObjects) {
        if([currentObject isKindOfClass:self]) {
            return currentObject;
        }
    }
    return nil;
}

+ (id) loadFromXib {
    return [self loadFromXibNamed:NSStringFromClass(self)];
}

@end
