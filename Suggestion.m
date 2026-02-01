#import "Suggestion.h"

NS_ASSUME_NONNULL_BEGIN

@implementation Suggestion

- (BOOL)hasSubtitle
{
    return [[self subtitle] length] > 0;
}

@end

NS_ASSUME_NONNULL_END
