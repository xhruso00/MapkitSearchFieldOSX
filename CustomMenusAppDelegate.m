/*
    File: CustomMenusAppDelegate.m
Abstract: This class is responsible for two major activities. It sets up the images in the popup menu (via a custom view) and responds to the menu actions. Also, it supplies the suggestions for the search text field and responds to suggestion selection changes and text field editing.
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

#import "CustomMenusAppDelegate.h"
#import "MapSearchField.h"
#import "MapSearchFieldCell.h"
#import "MyMapView.h"
#import "CLLocation+Additions.h"

@interface CustomMenusAppDelegate ()

@property IBOutlet MyMapView *mapView;
@property MKLocalSearch *localSearch;
@end

@implementation CustomMenusAppDelegate


/* Start off by pointing to Desktop Pictures.
*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
}

#pragma mark -
#pragma mark Suggestions

/* This method is invoked when the user preses return (or enter) on the search text field. We don't want to use the text from the search field as it is just the image filename without a path. Also, it may not be valid. Instead, use this user action to trigger setting the large image view in the main window to the currently suggested URL, if there is one.
*/
- (IBAction)performLocalSearch:(MapSearchField *)sender {
    NSLog(@"%@", sender);
    NSLog(@"%@", [sender suggestedCompletion]);
    NSLog(@"%@", [sender stringValue]);
    MKLocalSearchCompletion *completion = [sender suggestedCompletion];
    if (completion) {
        [[sender cell] startSpinner];
        MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] initWithCompletion:completion];
        MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:request];
        [self setLocalSearch:localSearch];
        [localSearch startWithCompletionHandler:^(MKLocalSearchResponse * _Nullable response, NSError * _Nullable error) {
            [[sender cell] stopSpinner];
            if (error) {
                NSLog(@"%@", error);
            } else {
                MKPlacemark *placemark = [[[response mapItems] firstObject] placemark];
                if (placemark) {
                    CLLocation *location = [CLLocation locationWithCoordinate:placemark.coordinate];
                    [[self mapView] setRegion:[response boundingRegion]];
                    [[self mapView] setPinLocation:location];
                }
            }
        }];
    }
}


@end
