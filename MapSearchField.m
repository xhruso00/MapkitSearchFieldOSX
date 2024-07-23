#import "MapSearchField.h"
#import <MapKit/MapKit.h>
#import "SuggestionsWindowController.h"
#import "MapSearchFieldCell.h"
#import "MapDelayedSpinner.h"

@interface MapSearchField() <MKLocalSearchCompleterDelegate, NSSearchFieldDelegate, NSTextFieldDelegate> {
@private
    SuggestionsWindowController *_suggestionsController;
    NSString *_userTypedString;
}
@property (strong) MKLocalSearchCompleter *searchCompleter;
@property (strong) MKLocalSearch *localSearch;
@property (nonatomic, strong) NSArray <MKLocalSearchCompletion*>*searchAutocompletions;
@property BOOL skipNextSuggestion;

@end



@implementation MapSearchField

- (void)awakeFromNib
{
    [super awakeFromNib];
    MapDelayedSpinner *spinner = [[MapDelayedSpinner alloc] initWithFrame:NSMakeRect(CGRectGetMaxX([self bounds]) - 22,
                                                                                     CGRectGetMinY([self bounds]) + 1,
                                                                                     22, 22)];
    [self addSubview:spinner];
    [[self cell] setSpinner:spinner];
}

//+ (Class)cellClass
//{
//    return [MapSearchField class];
//}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _userTypedString = @"";
    MKLocalSearchCompleter *searchCompleter = [[MKLocalSearchCompleter alloc] init];
    searchCompleter.resultTypes = MKLocalSearchCompleterResultTypeAddress|MKLocalSearchCompleterResultTypePointOfInterest;
    searchCompleter.delegate = self;
    [self setSearchCompleter:searchCompleter];
    [self setDelegate:self];
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    if ([[self cell] respondsToSelector:@selector(updateSpinnerFrame)]) {
        [(MapSearchFieldCell *)[self cell] updateSpinnerFrame];
    }
}

#pragma mark -
#pragma mark Suggestions

/* This method is invoked when the user preses return (or enter) on the search text field. We don't want to use the text from the search field as it is just the image filename without a path. Also, it may not be valid. Instead, use this user action to trigger setting the large image view in the main window to the currently suggested URL, if there is one.
 */
- (IBAction)performLocalSearch:(id)sender {
    NSImage *image = nil;
    if(_suggestedCompletion) {
        //image = [[NSImage alloc] initWithContentsOfURL:_suggestedURL];
    }
}

/* This is the action method for when the user changes the suggestion selection. Note, this action is called continuously as the suggestion selection changes while being tracked and does not denote user committal of the suggestion. For suggestion committal, the text field's action method is used (see above). This method is wired up programatically in the -controlTextDidBeginEditing: method below.
 */
- (IBAction)updateWithSelectedSuggestion:(id)sender {
    NSDictionary *entry = [sender selectedSuggestion];
    if (entry) {
        _suggestedCompletion = [entry objectForKey:kSuggestionCompletion];
        NSText *fieldEditor = [self.window fieldEditor:NO forObject:self];
        if (fieldEditor) {
            [self updateFieldEditor:fieldEditor withSuggestion:[entry objectForKey:kSuggestionLabel]];
        }
    } else {
        NSText *fieldEditor = [self.window fieldEditor:NO forObject:self];
        if (fieldEditor) {
            [self updateFieldEditor:fieldEditor withSuggestion:_userTypedString];
        }
    }
    
}

/* Recursively search through all the image files starting at the _baseURL for image file names that begin with the supplied string. It returns an array of NSDictionaries. Each dictionary contains a label, detailed label and an url with keys that match the binding used by each custom suggestion view defined in suggestionprototype.xib.
 */
