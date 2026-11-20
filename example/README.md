# opoinstall_flutter_plugin 示例工程

演示 `opoinstall_flutter_plugin` 的初始化、拉起回调、安装参数、注册统计、效果点和分享上报接口。

## 运行

```bash
cd example
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## 配置

- Android：在 `example/android/app/build.gradle` 中配置 `OPOINSTALL_APPKEY`
- iOS：在 `example/ios/Runner/Info.plist` 中配置 `com.opoinstall.APP_KEY`
- iOS 一键拉起：`Runner.entitlements` 中配置关联域名，`Info.plist` 中配置 scheme

完整集成说明见 [../README.md](../README.md)。
