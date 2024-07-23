#import "MapDelayedSpinner.h"

@implementation MapDelayedSpinner

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setStyle:NSProgressIndicatorStyleSpinning];
        [self setDisplayedWhenStopped:NO];
    }
    return self;
}


- (void)drawRect:(NSRect)dirtyRect {
    if ([self spins]) {
        [super drawRect:dirtyRect];
    }
}

- (BOOL)spins
{
    return _startAnimationDate != nil ? YES: NO;
}

- (void)setHidden:(BOOL)hidden
{
    if ([self isHidden] != hidden) {
        [super setHidden:hidden];
        if ([[self delegate] respondsToSelector:@selector(spinnerStateChanged)]) {
            [[self delegate] spinnerStateChanged];
        }
    }
}

- (void)startDelayedAnimation:(id)sender
{
    if (_stopRequested) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopRealAnimation) object:nil];
        _stopRequested = NO;
    } else {
        if (_startRequested) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startRealAnimation) object:nil];
            [self performSelector:@selector(startRealAnimation) withObject:nil afterDelay:1];
            _startRequested = YES;
            
        } else {
            if ([self spins] == NO) {
                [self performSelector:@selector(startRealAnimation) withObject:nil afterDelay:1];
                _startRequested = YES;
            }
        }
    }
}

- (void)stopDelayedAnimation:(id)sender
{
    if (_stopRequested == NO) {
        if (_startRequested) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startRealAnimation) object:nil];
            _startRequested = NO;
        } else {
            if ([self spins]) {
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopRealAnimation) object:nil];
                NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:_startAnimationDate];
                timeInterval = fmax(timeInterval - 0.5, 0);
                [self performSelector:@selector(stopRealAnimation) withObject:nil afterDelay:timeInterval];
                _stopRequested = YES;
            }
        }
    }
}

- (NSView *)hitTest:(NSPoint)point
{
    return nil;
}

- (void)setSpins:(BOOL)spins
{
    if ([self spins] != spins) {
        if (spins) {
            _startAnimationDate = [NSDate date];
        }
        else {
            _startAnimationDate = nil;
        }
    }
}

- (void)mouseEntered:(NSEvent *)event
{
    if ([event trackingNumber] == _trackingTag) {
        [self setHidden:YES];
    }
    if ([NSProgressIndicator instancesRespondToSelector:@selector(mouseEntered:)]) {
        [super mouseEntered:event];
    }
}

- (void)mouseExited:(NSEvent *)event
{
    if ([event trackingNumber] == _trackingTag) {
        [self setHidden:NO];
    }
    if ([NSProgressIndicator instancesRespondToSelector:@selector(mouseExited:)]) {
        [super mouseExited:event];
    }
}

- (void)startRealAnimation
{
    _startRequested = NO;
    [self setHidden:NO];
    _trackingTag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
    
    if ([[self delegate] respondsToSelector:@selector(spinnerStateChanged)]) {
        [[self delegate] spinnerStateChanged];
    }
    [self setSpins:YES];
    [super startAnimation:nil];
    [[self superview] setNeedsLayout:YES];
}

- (void)stopRealAnimation
{
    _stopRequested = NO;
    [self removeTrackingRect:_trackingTag];
    [self setHidden:YES];
    [self setSpins:NO];
    if ([[self delegate] respondsToSelector:@selector(spinnerStateChanged)]) {
        [[self delegate] spinnerStateChanged];
    }
    [super stopAnimation:nil];
    [[self superview] setNeedsLayout:YES];
}

@end
