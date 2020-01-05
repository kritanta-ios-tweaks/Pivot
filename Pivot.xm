#include "Pivot.h"


#pragma mark Globals


NSDictionary *prefs = nil;

// 0: Disabled
// 1: Plus Style
// 2: iPad Style
static int _pfMode = 1;
static BOOL _pfDontRotateWallpaper = YES;
static BOOL _pfMedusa = YES;
static BOOL _pfInvert = YES;
static CGFloat _pfVPad = 5;

// 2 = Plus Style
// 1 = iPad Style
// Anything else disables it. 
static int _rtRotationStyle = 1;


%hook SBApplication
- (BOOL)isMedusaCapable 
{
    if (_pfMedusa) 
    {
	    return YES;
    }
    return %orig;
}
%end

%hook SpringBoard

- (BOOL)supportsPortraitUpsideDownOrientation
{
    return _pfInvert;
}

- (NSUInteger)homeScreenRotationStyle
{
    return _rtRotationStyle;
}

- (BOOL)homeScreenSupportsRotation
{
    return (_rtRotationStyle != 0);
}

%end


%hook SBWallpaperController

-(BOOL)_isAcceptingOrientationChangesFromSource:(NSInteger)arg
{
    return (!_pfDontRotateWallpaper);
}

%end 


%hook SBIconListGridLayoutConfiguration 

- (UIEdgeInsets)landscapeLayoutInsets
{   
    UIEdgeInsets x = %orig;

    NSUInteger rows = MSHookIvar<NSUInteger>(self, "_numberOfPortraitRows");
    NSUInteger columns = MSHookIvar<NSUInteger>(self, "_numberOfPortraitColumns"); 
    BOOL i = ( !( rows == 3 && columns == 3 ) && !( rows <=2 && columns <=5));
    CGFloat h = [(SBIconController *)[%c(SBIconController) sharedInstance] _rootFolderController].dockHeight - 10;
    if (i)
    {
        return UIEdgeInsetsMake(
            5,
            x.left + h,
            5, // * 2 because regularly it was too slow
            x.right + h*0.5
        );
    }
    else 
        return x;
}

%end


@interface _UIStatusBar : UIView 
@property (nonatomic, assign) NSInteger orientation;
@end 

@interface _UIStatusBarStringView : UILabel 
@end


@interface _UIStatusBarCellularSignalView : UIView
@end

/*

%hook _UIStatusBarCellularSignalView

// %orig(CGRectMake(31, 24, frame.size.width, frame.size.height));


- (void)layoutSubviews
{
    %orig;
    @try
    {
        _UIStatusBar *bar = (_UIStatusBar *)self.superview.superview;
        if (UIDeviceOrientationIsLandscape(bar.orientation))
        {
            [self setFrame:CGRectMake(27, 20, self.frame.size.width, self.frame.size.height)];
            return;
        }
    }
    @catch (NSException *ex)
    {

    }
}

%end


%hook _UIStatusBarStringView

- (BOOL)prefersBaselineAlignment
{
    return NO;
}

- (void)layoutSubviews
{
    %orig;
    @try
    {
        _UIStatusBar *bar = (_UIStatusBar *)self.superview.superview;
        if (UIDeviceOrientationIsLandscape(bar.orientation))
        {
            [self setFrame:CGRectMake(18, 35, self.frame.size.width, self.frame.size.height)];
            return;
        }
    }
    @catch (NSException *ex)
    {

    }
}


%end
*/

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//
//
// Pivot Preferences
// #pragma Preferences
//
//
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

static void *observer = NULL;

static void reloadPrefs() 
{
    if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) 
    {
        CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

        if (keyList) 
        {
            prefs = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));

            if (!prefs) 
            {
                prefs = [NSDictionary new];
            }
            CFRelease(keyList);
        }
    } 
    else 
    {
        prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
    }
}



static void preferencesChanged() 
{
    CFPreferencesAppSynchronize((CFStringRef)kIdentifier);
    reloadPrefs();

    _pfMode = [[prefs valueForKey:@"rotationMode"] integerValue] ?: 1;
    _pfDontRotateWallpaper = [prefs objectForKey:@"lockWallpaper"] ? [[prefs valueForKey:@"lockWallpaper"] boolValue] : YES;
    _pfMedusa = [prefs objectForKey:@"medusa"] ? [[prefs valueForKey:@"medusa"] boolValue] : YES;
    _pfInvert = [prefs objectForKey:@"invert"] ? [[prefs valueForKey:@"invert"] boolValue] : YES;
    _pfVPad = [[prefs valueForKey:@"verticalPad"] floatValue] ?: 5.0;

    if (_pfMode != 2) _rtRotationStyle = _pfMode * 2; 
}

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//
//
// Pivot Constructor
// #pragma ctor
//
//
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

%ctor 
{
    preferencesChanged();

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        &observer,
        (CFNotificationCallback)preferencesChanged,
        kSettingsChangedNotification,
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}
