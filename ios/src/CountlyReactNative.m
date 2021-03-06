#import <React/RCTBridge.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <React/RCTEventDispatcher.h>

#import "Countly.h"
#import "CountlyReactNative.h"
#import "CountlyConfig.h"
#import "CountlyPushNotifications.h"
#import "CountlyConnectionManager.h"
#import "CountlyRemoteConfig.h"
#import "CountlyCommon.h"

NSString* const kCountlyReactNativeSDKVersion = @"20.04.5";
NSString* const kCountlyReactNativeSDKName = @"js-rnb-ios";

CountlyConfig* config = nil;
NSDictionary *lastStoredNotification = nil;
Result notificationListener = nil;
NSMutableArray *notificationIDs = nil;        // alloc here

@implementation CountlyReactNative

- (NSArray<NSString *> *)supportedEvents {
    return @[@"onCountlyPushNotification"];
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(init:(NSArray*)arguments)
{
  NSString* serverurl = [arguments objectAtIndex:0];
  NSString* appkey = [arguments objectAtIndex:1];
  NSString* deviceID = [arguments objectAtIndex:2];

  if (config == nil){
    config = CountlyConfig.new;
  }
  if(![deviceID  isEqual: @""]){
    config.deviceID = deviceID;
  }
  config.appKey = appkey;
  config.host = serverurl;
    
  CountlyCommon.sharedInstance.SDKName = kCountlyReactNativeSDKName;
  CountlyCommon.sharedInstance.SDKVersion = kCountlyReactNativeSDKVersion;
    
  config.features = @[CLYCrashReporting, CLYPushNotifications];

  if (serverurl != nil && [serverurl length] > 0) {
      dispatch_async(dispatch_get_main_queue(), ^
      {
          [[Countly sharedInstance] startWithConfig:config];
      });
  }
}

RCT_EXPORT_METHOD(event:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* eventType = [arguments objectAtIndex:0];
  if (eventType != nil && [eventType length] > 0) {
    if ([eventType  isEqual: @"event"]) {
      NSString* eventName = [arguments objectAtIndex:1];
      NSString* countString = [arguments objectAtIndex:2];
      int countInt = [countString intValue];
      [[Countly sharedInstance] recordEvent:eventName count:countInt];

    }
    else if ([eventType  isEqual: @"eventWithSum"]){
      NSString* eventName = [arguments objectAtIndex:1];
      NSString* countString = [arguments objectAtIndex:2];
      int countInt = [countString intValue];
      NSString* sumString = [arguments objectAtIndex:3];
      float sumFloat = [sumString floatValue];
      [[Countly sharedInstance] recordEvent:eventName count:countInt  sum:sumFloat];
    }
    else if ([eventType  isEqual: @"eventWithSegment"]){
      NSString* eventName = [arguments objectAtIndex:1];
      NSString* countString = [arguments objectAtIndex:2];
      int countInt = [countString intValue];
      NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

      for(int i=3,il=(int)arguments.count;i<il;i+=2){
        dict[[arguments objectAtIndex:i]] = [arguments objectAtIndex:i+1];
      }
      [[Countly sharedInstance] recordEvent:eventName segmentation:dict count:countInt];
    }
    else if ([eventType  isEqual: @"eventWithSumSegment"]){
      NSString* eventName = [arguments objectAtIndex:1];
      NSString* countString = [arguments objectAtIndex:2];
      int countInt = [countString intValue];
      NSString* sumString = [arguments objectAtIndex:3];
      float sumFloat = [sumString floatValue];
      NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

      for(int i=4,il=(int)arguments.count;i<il;i+=2){
        dict[[arguments objectAtIndex:i]] = [arguments objectAtIndex:i+1];
      }
      [[Countly sharedInstance] recordEvent:eventName segmentation:dict count:countInt  sum:sumFloat];
    }
  }
  });
}
RCT_EXPORT_METHOD(recordView:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* recordView = [arguments objectAtIndex:0];
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
  for(int i=1,il=(int)arguments.count;i<il;i+=2){
    dict[[arguments objectAtIndex:i]] = [arguments objectAtIndex:i+1];
  }
  [Countly.sharedInstance recordView:recordView segmentation: dict];
  });
}

