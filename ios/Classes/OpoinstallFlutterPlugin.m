#import <UIKit/UIKit.h>

#import "OpoinstallFlutterPlugin.h"

#import "OpoInstallSDK.h"

typedef NS_ENUM(NSUInteger, OpoInstallSDKPluginMethod) {
    OpoInstallSDKMethodInit,
    OpoInstallSDKMethodGetInstallParams,
    OpoInstallSDKMethodReportRegister,
    OpoInstallSDKMethodReportEffectPoint,
    OpoInstallSDKMethodReportShare,
    OpoInstallSDKMethodSetDebug
};

@interface OpoinstallFlutterPlugin () <OpoInstallDelegate>
@property (strong, nonatomic, readonly) NSDictionary *methodDict;
@property (strong, nonatomic) FlutterMethodChannel * flutterMethodChannel;
@property (assign, nonatomic) BOOL isOnWakeup;
@property (copy, nonatomic)NSDictionary *cacheDic;


@end

static FlutterMethodChannel * FLUTTER_METHOD_CHANNEL;

@implementation OpoinstallFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel * channel = [FlutterMethodChannel methodChannelWithName:@"opoinstall_flutter_plugin" binaryMessenger:[registrar messenger]];
    OpoinstallFlutterPlugin* instance = [[OpoinstallFlutterPlugin alloc] init];
    [registrar addApplicationDelegate:instance];
    instance.flutterMethodChannel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initData];
    }
    return self;
}

- (void)initData {
    _methodDict = @{
                    @"init"                   :      @(OpoInstallSDKMethodInit),
                    @"getInstall"             :      @(OpoInstallSDKMethodGetInstallParams),
                    @"reportRegister"         :      @(OpoInstallSDKMethodReportRegister),
                    @"reportEffectPoint"      :      @(OpoInstallSDKMethodReportEffectPoint),
                    @"reportShare"            :      @(OpoInstallSDKMethodReportShare),
                    @"setDebug"               :      @(OpoInstallSDKMethodSetDebug)
                    };
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSNumber *methodType = self.methodDict[call.method];
    if (methodType) {
        switch (methodType.intValue) {
            case OpoInstallSDKMethodInit:
            {
                [self initOpoInstall];
                
                NSDictionary *dict = nil;
                @synchronized(self){
                    if (self.cacheDic) {
                        dict = [self.cacheDic copy];
                    }
                }
                self.isOnWakeup = YES;
                if (dict.count != 0) {
                    [self.flutterMethodChannel invokeMethod:@"onWakeupNotification" arguments:dict];
                    self.cacheDic = nil;
                }
                result(nil);
                break;
            }
            case OpoInstallSDKMethodGetInstallParams:
            {
                NSNumber *timeNum = (NSNumber *) call.arguments[@"seconds"];
                double time = [timeNum doubleValue];
                if (time <= 0) {
                    time = 15;
                }
                [[OpoInstallSDK defaultManager] getInstallParmsWithTimeoutInterval:time completed:^(OpoInstallData * _Nullable appData) {
                    [self installParamsResponse:appData];
                }];
                result(nil);
                break;
            }
            case OpoInstallSDKMethodReportRegister:
            {
                [OpoInstallSDK reportRegister];
                result(nil);
                break;
            }
            case OpoInstallSDKMethodReportEffectPoint:
            {
                NSDictionary * args = call.arguments;
                NSNumber * pointValue = (NSNumber *) args[@"pointValue"];
                if ([args.allKeys containsObject:@"extras"]) {
                    [[OpoInstallSDK defaultManager] reportEffectPoint:(NSString *)args[@"pointId"] effectValue:[pointValue longValue] effectDictionary:(NSDictionary *)args[@"extras"]];
                }else{
                    [[OpoInstallSDK defaultManager] reportEffectPoint:(NSString *)args[@"pointId"] effectValue:[pointValue longValue]];
                }
                result(nil);
                break;
            }
            case OpoInstallSDKMethodReportShare:
            {
                NSDictionary * args = call.arguments;
                [[OpoInstallSDK defaultManager] reportShareParametersWithShareCode:(NSString *)args[@"shareCode"] sharePlatform:(NSString *)args[@"platform"] completed:^(NSInteger code, NSString * _Nullable msg) {
                    BOOL shouldRetry = NO;
                    if (code==-1) {
                        shouldRetry = YES;
                    }
                    NSDictionary * resultDic = @{@"shouldRetry":@(shouldRetry),@"message":msg ?: @""};
                    result(resultDic);
                }];
                break;
            }
            case OpoInstallSDKMethodSetDebug:
            {
                NSNumber *enabled = (NSNumber *) call.arguments[@"enabled"];
                [OpoInstallSDK setDebug:enabled.boolValue];
                result(nil);
                break;
            }
            default:
            {
                break;
            }
        }
    } else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - Opoinstall Notify Flutter Method
- (void)installParamsResponse:(OpoInstallData *) appData {
    NSDictionary *args = [self convertInstallArguments:appData];
    [self.flutterMethodChannel invokeMethod:@"onInstallNotification" arguments:args];
}

- (void)wakeUpParamsResponse:(OpoInstallData *) appData {
    NSDictionary *args = [self convertInstallArguments:appData];
    if (self.isOnWakeup) {
        [self.flutterMethodChannel invokeMethod:@"onWakeupNotification" arguments:args];
    }else{
        @synchronized(self){
            self.cacheDic = [[NSDictionary alloc]init];
            self.cacheDic = args;
        }
    }
}

- (NSDictionary *)convertInstallArguments:(OpoInstallData *) appData {
    NSString *channelCode = @"";
    NSString *bindData = @"";
    if (appData.channelCode != nil) {
        channelCode = appData.channelCode;
    }
    if (appData.data != nil) {
        bindData = [self jsonStringWithObject:appData.data];
    }
    BOOL shouldRetry = NO;
    if (appData.opCode==OPOCode_timeout) {
        shouldRetry = YES;
    }
    NSDictionary * dict = @{@"channelCode":channelCode,@"bindData":bindData,@"shouldRetry":@(shouldRetry)};
    return dict;
}

- (NSString *)jsonStringWithObject:(id)jsonObject {
    id arguments = (jsonObject == nil ? [NSNull null] : jsonObject);
    NSArray* argumentsWrappedInArr = [NSArray arrayWithObject:arguments];
    NSString* argumentsJSON = [self cp_JSONString:argumentsWrappedInArr];
    if (argumentsJSON.length>2) {argumentsJSON = [argumentsJSON substringWithRange:NSMakeRange(1, [argumentsJSON length] - 2)];}
    return argumentsJSON;
}

- (NSString *)cp_JSONString:(NSArray *)array {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if ([jsonString length] > 0 && error == nil){
        return jsonString;
    } else {
        return @"";
    }
}

#pragma mark - Opoinstall API
//通过OpoInstall获取已经安装App被唤醒时的参数（如果是通过渠道页面唤醒App时，会返回渠道编号）
-(void)getWakeUpParams:(OpoInstallData *) appData{
    [self wakeUpParamsResponse:appData];
}

+ (BOOL)handLinkURL:(NSURL *) url {
    return [OpoInstallSDK handLinkURL:url];
}

+ (BOOL)continueUserActivity:(NSUserActivity *) userActivity {
    return [OpoInstallSDK continueUserActivity:userActivity];
}

- (void)initOpoInstall{
    [OpoInstallSDK initWithDelegate:self];
}

#pragma mark - Application Delegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    [OpoinstallFlutterPlugin handLinkURL:url];
    return NO;
}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    [OpoinstallFlutterPlugin handLinkURL:url];
    return NO;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
