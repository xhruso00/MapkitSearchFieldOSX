#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@protocol MyMapViewDelegate <NSObject>
- (void)mapView:(MKMapView *)mapView didChangeLocation:(CLLocation *)location;
@end

@interface MyMapView : MKMapView {
    
}

- (void)setLocation:(CLLocation *)location;

@property (nonatomic, weak) id<MyMapViewDelegate> myDelegate;

@end