RCT_EXPORT_METHOD(setViewTracking:(NSArray*)arguments)
{

}

RCT_EXPORT_METHOD(setLoggingEnabled:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  BOOL boolean = [[arguments objectAtIndex:0] boolValue];
  if(boolean){
    config.enableDebug = YES;
  }else{
    config.enableDebug = NO;
  }
  });
}

RCT_EXPORT_METHOD(setUserData:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* name = [arguments objectAtIndex:0];
  NSString* username = [arguments objectAtIndex:1];
  NSString* email = [arguments objectAtIndex:2];
  NSString* org = [arguments objectAtIndex:3];
  NSString* phone = [arguments objectAtIndex:4];
  NSString* picture = [arguments objectAtIndex:5];
  NSString* pictureLocalPath = [arguments objectAtIndex:6];
  NSString* gender = [arguments objectAtIndex:7];
  NSString* byear = [arguments objectAtIndex:8];

  Countly.user.name = name;
  Countly.user.username = username;
  Countly.user.email = email;
  Countly.user.organization = org;
  Countly.user.phone = phone;
  Countly.user.pictureURL = picture;
  Countly.user.pictureLocalPath = pictureLocalPath;
  Countly.user.gender = gender;
  Countly.user.birthYear = @([byear integerValue]);
  [Countly.user save];
  });
}


RCT_EXPORT_METHOD(sendPushToken:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {

    NSString* token = [arguments objectAtIndex:0];
    NSString* messagingMode = [arguments objectAtIndex:1];
    NSString *urlString = [ @"" stringByAppendingFormat:@"%@?device_id=%@&app_key=%@&token_session=1&test_mode=%@&ios_token=%@", config.host, [Countly.sharedInstance deviceID], config.appKey, messagingMode, token];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:urlString]];
  });
}
RCT_EXPORT_METHOD(pushTokenType:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  if (config == nil){
    config = CountlyConfig.new;
  }
  config.sendPushTokenAlways = YES;
  NSString* tokenType = [arguments objectAtIndex:0];
  if([tokenType isEqualToString: @"1"]){
      config.pushTestMode = @"CLYPushTestModeDevelopment";
  }
  else if([tokenType isEqualToString: @"2"]){
      config.pushTestMode = @"CLYPushTestModeTestFlightOrAdHoc";
  }else{
  }
  });
}

RCT_EXPORT_METHOD(askForNotificationPermission:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  [Countly.sharedInstance askForNotificationPermission];
  });
}
- (void) saveListener:(Result) result{
    notificationListener = result;
}
RCT_EXPORT_METHOD(registerForNotification:(NSArray*)arguments)
{
    [self saveListener: ^(id  _Nullable result) {
         [self sendEventWithName:@"onCountlyPushNotification" body: [CountlyReactNative toJSON:lastStoredNotification]];
         lastStoredNotification = nil;
    }];
    if(lastStoredNotification != nil){
        [self sendEventWithName:@"onCountlyPushNotification" body: [CountlyReactNative toJSON:lastStoredNotification]];
        lastStoredNotification = nil;
    }
};

+ (void)onNotification:(NSDictionary *)notificationMessage
{
    NSLog(@"Notification received");
    NSLog(@"The notification %@", [CountlyReactNative toJSON:notificationMessage]);
    if(notificationMessage && notificationListener != nil){
      lastStoredNotification = notificationMessage;
      notificationListener(@[[CountlyReactNative toJSON:notificationMessage]]);
    }else{
      lastStoredNotification = notificationMessage;
    }
    if(notificationMessage){
      if(notificationIDs == nil){
        notificationIDs = [[NSMutableArray alloc] init];
      }
      if ([[notificationMessage allKeys] containsObject:@"c"]) {
        NSDictionary* countlyPayload = notificationMessage[@"c"];
        if ([[countlyPayload allKeys] containsObject:@"c"]) {
          NSString *notificationID = countlyPayload[@"i"];
          [notificationIDs insertObject:notificationID atIndex:[notificationIDs count]];
        }
      }
    }
}
+ (NSString *) toJSON: (NSDictionary  *) json{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];

    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
        return [NSString stringWithFormat:@"{'error': '%@'}", error];
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    }
}
+ (void) log: (NSString *) theMessage{
    if(config.enableDebug == YES){
        NSLog(@"[CountlyReactNative] %@", theMessage);
    }
}
RCT_EXPORT_METHOD(start)
{
  // [Countly.sharedInstance resume];
}