#if defined(__IPHONE_12_0)
    restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring> > * _Nullable restorableObjects))restorationHandler
#else
    restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler
#endif
{
    [OpoinstallFlutterPlugin continueUserActivity:userActivity];
    return NO;
}

+ (void)setUserActivityAndScheme:(NSDictionary *)launchOptions{
    if (launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey]) {
        NSDictionary *activityDic = [NSDictionary dictionaryWithDictionary:launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey]];

        if ([activityDic[UIApplicationLaunchOptionsUserActivityTypeKey] isEqual: NSUserActivityTypeBrowsingWeb]&&activityDic[@"UIApplicationLaunchOptionsUserActivityKey"]) {
            NSUserActivity *activity = [[NSUserActivity alloc]initWithActivityType:NSUserActivityTypeBrowsingWeb];
            activity = (NSUserActivity *)activityDic[@"UIApplicationLaunchOptionsUserActivityKey"];
            [OpoinstallFlutterPlugin continueUserActivity:activity];
        }
    }else if (launchOptions[UIApplicationLaunchOptionsURLKey]){
        NSURL *url = [[NSURL alloc]init];
        if ([launchOptions[UIApplicationLaunchOptionsURLKey] isKindOfClass:[NSURL class]]) {
            url = launchOptions[UIApplicationLaunchOptionsURLKey];
        }else if ([launchOptions[UIApplicationLaunchOptionsURLKey] isKindOfClass:[NSString class]]){
            url = [NSURL URLWithString:launchOptions[UIApplicationLaunchOptionsURLKey]];
        }
        [OpoinstallFlutterPlugin handLinkURL:url];
    }
}


@end
