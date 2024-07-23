#import "MyMapView.h"
#import "CLLocation+Additions.h"

@interface MyMapView() <CLLocationManagerDelegate,MKMapViewDelegate>

@property IBOutlet NSTextField *latitudeTextField;
@property IBOutlet NSTextField *longitudeTextField;
@property IBOutlet NSWindow *sheet;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *currentLocation;

@end

@implementation MyMapView

- (void)awakeFromNib
{
    [super awakeFromNib];
    if ([CLLocationManager locationServicesEnabled]) {
        if ([[self locationManager] authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
            [self determineCurrentLocationAction:nil];
        }
    }
}

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
    [self addLocateMeButton];
    [self setDelegate:self];
    CLLocationCoordinate2D coord = {51.507351, -0.127758};
    NSAssert(CLLocationCoordinate2DIsValid(coord) == YES, @"Invalid location");
    CLLocation *location = [CLLocation locationWithCoordinate:coord];
    [self setCurrentLocation:location resetAnnotations:YES];
}

- (void)addLocateMeButton
{
    
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 52, 32)];
    [button setTarget:self];
    [button setAction:@selector(determineCurrentLocationAction:)];
    [button setImage:[NSImage imageNamed:@"location"]];
    [button setButtonType:NSButtonTypeMomentaryLight];
    [button setImagePosition:NSImageOnly];
    [button setImageScaling:NSImageScaleProportionallyDown];
    [button setBordered:YES];
    [button setBezelStyle:NSBezelStyleRounded];
    [self addSubview:button];
}

- (void)setupLocationManager
{
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [self setLocationManager:locationManager];
    [locationManager authorizationStatus];
    if ([CLLocationManager locationServicesEnabled]) {
        [[self locationManager] startUpdatingLocation];
    }
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)setLocation:(CLLocation *)location
{
    if (location == nil) {
        return;
    }
    [self setCurrentLocation:location resetAnnotations:YES];
}

- (void)setCurrentLocation:(CLLocation *)currentLocation resetAnnotations:(BOOL)shouldReset
{
    [self setCurrentLocation:currentLocation];
    if (shouldReset) {
        [self resetAnnotations];
    }
}

- (void)setCurrentLocation:(CLLocation *)currentLocation
{
    if (currentLocation != _currentLocation) {
        _currentLocation = currentLocation;
        if ([[self myDelegate] respondsToSelector:@selector(mapView:didChangeLocation:)]) {
            [[self myDelegate] mapView:self didChangeLocation:currentLocation];
        }
    }
}

- (NSMenu *)menuForEvent:(NSEvent *)event
{
    NSMenuItem *item;
    NSMenu *menu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Map View Menu", nil)];
    CLLocationCoordinate2D coord = [self convertPoint:[event locationInWindow] toCoordinateFromView:nil];
    if (CLLocationCoordinate2DIsValid(coord)) {
        CLLocation *location = [CLLocation locationWithCoordinate:coord];
        item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Drop Pin", nil) action:@selector(dropPin:) keyEquivalent:@""];
        [item setRepresentedObject:location];
        [menu addItem:item];
    }
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Enter Coordinates", nil) action:@selector(enterCoordinates:) keyEquivalent:@""];
    [menu addItem:item];
    return menu;
}

- (IBAction)determineCurrentLocationAction:(id)sender
{
    if ([[self locationManager] authorizationStatus] == kCLAuthorizationStatusDenied) {
        [self openPrivacyLocationAction:nil];
    }
    CLLocation *location = [[self locationManager] location];
    if (location) {
        [self setCurrentLocation:location resetAnnotations:YES];
    }
}

- (IBAction)openPrivacyLocationAction:(id)sender
{
    NSString *privacyPath = @"x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices";
    NSURL *URL = [NSURL URLWithString:privacyPath];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}

- (void)dropPin:(id)sender
{
    [self setCurrentLocation:[sender representedObject] resetAnnotations:YES];
}

- (void)enterCoordinates:(id)sender
{
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"entercoordinates" bundle:nil];
    NSArray *array;
    __unused BOOL success = [nib instantiateWithOwner:self topLevelObjects:&array];
    if ([self sheet] == nil) {
        return;
    }
    
    [[self window] beginSheet:[self sheet] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            double latitude = self.latitudeTextField.doubleValue;
            double longitude = self.longitudeTextField.doubleValue;
            CLLocationCoordinate2D coord = {latitude, longitude};
            if(CLLocationCoordinate2DIsValid(coord)) {
                CLLocation *location = [CLLocation locationWithCoordinate:coord];
                [self setCurrentLocation:location resetAnnotations:YES];
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

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
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
        [[self longitudeTextField] setDoubleValue:droppedAt.longitude];
        [[self latitudeTextField] setDoubleValue:droppedAt.latitude];
        
        CLLocation *location = [CLLocation locationWithCoordinate:droppedAt];
        [self setCurrentLocation:location resetAnnotations:NO];
    }
}

- (void)resetAnnotations
{
    CLLocation *location = [self currentLocation];
    CLLocationCoordinate2D coord =  location.coordinate;
    
    MKCoordinateRegion region = {coord, [self region].span};
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = coord;
    
    [self setRegion:region];
    [self removeAnnotations:[self annotations]];
    [self addAnnotation:annotation];
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