- (NSArray *)suggestionsForText:(NSString*)text {
    // We don't want to hit the disk every time we need to re-calculate the the suggestion list. So we cache the result from disk. If we really wanted to be fancy, we could listen for changes to the file system at the _baseURL to know when the cache is out of date.
    
    // Search the known image URLs array for matches.
    NSMutableArray *suggestions = [NSMutableArray arrayWithCapacity:1];
    NSArray<MKLocalSearchCompletion *> *results = [[self searchCompleter] results];
    
    for (MKLocalSearchCompletion *completion in results) {
        NSString *title = [completion title] ? : @"";
        NSString *subtitle = [completion subtitle] ? : @"";
        NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                               title, kSuggestionLabel,
                               subtitle, kSuggestionDetailedLabel,
                               completion, kSuggestionCompletion,
                               [NSNull null], kSuggestionImage,
                               nil];
        [suggestions addObject:entry];
        
    }
    
    return suggestions;
}

/* Update the field editor with a suggested string. The additional suggested characters are auto selected.
 */
- (void)updateFieldEditor:(NSText *)fieldEditor withSuggestion:(NSString *)suggestion {
//    if (suggestion == nil){
//        [fieldEditor delete:self];
//    } else {
        NSRange selection = NSMakeRange([fieldEditor selectedRange].location, [suggestion length]);
        [fieldEditor setString:suggestion];
        [fieldEditor setSelectedRange:selection];
//    }
}

/* Determines the current list of suggestions, display the suggestions and update the field editor.
 */
- (void)updateSuggestionsFromControl:(NSControl *)control {
    NSText *fieldEditor = [self.window fieldEditor:NO forObject:control];
    if (fieldEditor) {
        // Only use the text up to the caret position
        //NSRange selection = [fieldEditor selectedRange];
        //NSString *text = [[fieldEditor string] substringToIndex:selection.location];
        NSString *text = _userTypedString;
        if ([text length]) {
            [[self searchCompleter] cancel];
            [[self searchCompleter] setQueryFragment:text];
        }
    }
}

/* In interface builder, we set this class object as the delegate for the search text field. When the user starts editing the text field, this method is called. This is an opportune time to display the initial suggestions.
 */
- (void)controlTextDidBeginEditing:(NSNotification *)notification {
    // We keep the suggestionsController around, but lazely allocate it the first time it is needed.
    if (!_suggestionsController) {
        _suggestionsController = [[SuggestionsWindowController alloc] init];
        _suggestionsController.target = self;
        _suggestionsController.action = @selector(updateWithSelectedSuggestion:);
    }
    
    [self updateSuggestionsFromControl:notification.object];
}

- (void)textDidChange:(NSNotification *)notification
{
    [super textDidChange:notification];
    _userTypedString = [self stringValue];
    NSLog(@"_userTypedString %@", _userTypedString);
}

/* The field editor's text may have changed for a number of reasons. Generally, we should update the suggestions window with the new suggestions. However, in some cases (the user deletes characters) we cancel the suggestions window.
 */
- (void)controlTextDidChange:(NSNotification *)notification {
    _suggestedCompletion = nil;
    if(!self.skipNextSuggestion) {
        [self updateSuggestionsFromControl:notification.object];
    } else {
        // If we are skipping this suggestion, the set the _suggestedURL to nil and cancel the suggestions window.
        _suggestedCompletion = nil;
        
        // If the suggestionController is already in a cancelled state, this call does nothing and is therefore always safe to call.
        [_suggestionsController cancelSuggestions];
        
        // This suggestion has been skipped, don't skip the next one.
        self.skipNextSuggestion = NO;
    }
}

/* The field editor has ended editing the text. This is not the same as the action from the NSTextField. In the MainMenu.xib, the search text field is setup to only send its action on return / enter. If the user tabs to or clicks on another control, text editing will end and this method is called. We don't consider this committal of the action. Instead, we realy on the text field's action (see -performLocalSearch: above) to commit the suggestion. However, since the action may not occur, we need to cancel the suggestions window here.
 */

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    /* If the suggestionController is already in a cancelled state, this call does nothing and is therefore always safe to call.
     */
    [_suggestionsController cancelSuggestions];
}