RCT_EXPORT_METHOD(stop)
{
  // [Countly.sharedInstance suspend];
}

RCT_EXPORT_METHOD(changeDeviceId:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* newDeviceID = [arguments objectAtIndex:0];
  NSString* onServerString = [arguments objectAtIndex:1];
  if ([onServerString  isEqual: @"1"]) {
    [Countly.sharedInstance setNewDeviceID:newDeviceID onServer: YES];
  }else{
    [Countly.sharedInstance setNewDeviceID:newDeviceID onServer: NO];
  }
  });
}

RCT_EXPORT_METHOD(userLoggedIn:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* deviceID = [arguments objectAtIndex:0];
  [Countly.sharedInstance userLoggedIn:deviceID];
  });
}
RCT_EXPORT_METHOD(userLoggedOut:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  [Countly.sharedInstance userLoggedOut];
  });
}
RCT_EXPORT_METHOD(setHttpPostForced:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* isPost = [arguments objectAtIndex:0];
  if (config == nil){
    config = CountlyConfig.new;
  }

  if ([isPost  isEqual: @"1"]) {
    config.alwaysUsePOST = YES;
  }else{
    config.alwaysUsePOST = NO;
  }
  });
}

RCT_EXPORT_METHOD(enableParameterTamperingProtection:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* salt = [arguments objectAtIndex:0];
  if (config == nil){
    config = CountlyConfig.new;
  }
  config.secretSalt = salt;
  });
}

RCT_EXPORT_METHOD(pinnedCertificates:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* certificateName = [arguments objectAtIndex:0];
  if (config == nil){
    config = CountlyConfig.new;
  }
  config.pinnedCertificates = @[certificateName];
  });
}

RCT_EXPORT_METHOD(startEvent:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* startEvent = [arguments objectAtIndex:0];
  [Countly.sharedInstance startEvent:startEvent];
  });
}

RCT_EXPORT_METHOD(cancelEvent:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* cancelEvent = [arguments objectAtIndex:0];
  [Countly.sharedInstance cancelEvent:cancelEvent];
  });
}

/*
RCT_EXPORT_METHOD(endEvent:(NSDictionary*)options)
{
  NSString* eventName = "";

  if ([options valueForKey:@"eventName"] == nil) {
    // log error as in android method
    return;
  }
  else {
    eventName = (String) [options valueForKey:@"eventName"];
  }
  int eventCount = 1;
  if ([options valueForKey:@"eventCount"] != nil) {
    eventCount = (int) [options valueForKey:@"eventCount"]
  }
  double eventSum = 0;
  if ([options valueForKey:@"eventSum"] != nil) {
    eventSum = (double) [options valueForKey:@"eventSum"]
  }
  NSMutableDictionary *segments = [NSMutableDictionary dictionary]
  if ([options valueForKey:@"segments"] != nil) {
    NSDictionary *segmentation = (NSDictionary*) [options valueForKey:@"segments"];
    [segments addEntriesFromDictionary:segmentation];
  }
  [Countly.sharedInstance endEvent:eventName segmentation:segments count:eventCount sum:eventSum];
}
*/

