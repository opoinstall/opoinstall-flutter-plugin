import 'dart:io';

import 'package:flutter/material.dart';
import 'package:opoinstall_flutter_plugin/opoinstall_flutter_plugin.dart';

/// 示例页面文案，按 [英文, 中文] 顺序存放，默认展示英文
const Map<String, List<String>> _texts = <String, List<String>>{
  'installHint': <String>[
    'Tap "Get Install Params" when your business flow needs it.',
    '在业务流程需要时点击“获取安装参数”。',
  ],
  'waitingWakeup': <String>['Waiting for wakeup callback...', '等待拉起回调...'],
  'requestingInstall': <String>['Requesting install params...', '正在获取安装参数...'],
  'registerSubmitted': <String>['Register event submitted.', '注册事件已上报。'],
  'enterEffectId': <String>['Please enter an effect point ID.', '请输入效果点 ID。'],
  'effectSubmitted': <String>['Effect point submitted.', '效果点已上报。'],
  'effectDetailSubmitted': <String>[
    'Detailed effect point submitted.',
    '效果点明细已上报。',
  ],
  'completeShare': <String>[
    'Please complete share code and platform.',
    '请填写分享码和分享平台。',
  ],
  'shareFinished': <String>['Share report finished.', '分享上报完成。'],
  'clipboardDisabled': <String>[
    'Clipboard fetch disabled on Android.',
    '已关闭 Android 端剪切板读取。',
  ],
  'installCallbackOk': <String>[
    'Install callback received successfully.',
    '安装回调获取成功。',
  ],
  'wakeupCallbackOk': <String>[
    'Wakeup callback received successfully.',
    '拉起回调获取成功。',
  ],
  'quickActions': <String>['Quick Actions', '快捷操作'],
  'quickActionsSub': <String>[
    'Common SDK operations grouped for demos and smoke tests.',
    '常用 SDK 操作，便于演示和快速验证。',
  ],
  'getInstall': <String>['Get Install Params', '获取安装参数'],
  'reportRegister': <String>['Report Register', '上报注册'],
  'reportEffect': <String>['Report Effect', '上报效果点'],
  'effectExtras': <String>['Effect + Extras', '效果点明细'],
  'reportShare': <String>['Report Share', '上报分享'],
  'disableClipboard': <String>['Disable Clipboard Fetch', '关闭剪切板读取'],
  'demoSettings': <String>['Demo Settings', '演示设置'],
  'demoSettingsSub': <String>[
    'Adjust the most common parameters without editing code.',
    '无需改代码即可调整常用参数。',
  ],
  'installTimeout': <String>['Install Timeout (s)', '安装参数超时（秒）'],
  'debugLogging': <String>['Debug logging', '调试日志'],
  'enabled': <String>['enabled', '已开启'],
  'disabled': <String>['disabled', '已关闭'],
  'debugSubtitle': <String>[
    'Toggles the native SDK debug log switch.',
    '控制原生 SDK 调试日志开关。',
  ],
  'enableDebug': <String>['Enable native debug output', '开启原生调试日志'],
  'effectId': <String>['Effect Point ID', '效果点 ID'],
  'effectValue': <String>['Effect Point Value', '效果点数值'],
  'shareCode': <String>['Share Code', '分享码'],
  'sharePlatform': <String>['Share Platform', '分享平台'],
  'callbackConsole': <String>['Callback Console', '回调控制台'],
  'callbackConsoleSub': <String>[
    'Put install and wakeup results at the top so the demo answers the main question first.',
    '安装与拉起结果放在最上方，便于直接查看。',
  ],
  'installCallback': <String>['Install Callback', '安装回调'],
  'wakeupCallback': <String>['Wakeup Callback', '拉起回调'],
};

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final OpoinstallFlutterPlugin _opoinstallFlutterPlugin =
      OpoinstallFlutterPlugin();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _effectIdController = TextEditingController(
    text: 'effect_test',
  );
  final TextEditingController _effectValueController = TextEditingController(
    text: '1',
  );
  final TextEditingController _shareCodeController = TextEditingController(
    text: '123456',
  );
  final TextEditingController _sharePlatformController = TextEditingController(
    text: 'WechatSession',
  );
  final TextEditingController _installSecondsController = TextEditingController(
    text: '10',
  );

  String? _wakeUpLog;
  String? _installLog;
  bool _debugEnabled = true;
  bool _isEnglish = true;

  String _t(String key) {
    final List<String>? value = _texts[key];
    if (value == null) {
      return key;
    }
    return value[_isEnglish ? 0 : 1];
  }

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  @override
  void dispose() {
    _effectIdController.dispose();
    _effectValueController.dispose();
    _shareCodeController.dispose();
    _sharePlatformController.dispose();
    _installSecondsController.dispose();
    super.dispose();
  }

  Future<void> _initPlatformState() async {
    _opoinstallFlutterPlugin.init(_wakeupHandler);
  }

  Future<void> _requestInstall() async {
    final int seconds =
        int.tryParse(_installSecondsController.text.trim()) ?? 10;
    setState(() {
      _installLog = _t('requestingInstall');
    });
    _opoinstallFlutterPlugin.install(_installHandler, seconds);
  }

  Future<void> _reportRegister() async {
    _opoinstallFlutterPlugin.reportRegister();
    _showNotice(_t('registerSubmitted'));
  }

  Future<void> _reportEffectPoint({required bool includeExtras}) async {
    final int pointValue =
        int.tryParse(_effectValueController.text.trim()) ?? 1;
    final String pointId = _effectIdController.text.trim();
    if (pointId.isEmpty) {
      _showNotice(_t('enterEffectId'));
      return;
    }

    if (includeExtras) {
      final Map<String, String> extraMap = <String, String>{
        'systemVersion': Platform.operatingSystemVersion,
        'flutterVersion': Platform.version,
      };
      _opoinstallFlutterPlugin.reportEffectPoint(pointId, pointValue, extraMap);
      _showNotice(_t('effectDetailSubmitted'));
      return;
    }

    _opoinstallFlutterPlugin.reportEffectPoint(pointId, pointValue);
    _showNotice(_t('effectSubmitted'));
  }

  Future<void> _reportShare() async {
    final String shareCode = _shareCodeController.text.trim();
    final String platform = _sharePlatformController.text.trim();
    if (shareCode.isEmpty || platform.isEmpty) {
      _showNotice(_t('completeShare'));
      return;
    }

    final Map<Object?, Object?> data =
        await _opoinstallFlutterPlugin.reportShare(shareCode, platform);
    _showNotice(
      '${_t('shareFinished')} shouldRetry=${data['shouldRetry']}, message=${data['message'] ?? 'OK'}',
    );
  }

  Future<void> _disableFetchClipData() async {
    _opoinstallFlutterPlugin.disableFetchClipData();
    _showNotice(_t('clipboardDisabled'));
  }

  void _showNotice(String message) {
    final ScaffoldMessengerState? messenger =
        _scaffoldMessengerKey.currentState;
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _buildResultText(Map<String, Object> data, {required String prefix}) {
    return '$prefix\n'
        'channelCode: ${data['channelCode']}\n'
        'bindData: ${data['bindData']}\n'
        'shouldRetry: ${data['shouldRetry']}\n'
        'updatedAt: ${_timestamp()}';
  }

  String _timestamp() {
    final DateTime now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(now.hour)}:${twoDigits(now.minute)}:${twoDigits(now.second)}';
  }

  Future<void> _installHandler(Map<String, Object> data) async {
    if (!mounted) return;
    setState(() {
      _installLog = _buildResultText(data, prefix: _t('installCallbackOk'));
    });
  }

  Future<void> _wakeupHandler(Map<String, Object> data) async {
    if (!mounted) return;
    setState(() {
      _wakeUpLog = _buildResultText(data, prefix: _t('wakeupCallbackOk'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0E7A74),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Color(0xFFF3EFE5),
                Color(0xFFE4F3EE),
                Color(0xFFD9E8F7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEnglish = !_isEnglish;
                            });
                          },
                          icon: const Icon(Icons.translate, size: 18),
                          label: Text(_isEnglish ? '中文' : 'English'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                          ),
                        ),
                      ),
                      _buildConsoleCard(),
                      const SizedBox(height: 20),
                      _buildControlPanel(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context) {
    return Column(
      children: <Widget>[
        _GlassCard(
          title: _t('quickActions'),
          subtitle: _t('quickActionsSub'),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _ActionChipButton(
                icon: Icons.download_rounded,
                label: _t('getInstall'),
                onPressed: _requestInstall,
              ),
              _ActionChipButton(
                icon: Icons.how_to_reg_rounded,
                label: _t('reportRegister'),
                onPressed: _reportRegister,
              ),
              _ActionChipButton(
                icon: Icons.auto_graph_rounded,
                label: _t('reportEffect'),
                onPressed: () => _reportEffectPoint(includeExtras: false),
              ),
              _ActionChipButton(
                icon: Icons.insights_rounded,
                label: _t('effectExtras'),
                onPressed: () => _reportEffectPoint(includeExtras: true),
              ),
              _ActionChipButton(
                icon: Icons.share_rounded,
                label: _t('reportShare'),
                onPressed: _reportShare,
              ),
              if (Platform.isAndroid)
                _ActionChipButton(
                  icon: Icons.content_paste_off_rounded,
                  label: _t('disableClipboard'),
                  onPressed: _disableFetchClipData,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _GlassCard(
          title: _t('demoSettings'),
          subtitle: _t('demoSettingsSub'),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _InputField(
                      controller: _installSecondsController,
                      label: _t('installTimeout'),
                      hint: '10',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF7F3),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${_t('debugLogging')}: ${_debugEnabled ? _t('enabled') : _t('disabled')}.',
                  style: const TextStyle(
                    color: Color(0xFF115E59),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _debugEnabled,
                contentPadding: EdgeInsets.zero,
                title: Text(_t('enableDebug')),
                subtitle: Text(_t('debugSubtitle')),
                onChanged: (bool value) {
                  setState(() {
                    _debugEnabled = value;
                  });
                  _opoinstallFlutterPlugin.setDebug(value);
                },
              ),
              const SizedBox(height: 8),
              _InputField(
                controller: _effectIdController,
                label: _t('effectId'),
                hint: 'effect_test',
              ),
              const SizedBox(height: 12),
              _InputField(
                controller: _effectValueController,
                label: _t('effectValue'),
                hint: '1',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _InputField(
                controller: _shareCodeController,
                label: _t('shareCode'),
                hint: '123456',
              ),
              const SizedBox(height: 12),
              _InputField(
                controller: _sharePlatformController,
                label: _t('sharePlatform'),
                hint: 'WechatSession',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsoleCard() {
    return _GlassCard(
      title: _t('callbackConsole'),
      subtitle: _t('callbackConsoleSub'),
      child: Column(
        children: <Widget>[
          _LogPanel(
            title: _t('installCallback'),
            color: const Color(0xFF0E7A74),
            content: _installLog ?? _t('installHint'),
          ),
          const SizedBox(height: 16),
          _LogPanel(
            title: _t('wakeupCallback'),
            color: const Color(0xFFB55D32),
            content: _wakeUpLog ?? _t('waitingWakeup'),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF8FAFC), width: 1.2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.4),
        ),
      ),
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel({
    required this.title,
    required this.color,
    required this.content,
  });

  final String title;
  final Color color;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            content,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
