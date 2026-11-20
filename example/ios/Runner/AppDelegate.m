#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
//如果是swift，请在桥接文件（一般命名为XXX-Bridging-Header.h）中引入
#import <opoinstall_flutter_global/OpoinstallFlutterPlugin.h>


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
        
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}


//添加此方法以获取拉起参数
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler{
    //判断是否通过OpoInstall Universal Link 唤起App
    [OpoinstallFlutterPlugin continueUserActivity:userActivity];
    //其他第三方回调；
    return YES;
}

//适用目前所有iOS版本
-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    //判断是否通过OpoInstall URL Scheme 唤起App
    [OpoinstallFlutterPlugin handLinkURL:url];
    //其他第三方回调；
    return YES;
}
//iOS9以上，会优先走这个方法
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(nonnull NSDictionary *)options{
    //判断是否通过OpoInstall URL Scheme 唤起App
    [OpoinstallFlutterPlugin handLinkURL:url];
    //其他第三方回调；
    return YES;
}

@end