RCT_EXPORT_METHOD(endEvent:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* eventType = [arguments objectAtIndex:0];

  if ([eventType  isEqual: @"event"]) {
    NSString* eventName = [arguments objectAtIndex:1];
    [Countly.sharedInstance endEvent:eventName];
  }
  else if ([eventType  isEqual: @"eventWithSum"]){
    NSString* eventName = [arguments objectAtIndex:1];

    NSString* countString = [arguments objectAtIndex:2];
    int countInt = [countString intValue];

    NSString* sumString = [arguments objectAtIndex:3];
    float sumInt = [sumString floatValue];

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [Countly.sharedInstance endEvent:eventName segmentation:dict count:countInt sum:sumInt];
  }
  else if ([eventType  isEqual: @"eventWithSegment"]){
    NSString* eventName = [arguments objectAtIndex:1];

    NSString* countString = [arguments objectAtIndex:2];
    int countInt = [countString intValue];

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for(int i=4,il=(int)arguments.count;i<il;i+=2){
      dict[[arguments objectAtIndex:i]] = [arguments objectAtIndex:i+1];
    }

    [Countly.sharedInstance endEvent:eventName segmentation:dict count:countInt sum:0];
  }
  else if ([eventType  isEqual: @"eventWithSumSegment"]){
    NSString* eventName = [arguments objectAtIndex:1];

    NSString* countString = [arguments objectAtIndex:2];
    int countInt = [countString intValue];

    NSString* sumString = [arguments objectAtIndex:3];
    float sumInt = [sumString floatValue];

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for(int i=4,il=(int)arguments.count;i<il;i+=2){
      dict[[arguments objectAtIndex:i]] = [arguments objectAtIndex:i+1];
    }

    [Countly.sharedInstance endEvent:eventName segmentation:dict count:countInt sum:sumInt];
  }
  else{
  }
  });
}

RCT_EXPORT_METHOD(setLocation:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* countryCode = [arguments objectAtIndex:0];
  NSString* city = [arguments objectAtIndex:1];
  NSString* locationString = [arguments objectAtIndex:2];
  NSString* ipAddress = [arguments objectAtIndex:3];

  if([@"null" isEqualToString:city]){
      city = nil;
  }
  if([@"null" isEqualToString:countryCode]){
      countryCode = nil;
  }
  if([@"null" isEqualToString:locationString]){
      locationString = nil;
  }
  if([@"null" isEqualToString:ipAddress]){
      ipAddress = nil;
  }

  if(locationString != nil && [locationString containsString:@","]){
      @try{
          NSArray *locationArray = [locationString componentsSeparatedByString:@","];
          NSString* latitudeString = [locationArray objectAtIndex:0];
          NSString* longitudeString = [locationArray objectAtIndex:1];

          double latitudeDouble = [latitudeString doubleValue];
          double longitudeDouble = [longitudeString doubleValue];
          [Countly.sharedInstance recordLocation:(CLLocationCoordinate2D){latitudeDouble,longitudeDouble}];
      }
      @catch(NSException *exception){
          NSLog(@"[Countly] Invalid location: %@", locationString);
      }
  }

  [Countly.sharedInstance recordCity:city andISOCountryCode:countryCode];
  [Countly.sharedInstance recordIP:ipAddress];
  });
}

RCT_EXPORT_METHOD(disableLocation)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  [Countly.sharedInstance disableLocationInfo];
  });
}

RCT_EXPORT_METHOD(enableCrashReporting)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  if (config == nil){
    config = CountlyConfig.new;
  }
  config.features = @[CLYCrashReporting];
  });
}

RCT_EXPORT_METHOD(addCrashLog:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* logs = [arguments objectAtIndex:0];
  [Countly.sharedInstance recordCrashLog:logs];
  });
}

RCT_EXPORT_METHOD(logException:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* execption = [arguments objectAtIndex:0];
  NSString* nonfatal = [arguments objectAtIndex:1];
  NSArray *nsException = [execption componentsSeparatedByString:@"\n"];

  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

  for(int i=2,il=(int)arguments.count;i<il;i+=2){
      dict[[arguments objectAtIndex:i]] = [arguments objectAtIndex:i+1];
  }
  [dict setObject:nonfatal forKey:@"nonfatal"];

  NSException* myException = [NSException exceptionWithName:@"Exception" reason:execption userInfo:dict];

  [Countly.sharedInstance recordHandledException:myException withStackTrace: nsException];
  });
}

RCT_EXPORT_METHOD(logJSException:(NSString *)errTitle withMessage:(NSString *)message withStack:(NSString *)stackTrace) {
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSException* myException = [NSException exceptionWithName:errTitle reason:message
                              userInfo:@{@"nonfatal":@"1"}];
  NSArray *stack = [stackTrace componentsSeparatedByString:@"\n"];
  [Countly.sharedInstance recordHandledException:myException withStackTrace:stack];
  });
}

