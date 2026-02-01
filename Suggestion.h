#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Suggestion : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, strong) id completion;

- (BOOL)hasSubtitle;

@end

NS_ASSUME_NONNULL_END