/* As the delegate for the NSTextField, this class is given a chance to respond to the key binding commands interpreted by the input manager when the field editor calls -interpretKeyEvents:. This is where we forward some of the keyboard commands to the suggestion window to facilitate keyboard navigation. Also, this is where we can determine when the user deletes and where we can prevent AppKit's auto completion.
 */
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    
    if (commandSelector == @selector(moveUp:)) {
        // Move up in the suggested selections list
        [_suggestionsController moveUp:textView];
        return YES;
    }
    
    if (commandSelector == @selector(moveDown:)) {
        // Move down in the suggested selections list
        [_suggestionsController moveDown:textView];
        return YES;
    }
    
    if (commandSelector == @selector(deleteForward:) || commandSelector == @selector(deleteBackward:)) {
        /* The user is deleting the highlighted portion of the suggestion or more. Return NO so that the field editor performs the deletion. The field editor will then call -controlTextDidChange:. We don't want to provide a new set of suggestions as that will put back the characters the user just deleted. Instead, set skipNextSuggestion to YES which will cause -controlTextDidChange: to cancel the suggestions window. (see -controlTextDidChange: above)
         */
        self.skipNextSuggestion = YES;
        return NO;
    }
    
    if (commandSelector == @selector(complete:)) {
        // The user has pressed the key combination for auto completion. AppKit has a built in auto completion. By overriding this command we prevent AppKit's auto completion and can respond to the user's intention by showing or cancelling our custom suggestions window.
        if ([_suggestionsController.window isVisible]) {
            [_suggestionsController cancelSuggestions];
        } else {
            [self updateSuggestionsFromControl:control];
        }
        
        return YES;
    }
    
    if (commandSelector == @selector(cancelOperation:)) {
        if ([_suggestionsController.window isVisible]) {
            [_suggestionsController cancelSuggestions];
            [[self searchCompleter] cancel];
            [self updateWithSelectedSuggestion:nil];
            _suggestedCompletion = nil;
            _searchAutocompletions = nil;
            return YES;
        } else {
            _userTypedString = @"";
        }
        return NO;
    }
    
    // This is a command that we don't specifically handle, let the field editor do the appropriate thing.
    return NO;
}

- (void)cancelOperation:(nullable id)sender
{
    if ([[self stringValue] length] == 0) {
        [[self window] makeFirstResponder:[self window]];
    }
}

#pragma mark -
#pragma mark MKLocalSearchCompleterDelegate

- (void)completerDidUpdateResults:(MKLocalSearchCompleter *)completer
{
    [self setSearchAutocompletions:[completer results]];
    NSText *fieldEditor = [self.window fieldEditor:NO forObject:self];
    if (fieldEditor) {
        // Only use the text up to the caret position
        NSRange selection = [fieldEditor selectedRange];
        NSString *text = [[fieldEditor string] substringToIndex:selection.location];
        
        NSArray *suggestions = [self suggestionsForText:text];
        if ([suggestions count] > 0) {
            // We have at least 1 suggestion. Update the field editor to the first suggestion and show the suggestions window.
            //NSDictionary *suggestion = [suggestions objectAtIndex:0];
            //_suggestedCompletion = [suggestion objectForKey:kSuggestionCompletion];
            //[self updateFieldEditor:fieldEditor withSuggestion:[suggestion objectForKey:kSuggestionLabel]];
            
            [_suggestionsController setSuggestions:suggestions];
            if (![_suggestionsController.window isVisible]) {
                [_suggestionsController beginForTextField:self];
            }
        } else {
            // No suggestions. Cancel the suggestion window and set the _suggestedURL to nil.
            _suggestedCompletion = nil;
            [_suggestionsController cancelSuggestions];
        }
    }
}

- (void)completer:(MKLocalSearchCompleter *)completer didFailWithError:(NSError *)error
{
    NSLog(@"%@",error);
    _suggestedCompletion = nil;
    [_suggestionsController cancelSuggestions];
}

@end
