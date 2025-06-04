#import "MyMapView.h"
#import "CoreWLAN/CoreWLAN.h"
#import "CLLocation+Additions.h"

typedef NS_ENUM(NSInteger, MKLocationErrorCode) {
    MKLocationErrorCodeDenied,
    MKLocationErrorCodeRestricted,
    MKLocationErrorCodeCoreLocationDisabled,
    MKLocationErrorCodeWifiOff,
    MKLocationErrorCodeNoWifi
};

@interface MyMapView() <CLLocationManagerDelegate,MKMapViewDelegate>

@property IBOutlet NSTextField *latitudeTextField;
@property IBOutlet NSTextField *longitudeTextField;
@property IBOutlet NSWindow *sheet;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) MKPointAnnotation *pinAnnotation;

@end

@implementation MyMapView

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
    [self setupLocationManager];
    if (@available(macOS 14.0, *)) {
        [self setShowsUserTrackingButton:YES];
    } else {
        [self addLocateMeButton];
    }
    [self addPinPointAnnotation];
    [self setDelegate:self];
}

- (void)addLocateMeButton
{
    NSImage *locationImage = [NSImage imageWithSystemSymbolName:@"location" accessibilityDescription:@"location services"];
    NSButton *button = [NSButton buttonWithImage:locationImage target:self action:@selector(tapLocateMe:)];
    button.toolTip = NSLocalizedString(@"Show your current location", "");
    [self addSubview:button];
}

- (void)addPinPointAnnotation
{
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = [self centerCoordinate];
    [self addAnnotation:annotation];
    _pinAnnotation = annotation;
}

- (void)setupLocationManager
{
    // we only need instance of location manager to determine authorizations status
    // userLocation is handled by MKMapView
    // Warning: In the same runloop newly created instance of CLLocationManager returns not determined status
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [self setLocationManager:locationManager];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)setPinLocation:(CLLocation *)location
{
    [self pinAnnotation].coordinate = location.coordinate;
}

- (NSMenu *)menuForEvent:(NSEvent *)event
{
    NSMenuItem *item;
    NSMenu *menu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Map View Menu", nil)];
    CLLocationCoordinate2D coord = [self convertPoint:[event locationInWindow] toCoordinateFromView:nil];
    if (CLLocationCoordinate2DIsValid(coord)) {
        CLLocation *location = [CLLocation locationWithCoordinate:coord];
        item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Drop Pin", nil) action:@selector(dropPinAction:) keyEquivalent:@""];
        [item setRepresentedObject:location];
        [menu addItem:item];
    }
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Enter Coordinates", nil) action:@selector(enterCoordinates:) keyEquivalent:@""];
    [menu addItem:item];
    return menu;
}

- (IBAction)tapLocateMe:(id)sender
{
    [self handleLocationRequest];
}

- (void)handleLocationRequest
{
    if ([self userLocation].location != nil) {
        [self showAnnotations:@[[self userLocation]] animated:NO];
        return;
    }
    
    MKUserTrackingMode nextMode = MKUserTrackingModeNone;
    if ([self userTrackingMode] == MKUserTrackingModeNone) {
        nextMode = MKUserTrackingModeFollow;
    }
    [self setUserTrackingMode:nextMode animated:YES];
    
    [self showLocationServicesAlertIfNeeded];
}

- (void)showLocationServicesAlertIfNeeded {
    if (![CLLocationManager locationServicesEnabled]) {
        [self presentCoreLocationAlert:MKLocationErrorCodeCoreLocationDisabled];
        return;
    }

    CLAuthorizationStatus status = [self.locationManager authorizationStatus];
    if (status != kCLAuthorizationStatusAuthorized && status != kCLAuthorizationStatusNotDetermined) {
        [self presentCoreLocationAlert:MKLocationErrorCodeDenied];
        return;
    }

    if (status != kCLAuthorizationStatusAuthorized) {
        // Not determined branch
        if (@available(macOS 14.0, *)) {
            // Without location access [CWWiFiClient sharedWiFiClient] doesn't tell us anything
            return;
        } else {
            // on lower systems we proceed to check if Wi-Fi is enabled
        }
    }

    // Authorized branch
    NSArray<CWInterface *> *interfaces = [[CWWiFiClient sharedWiFiClient] interfaces];
    CWInterface *interface = [[CWWiFiClient sharedWiFiClient] interface];

    if (!interfaces.count || !interface) {
        [self presentCoreLocationAlert:MKLocationErrorCodeNoWifi];
        return;
    }

    if (![interface powerOn]) {
        [self presentCoreLocationAlert:MKLocationErrorCodeWifiOff];
    }
}

