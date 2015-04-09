//
//  ViewController.m
//  p2pkit-quickstart-ios
//
//  Copyright (c) 2015 Uepaa AG. All rights reserved.
//

#import "ViewController.h"
#import <P2PKit/P2PKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController ()<PPKControllerDelegate,CLLocationManagerDelegate> {
    CLLocationManager* locMgr_;
}
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [PPKController enableWithConfiguration:@"<YOUR APP KEY>" observer:self];
}

#pragma mark - PPKControllerDelegate

-(void)PPKControllerInitialized {
    
    [PPKController startP2PDiscovery];
    [PPKController startGeoDiscovery];
    [PPKController startOnlineMessaging];
    
    [self logKey:@"My ID (p2pkit init success!)" value:[PPKController myPeerID]];
}

-(void)PPKControllerFailedWithError:(NSError*)error {
    
    NSString *description;
    
    switch ((PPKErrorCode) error.code) {
        case PPKErrorAppKeyInvalid:
            description = @"Invalid app key";
            break;
        case PPKErrorAppKeyExpired:
            description = @"Expired app key";
            break;
        case PPKErrorOnlineProtocolVersionNotSupported:
            description = @"Server protocol mismatch";
            break;
        case PPKErrorOnlineAppKeyInvalid:
            description = @"Invalid app key";
            break;
        case PPKErrorOnlineAppKeyExpired:
            description = @"Expired app key";
            break;
    }
    
    [self logKey:@"SDK init error" value:description];
}

-(void)p2pDiscoveryStateChanged:(PPKPeer2PeerDiscoveryState)state {
    
    NSString *description;
    
    switch (state) {
        case PPKPeer2PeerDiscoveryStopped:
            description = @"stopped";
            break;
        case PPKPeer2PeerDiscoverySuspended:
            description = @"suspended";
            break;
        case PPKPeer2PeerDiscoveryRunning:
            description = @"running";
            break;
    }
    
    [self logKey:@"P2P state" value:description];
}

-(void)p2pPeerDiscovered:(NSString*)peerID {
    
    [self logKey:peerID value:@"P2P discovered"];
    [self send:@"From iOS: Hello P2P!" to:peerID];
}

-(void)p2pPeerLost:(NSString*)peerID {
    [self logKey:peerID value:@"P2P lost"];
}

-(void)onlineMessagingStateChanged:(PPKOnlineMessagingState)state {
    
    NSString *description;
    
    switch (state) {
        case PPKOnlineMessagingRunning:
            description = @"running";
            [self startLocationUpdates];
            break;
        case PPKOnlineMessagingSuspended:
            description = @"suspended";
            [self stopLocationUpdates];
            break;
        case PPKOnlineMessagingStopped:
            description = @"stopped";
            [self stopLocationUpdates];
            break;
    }
    
    [self logKey:@"Online messaging state" value:description];
}

-(void)messageReceived:(NSData*)messageBody header:(NSString*)messageHeader from:(NSString*)peerID {
    [self logKey:peerID value:[[NSString alloc] initWithData:messageBody encoding:NSUTF8StringEncoding]];
}

-(void)geoDiscoveryStateChanged:(PPKGeoDiscoveryState)state {
    
    NSString *description;
    
    switch (state) {
        case PPKGeoDiscoveryRunning:
            description = @"running";
            [self startLocationUpdates];
            break;
        case PPKGeoDiscoverySuspended:
            description = @"suspended";
            [self stopLocationUpdates];
            break;
        case PPKGeoDiscoveryStopped:
            description = @"stopped";
            [self stopLocationUpdates];
            break;
    }
    
    [self logKey:@"GEO state" value:description];
}

-(void)geoPeerDiscovered:(NSString*)peerID {
    
    [self logKey:peerID value:@"GEO discovered"];
    [self send:@"From iOS: Hello GEO!" to:peerID];
}

-(void)geoPeerLost:(NSString*)peerID {
    [self logKey:peerID value:@"GEO lost"];
}

#pragma mark - Helpers

-(void)logKey:(NSString*)key value:(NSString*)value {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logTextView.text = [NSString stringWithFormat:@"%@: %@\n%@", key, value, self.logTextView.text];
    });
}

-(void)send:(NSString*)message to:(NSString*)peerID {
    [PPKController sendMessage:[message dataUsingEncoding:NSUTF8StringEncoding] withHeader:@"SimpleChatMessage" to:peerID];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [PPKController updateUserLocation:[locations lastObject]];
}

#pragma mark - CLLocationManager Helpers

-(void)startLocationUpdates {
    
    if (locMgr_) {
        return;
    }
    
    locMgr_ = [CLLocationManager new];
    [locMgr_ setDelegate:self];
    [locMgr_ setDesiredAccuracy:200];

    /* Avoid sending to many location updates, set a distance filter */
    [locMgr_ setDistanceFilter:200];

    if ([locMgr_ respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [locMgr_ requestAlwaysAuthorization];
    }
    
    [locMgr_ startUpdatingLocation];
}

-(void)stopLocationUpdates {
    
    if (!locMgr_) {
        return;
    }
    
    [locMgr_ stopUpdatingLocation];
    [locMgr_ setDelegate:nil];
    locMgr_ = nil;
}

@end
