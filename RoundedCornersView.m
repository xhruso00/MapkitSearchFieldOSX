/*
    File: RoundedCornersView.m
Abstract: A view that draws a rounded rect with the window background. It is used to draw the background for the suggestions window and expose the suggestions to accessibility.
 Version: 1.4

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2012 Apple Inc. All Rights Reserved.

*/

#import "RoundedCornersView.h"


@implementation RoundedCornersView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.material = NSVisualEffectMaterialMenu;
        self.state = NSVisualEffectStateActive;
        self.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        
        CGFloat cornerRadius = [self cornerRadius];
        NSImage *maskImage = [NSImage imageWithSize:NSMakeSize(cornerRadius * 2.0f, cornerRadius * 2.0f) flipped:YES drawingHandler:^BOOL(NSRect dstRect) {
            NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:dstRect xRadius:cornerRadius yRadius:cornerRadius];
            [[NSColor blackColor] setFill];
            [path fill];
            return path;
        }];
        maskImage.capInsets = NSEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius);
        maskImage.resizingMode = NSImageResizingModeStretch;
        
        /// needs to be added as a subview in order to have the corners rounded with cornerRadius
        //self.wantsLayer = YES;
        //self.layer?.cornerRadius = cornerRadius;
        self.maskImage = maskImage;
    }
    return self;
}

- (BOOL)isFlipped {
    return YES;
}

- (CGFloat)cornerRadius
{
    return 10.0f;
}

@end
