package io.opoinstall.opoinstall_flutter_plugin;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import com.opoinstall.api.OpoData;
import com.opoinstall.api.OpoError;
import com.opoinstall.api.OpoInstall;
import com.opoinstall.api.ResultCallBack;

/**
 * OpoinstallFlutterPlugin
 */
public class OpoinstallFlutterPlugin
        implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener {

    private static final String TAG = "flutter_global";

    private static final String METHOD_WAKEUP_NOTIFICATION = "onWakeupNotification";
    private static final String METHOD_INSTALL_NOTIFICATION = "onInstallNotification";

    private MethodChannel channel = null;
    private ActivityPluginBinding activityPluginBinding;
    private FlutterPluginBinding flutterPluginBinding;
    private Context applicationContext;
    private Intent intentHolder = null;

    // SDK 是否已执行 initialize（延迟到用户同意隐私政策后调用 init/getInstall 时执行）
    private volatile boolean sdkInitialized = false;
    // 是否已调用 start，start 之后才能处理拉起参数
    private volatile boolean initialized = false;
    // Dart 侧是否已调用 init（可能在 Activity 未 attach 时调用）
    private boolean initRequested = false;

    private boolean debuggable = true;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        flutterPluginBinding = binding;
        applicationContext = binding.getApplicationContext();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "opoinstall_flutter_global");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activityPluginBinding = binding;
        activityPluginBinding.addOnNewIntentListener(this);
        if (initRequested && !initialized) {
            startSdk();
        }
        Activity activity = binding.getActivity();
        if (activity != null) {
            wakeup(activity.getIntent());
        }
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activityPluginBinding = binding;
        activityPluginBinding.addOnNewIntentListener(this);
    }

    @Override
    public void onMethodCall(MethodCall call, @NonNull final Result result) {
        debugLog("invoke " + call.method);
        if ("setDebug".equalsIgnoreCase(call.method)) {
            Boolean enabled = call.argument("enabled");
            debuggable = enabled == null || enabled;
            OpoInstall.setDebug(debuggable);
            result.success("OK");
            return;
        }
        ensureInitialized();
        if ("disableFetchClipData".equalsIgnoreCase(call.method)) {
            OpoInstall.getInstance().disableFetchClipData();
            result.success("OK");
        } else if ("init".equalsIgnoreCase(call.method)) {
            init();
            result.success("OK");
        } else if ("registerWakeup".equalsIgnoreCase(call.method)) {
            // 保留旧接口，拉起监听由 Activity/DeepLink 回调完成
            result.success("OK");
        } else if ("getInstall".equalsIgnoreCase(call.method)) {
            Integer seconds = call.argument("seconds");
            OpoInstall.getInstance().getInstallParam(seconds == null ? 0 : seconds,
                    new ResultCallBack<OpoData>() {
                        @Override
                        public void onResult(OpoData opData) {
                            channel.invokeMethod(METHOD_INSTALL_NOTIFICATION, data2Map(opData));
                        }

                        @Override
                        public void onError(OpoError opError) {
                            channel.invokeMethod(METHOD_INSTALL_NOTIFICATION, error2Map(opError));
                        }
                    });
            result.success("OK");
        } else if ("reportRegister".equalsIgnoreCase(call.method)) {
            OpoInstall.getInstance().register();
            result.success("OK");
        } else if ("reportEffectPoint".equalsIgnoreCase(call.method)) {
            String pointId = call.argument("pointId");
            Integer pointValue = call.argument("pointValue");
            if (TextUtils.isEmpty(pointId) || pointValue == null) {
                Log.w(TAG, "pointId is empty or pointValue is null");
            } else {
                Map<String, String> extraMap = call.argument("extras");
                OpoInstall.getInstance().saveEvent(pointId, pointValue, extraMap);
            }
            result.success("OK");
        } else if ("reportShare".equalsIgnoreCase(call.method)) {
            String shareCode = call.argument("shareCode");
            String sharePlatform = call.argument("platform");
            final Map<String, Object> data = new HashMap<>();
            if (TextUtils.isEmpty(shareCode) || TextUtils.isEmpty(sharePlatform)) {
                data.put("message", "shareCode or platform is empty");
                data.put("shouldRetry", false);
                result.success(data);
            } else {
                OpoInstall.getInstance().reportShare(shareCode, sharePlatform, new ResultCallBack<Boolean>() {
                    @Override
                    public void onResult(Boolean unused) {
                        data.put("shouldRetry", false);
                        result.success(data);
                    }

                    @Override
                    public void onError(OpoError opError) {
                        result.success(error2Map(opError));
                    }
                });
            }
        } else {
            result.notImplemented();
        }
    }

    /**
     * 延迟初始化 SDK：首次调用 SDK 能力时再 initialize，避免 App 启动即采集数据
     */
    private void ensureInitialized() {
        if (sdkInitialized || applicationContext == null) {
            return;
        }
        OpoInstall.initialize(applicationContext);
        sdkInitialized = true;
    }

    private void init() {
        initRequested = true;
        ensureInitialized();
        startSdk();
    }

    private void startSdk() {
        if (activityPluginBinding == null) {
            return;
        }
        Activity activity = activityPluginBinding.getActivity();
        if (activity == null) {
            return;
        }
        OpoInstall.getInstance().start(activity);
        initialized = true;
        if (intentHolder != null) {
            wakeup(intentHolder);
            intentHolder = null;
        }
    }

    @Override
    public boolean onNewIntent(Intent intent) {
        debugLog("onNewIntent");
        wakeup(intent);
        return false;
    }

    private void wakeup(Intent intent) {
        if (intent == null) {
            return;
        }
        if (initialized) {
            OpoInstall.getInstance().handleDeepLink(intent, new ResultCallBack<OpoData>() {
                @Override
                public void onResult(OpoData opData) {
                    channel.invokeMethod(METHOD_WAKEUP_NOTIFICATION, data2Map(opData));
                }

                @Override
                public void onError(OpoError opError) {
                    channel.invokeMethod(METHOD_WAKEUP_NOTIFICATION, error2Map(opError));
                }
            });
        } else {
            intentHolder = intent;
        }
    }

    private static Map<String, Object> data2Map(OpoData data) {
        Map<String, Object> result = new HashMap<>();
        result.put("shouldRetry", false);
        if (data != null) {
            result.put("channelCode", data.getChannelCode());
            result.put("bindData", data.getBindData());
        }
        return result;
    }

    private static Map<String, Object> error2Map(OpoError error) {
        Map<String, Object> result = new HashMap<>();
        result.put("shouldRetry", error.shouldRetry());
        result.put("message", error.getErrorMsg());
        return result;
    }

    private void debugLog(String message) {
        if (debuggable) {
            Log.d(TAG, message);
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onDetachedFromActivity() {
        activityPluginBinding.removeOnNewIntentListener(this);
        activityPluginBinding = null;
    }
}
