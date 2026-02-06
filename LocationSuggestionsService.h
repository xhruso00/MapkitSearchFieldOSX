#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LocationSuggestionsResult)(NSArray<MKLocalSearchCompletion *> * _Nullable results,
                                          NSError * _Nullable error);

@interface LocationSuggestionsService : NSObject

@property (class, nonatomic, readonly) LocationSuggestionsService *shared;

@property (nonatomic, readonly) NSArray<MKLocalSearchCompletion *>*currentSuggestions;
@property (nonatomic, readonly) NSString *lastSearchString;

- (void)searchString:(NSString *)searchString completion:(LocationSuggestionsResult)completion;
- (void)cancelSearch;

@end
NS_ASSUME_NONNULL_END
