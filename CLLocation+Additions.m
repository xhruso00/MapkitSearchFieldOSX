#import "CLLocation+Additions.h"

@implementation CLLocation(Additions)

+ (instancetype)locationWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    return location;
}

@end
