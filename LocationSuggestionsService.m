#import "LocationSuggestionsService.h"

@interface LocationSuggestionsService () <MKLocalSearchCompleterDelegate>

@property (nonatomic, strong) MKLocalSearchCompleter *completer;
@property (nonatomic, copy, nullable) LocationSuggestionsResult completionHandler;
@property (nonatomic, strong) NSArray<MKLocalSearchCompletion *> *currentSuggestions;
@property (nonatomic, copy) NSString *lastSearchString;

@end

@implementation LocationSuggestionsService

+ (instancetype)shared {
    static LocationSuggestionsService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Use +shared"
                                 userInfo:nil];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _currentSuggestions = @[];
        _lastSearchString = @"";
        
        _completer = [[MKLocalSearchCompleter alloc] init];
        
        _completer.resultTypes = MKLocalSearchCompleterResultTypeAddress | MKLocalSearchCompleterResultTypePointOfInterest;
        
        _completer.region = MKCoordinateRegionForMapRect(MKMapRectWorld);
        _completer.delegate = self;
    }
    return self;
}

#pragma mark - Public API

- (void)searchString:(NSString *)searchString completion:(LocationSuggestionsResult)completion {
    
    NSParameterAssert(searchString.length > 0);
    
    self.completionHandler = completion;
    
    if ([self.completer.queryFragment isEqualToString:searchString]) {
        if (!self.completer.isSearching && completion) {
            completion(self.currentSuggestions, nil);
        }
        return;
    }
    
    [self.completer cancel];
    self.completer.queryFragment = searchString;
    self.lastSearchString = searchString;
}

- (void)cancelSearch {
    [self.completer cancel];
    self.completionHandler = nil;
}

#pragma mark - MKLocalSearchCompleterDelegate

- (void)completerDidUpdateResults:(MKLocalSearchCompleter *)completer {
    if (!self.completionHandler) { return; }
    
    self.currentSuggestions = completer.results;
    self.completionHandler(self.currentSuggestions, nil);
}

- (void)completer:(MKLocalSearchCompleter *)completer didFailWithError:(NSError *)error {
    
    NSLog(@"%@", error);
    
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        if (error.code == NSURLErrorTimedOut ||
            error.code == NSURLErrorNotConnectedToInternet) {
            return;
        }
    }
    
    if ([error.domain isEqualToString:MKErrorDomain]) {
        if (error.code == MKErrorDirectionsNotFound ||
            error.code == MKErrorUnknown) {
            return;
        }
    }
    
    if (self.completionHandler) {
        self.completionHandler(nil, error);
    }
}

#if DEBUG
- (void)completerDidUpdateResults:(MKLocalSearchCompleter *)completer finished:(BOOL)finished {
    
}
#endif

- (void)dealloc {
    _completer.delegate = nil;
    [_completer cancel];
}

@end