- (void)presentCoreLocationAlert:(MKLocationErrorCode)code {
    NSError *error = MKLocationErrorMake(code);
    NSAlert *alert = [NSAlert alertWithError:error];

    BOOL canShowButton = (code == MKLocationErrorCodeDenied ||
                          code == MKLocationErrorCodeRestricted ||
                          code == MKLocationErrorCodeCoreLocationDisabled);

    if (canShowButton) {
        [alert addButtonWithTitle:NSLocalizedString(@"Open Privacy Settings…", @"")];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    }

    NSModalResponse result = [alert runModal];
    if (result == NSAlertSecondButtonReturn && canShowButton) {
        NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Location"];
        if (!url) {
            NSLog(@"Settings (Privacy: %@) not found.", @"x-apple.systempreferences:com.apple.preference.security?Privacy_Location");
            return;
        }
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

NSError *MKLocationErrorMake(MKLocationErrorCode code) {
    NSBundle *bundle = [NSBundle bundleForClass:[MKMapView class]];
    NSString *localizedDescription = [bundle localizedStringForKey:@"Cannot Show Your Location"
                                                             value:nil
                                                             table:@"MapKit"];
    NSString *localizedRecovery = @"";

    switch (code) {
        case MKLocationErrorCodeDenied:
        case MKLocationErrorCodeRestricted:
        case MKLocationErrorCodeCoreLocationDisabled: {
            localizedDescription = [bundle localizedStringForKey:@"Location Services Off"
                                                           value:nil
                                                           table:@"MapKit"];
            if (@available(macOS 13.0, *)) {
                localizedRecovery = [bundle localizedStringForKey:@"Turn on Location Services in System Settings > Privacy & Security to allow %@ to determine your current location."
                                                            value:nil
                                                            table:@"MapKit"];
            } else {
                localizedRecovery = [bundle localizedStringForKey:@"Turn on Location Services in System Preferences > Security & Privacy to allow %@ to determine your current location"
                                                            value:nil
                                                            table:@"MapKit"];
            }
            localizedRecovery = [NSString stringWithFormat:localizedRecovery, @"App name"];
            break;
        }
        case MKLocationErrorCodeWifiOff: {
            localizedDescription = [bundle localizedStringForKey:@"Cannot Show Your Location"
                                                           value:nil
                                                           table:@"MapKit"];
            localizedRecovery = [bundle localizedStringForKey:@"Turn on Wi-Fi to allow %@ to determine your current location."
                                                        value:nil
                                                        table:@"MapKit"];
            localizedRecovery = [NSString stringWithFormat:localizedRecovery, @"App name"];
            break;
        }
        case MKLocationErrorCodeNoWifi: {
            localizedRecovery = [bundle localizedStringForKey:@"This Mac cannot determine your current location because it does not have Wi-Fi."
                                                        value:nil
                                                        table:@"MapKit"];
            break;
        }
    }

    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: localizedDescription,
        NSLocalizedRecoverySuggestionErrorKey: localizedRecovery
    };

    return [NSError errorWithDomain:@"MKLocationErrorDomain"
                               code:code
                           userInfo:userInfo];
}

- (void)dropPinAction:(NSMenuItem *)sender
{
    [self dropPinAt:[sender representedObject] animated:YES];
}

- (void)dropPinAt:(CLLocation *)location animated:(BOOL)animated
{
    [self pinAnnotation].coordinate = location.coordinate;
    if ([[self myDelegate] respondsToSelector:@selector(mapView:didChangeLocation:)]) {
        [[self myDelegate] mapView:self didChangeLocation:location];
    }
}

- (void)enterCoordinates:(id)sender
{
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"entercoordinates" bundle:nil];
    NSArray *array;
    __unused BOOL success = [nib instantiateWithOwner:self topLevelObjects:&array];
    if ([self sheet] == nil) {
        return;
    }
    
    self.latitudeTextField.doubleValue = [self pinAnnotation].coordinate.latitude;
    self.longitudeTextField.doubleValue = [self pinAnnotation].coordinate.longitude;
    
    [[self window] beginSheet:[self sheet] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            double latitude = self.latitudeTextField.doubleValue;
            double longitude = self.longitudeTextField.doubleValue;
            CLLocationCoordinate2D coord = {latitude, longitude};
            if(CLLocationCoordinate2DIsValid(coord)) {
                [self pinAnnotation].coordinate = coord;
                [self showAnnotations:@[[self pinAnnotation]] animated:YES];
                CLLocation *location = [CLLocation locationWithCoordinate:coord];
                if ([[self myDelegate] respondsToSelector:@selector(mapView:didChangeLocation:)]) {
                    [[self myDelegate] mapView:self didChangeLocation:location];
                }
            } else {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:NSLocalizedString(@"Location Invalid", nil)];
                [alert setAlertStyle:NSAlertStyleInformational];
                [alert setIcon:[NSImage imageNamed:NSImageNameCaution]];
                [alert setInformativeText:NSLocalizedString(@"Invalid location entered. Allowed values:\r\nLatitude: -90..90.\r\nLongitude: -180..180", nil)];
                [alert runModal];
            }
        }
    }];
}

- (IBAction)submitCoordinateAction:(id)sender
{
    [[self window] endSheet:[sender window] returnCode:NSModalResponseOK];
}

- (IBAction)cancelCoordinateAction:(id)sender
{
    [[self window] endSheet:[sender window] returnCode:NSModalResponseCancel];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString *defaultID = @"pin";
    
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self dequeueReusableAnnotationViewWithIdentifier:defaultID];
    //If one isn't available, create a new one
    if(annotationView == nil)
    {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:defaultID];
        annotationView.pinTintColor = [MKPinAnnotationView purplePinColor];
        annotationView.draggable = YES;
    }
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    if (newState == MKAnnotationViewDragStateEnding) // you can check out some more states by looking at the docs
    {
        CLLocationCoordinate2D droppedAt = annotationView.annotation.coordinate;
        CLLocation *location = [CLLocation locationWithCoordinate:droppedAt];
        if ([[self myDelegate] respondsToSelector:@selector(mapView:didChangeLocation:)]) {
            [[self myDelegate] mapView:self didChangeLocation:location];
        }
    }
}

#pragma mark -
#pragma CLLocationManagerDelegate

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager
{

}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    [manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [[NSAlert alertWithError:error] runModal];
}

@end
