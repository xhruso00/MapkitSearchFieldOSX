#import <Cocoa/Cocoa.h>

@protocol MapDelayedSpinnerDelegate <NSObject>
- (void)spinnerStateChanged;
@end

@interface MapDelayedSpinner : NSProgressIndicator {
@private
    NSDate *_startAnimationDate;
    NSTrackingRectTag _trackingTag;
    BOOL _stopRequested;
    BOOL _startRequested;
}

@property (nonatomic) BOOL spins;
@property (nonatomic, weak) id<MapDelayedSpinnerDelegate> delegate;

- (void)startDelayedAnimation:(id)sender;
- (void)stopDelayedAnimation:(id)sender;

@end
