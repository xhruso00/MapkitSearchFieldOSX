#import <Cocoa/Cocoa.h>
#import <MapKit/MapKit.h>

@interface MapSearchField : NSSearchField  {

}

@property MKLocalSearchCompletion *suggestedCompletion;

@end
