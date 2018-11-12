#import "MyMapView.h"
#import <CoreLocation/CoreLocation.h>

@implementation MyMapView

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (NSMenu *)mapView:(MKMapView *)mapView menuForEvent:(NSEvent *)event
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Map View Menu"];
    CLLocationCoordinate2D coord = [mapView convertPoint:[event locationInWindow] toCoordinateFromView:nil];
//    if (CLLocationCoordinate2DIsValid(coord)) {
//        CLLocation *location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
//        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Drop Pin" action:@selector(dropPin:) keyEquivalent:@""];
//        [item setRepresentedObject:location];
//        [menu addItem:item];
//    }
    return menu;
}

//- (nullable NSMenu *)menuForEvent:(NSEvent *)event
//{
//    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Map View Menu"];
//
//    return menu;
//}

@end
