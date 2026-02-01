# MapkitSearchFieldOSX
Example of NSSearchfield with suggestions for MapKit on MacOS
Almost drag&drop solution for you.

NOTE: This is very old code. It still works but there are multiple issues (referenced + not referenced here). Recommend looking for issues here https://github.com/jbrayton/CustomMenus/issues

NOTE: I have updated RoundedCorners to use NSVisualEffectView and HighlightingView to be subclass of NSTableCellView to propagate emphasized state automatically. Custom tableview is prepared in the repository for the curious ones.

NOTE: macOS15 introduced suggestionMenu delegate which should be used


The original code from CustomMenus was used 1:1 in StoreUI.framework on macOS10.9 https://github.com/samdmarshall/OSXPrivateSDK/blob/f4d52b60e86b496abfaffa119a7d299562d99783/PrivateSDK10.9.sparse.sdk/System/Library/PrivateFrameworks/StoreUI.framework/PrivateHeaders/SuggestionsWindowController.h

Another updated versions with tableview can be found at:
https://github.com/andyvand/classdump-dyld/blob/0e64b667db469d8791e4b95f78bbdf1c107f1184/Full/System/Library/PrivateFrameworks/SocialUI.framework/Versions/A/SocialUI/SOAddRecipientFieldViewController.h


![](https://raw.githubusercontent.com/xhruso00/MapkitSearchFieldOSX/master/screenshot.png)