RCT_EXPORT_METHOD(userData_setProperty:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* keyName = [arguments objectAtIndex:0];
  NSString* keyValue = [arguments objectAtIndex:1];

  [Countly.user set:keyName value:keyValue];
  [Countly.user save];
  });
}

RCT_EXPORT_METHOD(userData_increment:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* keyName = [arguments objectAtIndex:0];

  [Countly.user increment:keyName];
  [Countly.user save];
  });
}

RCT_EXPORT_METHOD(userData_incrementBy:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* keyName = [arguments objectAtIndex:0];
  NSString* keyValue = [arguments objectAtIndex:1];
  int keyValueInteger = [keyValue intValue];

  [Countly.user incrementBy:keyName value:[NSNumber numberWithInt:keyValueInteger]];
  [Countly.user save];
  });
}

RCT_EXPORT_METHOD(userData_multiply:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* keyName = [arguments objectAtIndex:0];
  NSString* keyValue = [arguments objectAtIndex:1];
  int keyValueInteger = [keyValue intValue];

  [Countly.user multiply:keyName value:[NSNumber numberWithInt:keyValueInteger]];
  [Countly.user save];
  });
}

RCT_EXPORT_METHOD(userData_saveMax:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* keyName = [arguments objectAtIndex:0];
  NSString* keyValue = [arguments objectAtIndex:1];
  int keyValueInteger = [keyValue intValue];

  [Countly.user max:keyName value:[NSNumber numberWithInt:keyValueInteger]];
  [Countly.user save];
  });
}

RCT_EXPORT_METHOD(userData_saveMin:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* keyName = [arguments objectAtIndex:0];
  NSString* keyValue = [arguments objectAtIndex:1];
  int keyValueInteger = [keyValue intValue];

  [Countly.user min:keyName value:[NSNumber numberWithInt:keyValueInteger]];
  [Countly.user save];
  });
}

RCT_EXPORT_METHOD(userData_setOnce:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* keyName = [arguments objectAtIndex:0];
  NSString* keyValue = [arguments objectAtIndex:1];

  [Countly.user setOnce:keyName value:keyValue];
  [Countly.user save];
  });
}
RCT_EXPORT_METHOD(userData_pushUniqueValue:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* keyName = [arguments objectAtIndex:0];
  NSString* keyValue = [arguments objectAtIndex:1];

  [Countly.user pushUnique:keyName value:keyValue];
  [Countly.user save];
  });
}
RCT_EXPORT_METHOD(userData_pushValue:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* keyName = [arguments objectAtIndex:0];
  NSString* keyValue = [arguments objectAtIndex:1];

  [Countly.user push:keyName value:keyValue];
  [Countly.user save];
  });
}
RCT_EXPORT_METHOD(userData_pullValue:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* keyName = [arguments objectAtIndex:0];
  NSString* keyValue = [arguments objectAtIndex:1];

  [Countly.user pull:keyName value:keyValue];
  [Countly.user save];
  });
}



RCT_EXPORT_METHOD(demo:(NSArray*)arguments)
{

}

RCT_EXPORT_METHOD(setRequiresConsent:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  if (config == nil){
    config = CountlyConfig.new;
  }
  BOOL consentFlag = [[arguments objectAtIndex:0] boolValue];
  config.requiresConsent = consentFlag;
  });
}

RCT_EXPORT_METHOD(giveConsent:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  [Countly.sharedInstance giveConsentForFeatures:arguments];
  });
}

RCT_EXPORT_METHOD(removeConsent:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  [Countly.sharedInstance cancelConsentForFeatures:arguments];
  });
}

RCT_EXPORT_METHOD(giveAllConsent)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  [Countly.sharedInstance giveConsentForAllFeatures];
  });
}

RCT_EXPORT_METHOD(removeAllConsent)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  [Countly.sharedInstance cancelConsentForAllFeatures];
  });
}

