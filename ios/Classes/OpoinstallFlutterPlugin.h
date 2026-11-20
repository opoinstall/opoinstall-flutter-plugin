#import <Flutter/Flutter.h>

#if __has_include(<Flutter/FlutterSceneLifeCycle.h>)
#import <Flutter/FlutterSceneLifeCycle.h>
#endif

#if __has_include(<Flutter/FlutterSceneLifeCycle.h>)
@interface OpoinstallFlutterPlugin : NSObject<FlutterPlugin, FlutterSceneLifeCycleDelegate>
#else
@interface OpoinstallFlutterPlugin : NSObject<FlutterPlugin>
#endif

/**
 * 处理 URI schemes
 * @param URL 系统回调传回的URL
 * @return bool URL是否被OpoInstall识别
 */
+ (BOOL)handLinkURL:(NSURL *) url;

/**
 * 处理 通用链接
 * @param userActivity 存储了页面信息，包括url
 * @return bool URL是否被OpoInstall识别
 */
+ (BOOL)continueUserActivity:(NSUserActivity *) userActivity;


+ (void)setUserActivityAndScheme:(NSDictionary *)launchOptions;

@end
