#import "SuggestionsTableView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SuggestionsTableView()
@property (nonatomic, strong) NSTrackingArea* cursorTrackingArea;
@end

@implementation SuggestionsTableView

#pragma mark - Event Handling

- (void)mouseMoved:(NSEvent *)event {
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    NSInteger row = [self rowAtPoint:point];

    if (row == -1) {
        [self deselectAll:nil];
        return;
    }

    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:row];
    [self selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (void)mouseExited:(NSEvent *)event {
    /// after clicking on a row, window is dismissed but the event is still fired
    if (self.window == nil || !self.window.isVisible) {
        return;
    }

    [self deselectAll:nil];
    [super mouseExited:event];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];

    if (_cursorTrackingArea != nil) {
        [self removeTrackingArea:_cursorTrackingArea];
    }

    NSTrackingAreaOptions options =
        NSTrackingInVisibleRect |
        NSTrackingMouseMoved |
        NSTrackingActiveInActiveApp |
        NSTrackingMouseEnteredAndExited;

    _cursorTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                       options:options
                                                         owner:self
                                                      userInfo:nil];

    [self addTrackingArea:_cursorTrackingArea];
}

@end

NS_ASSUME_NONNULL_END
