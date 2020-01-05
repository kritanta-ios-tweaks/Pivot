#include <UIKit/UIKit.h>

#define kIdentifier @"me.kritanta.pivot"
#define kSettingsChangedNotification (CFStringRef)@"me.kritanta.pivot/Prefs"
#define kSettingsPath @"/var/mobile/Library/Preferences/me.kritanta.pivot.plist"

@interface SBRootFolderController : UIViewController
@property (nonatomic, assign) CGFloat dockHeight;
@end

@interface SBIconController : UIViewController
+ (SBIconController *)sharedInstance;
- (SBRootFolderController *)_rootFolderController;
@end