RCT_EXPORT_METHOD(remoteConfigUpdate:(NSArray*)arguments callback:(RCTResponseSenderBlock)callback)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  [Countly.sharedInstance updateRemoteConfigWithCompletionHandler:^(NSError * error)
  {
      if (!error)
      {
          NSArray *result = @[@"Remote Config is updated and ready to use!"];
          callback(@[result]);
      }
      else
      {
          NSString* returnString = [NSString stringWithFormat:@"There was an error while updating Remote Config: %@", error];
          NSArray *result = @[returnString];
          callback(@[result]);
      }
  }];
  });
}

RCT_EXPORT_METHOD(updateRemoteConfigForKeysOnly:(NSArray*)arguments callback:(RCTResponseSenderBlock)callback)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSMutableArray *randomSelection = [[NSMutableArray alloc] init];
  for (int i = 0; i < (int)arguments.count; i++){
      [randomSelection addObject:[arguments objectAtIndex:i]];
  }
  NSArray *keyNames = [randomSelection copy];
  [Countly.sharedInstance updateRemoteConfigOnlyForKeys:keyNames completionHandler:^(NSError * error)
  {
      if (!error)
      {
          NSArray *result = @[@"Remote Config is updated only for given keys and ready to use!"];
          callback(@[result]);
      }
      else
      {
          NSString* returnString = [NSString stringWithFormat:@"There was an error while updating Remote Config: %@", error];
          NSArray *result = @[returnString];
          callback(@[result]);
      }
  }];
  });
}

RCT_EXPORT_METHOD(updateRemoteConfigExceptKeys:(NSArray*)arguments callback:(RCTResponseSenderBlock)callback)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSMutableArray *randomSelection = [[NSMutableArray alloc] init];
  for (int i = 0; i < (int)arguments.count; i++){
      [randomSelection addObject:[arguments objectAtIndex:i]];
  }
  NSArray *keyNames = [randomSelection copy];
  [Countly.sharedInstance updateRemoteConfigExceptForKeys:keyNames completionHandler:^(NSError * error)
  {
      if (!error)
      {
          NSArray *result = @[@"Remote Config is updated except for given keys and ready to use !"];
          callback(@[result]);
      }
      else
      {
          NSString* returnString = [NSString stringWithFormat:@"There was an error while updating Remote Config: %@", error];
          NSArray *result = @[returnString];
          callback(@[result]);
      }
  }];
  });
}

RCT_EXPORT_METHOD(getRemoteConfigValueForKey:(NSArray*)arguments callback:(RCTResponseSenderBlock)callback)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  id value = [Countly.sharedInstance remoteConfigValueForKey:[arguments objectAtIndex:0]];
  if(value){
    callback(@[value]);
  }
  else{
    NSString *value = @"ConfigKeyNotFound";
    callback(@[value]);
  }
  });
}

RCT_EXPORT_METHOD(showStarRating:(NSArray*)arguments callback:(RCTResponseSenderBlock)callback)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
    [Countly.sharedInstance askForStarRating:^(NSInteger rating){
      callback(@[[@(rating) stringValue]]);
    }];
  });
}

RCT_EXPORT_METHOD(showFeedbackPopup:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* FEEDBACK_WIDGET_ID = [arguments objectAtIndex:0];
  [Countly.sharedInstance presentFeedbackWidgetWithID:FEEDBACK_WIDGET_ID completionHandler:^(NSError* error)
  {

  }];
  });
}

RCT_EXPORT_METHOD(setEventSendThreshold:(NSArray*)arguments)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
  NSString* size = [arguments objectAtIndex:0];
  int sizeInt = [size intValue];
  if (config == nil){
    config = CountlyConfig.new;
  }
  config.eventSendThreshold = sizeInt;
  });
}

RCT_REMAP_METHOD(isInitialized,
                 isInitializedWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
    id result = [NSNumber numberWithBool:CountlyCommon.sharedInstance.hasStarted] ;
    resolve(result);
  });
}


RCT_REMAP_METHOD(hasBeenCalledOnStart,
                 hasBeenCalledOnStartWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
    id result = [NSNumber numberWithBool:CountlyCommon.sharedInstance.hasStarted] ;
    resolve(result);
  });
}

RCT_EXPORT_METHOD(remoteConfigClearValues:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^ {
    [CountlyRemoteConfig.sharedInstance clearCachedRemoteConfig];
    resolve(@"Remote Config Cleared.");
  });
}
@end
