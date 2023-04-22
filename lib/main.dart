// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:provider/provider.dart';

const _brandBlue = Color(0xFF1E88E5);
//bool _isDemoUsingDynamicColors = false;

CustomColors lightCustomColors = const CustomColors(danger: Color(0xFFE53935));
CustomColors darkCustomColors = const CustomColors(danger: Color(0xFFEF9A9A));

var brightness =
    SchedulerBinding.instance.platformDispatcher.platformBrightness;
bool isLightMode = brightness == Brightness.light;

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.danger,
  });

  final Color? danger;

  @override
  CustomColors copyWith({Color? danger}) {
    return CustomColors(
      danger: danger ?? this.danger,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      danger: Color.lerp(danger, other.danger, t),
    );
  }

  CustomColors harmonized(ColorScheme dynamic) {
    return copyWith(danger: danger!.harmonizeWith(dynamic.primary));
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BackEventNotifier(),
      child: const MainView(),
    ),
  );
}

class BackEventNotifier extends ChangeNotifier {
  bool _isBack = true;

  bool get isBack => _isBack;

  void add(bool value) {
    _isBack = value;
    notifyListeners();
  }
}

class MainView extends StatelessWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final WebViewController _controller;
  String finalUrl = 'https://flutter.dev';
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    const PlatformWebViewControllerCreationParams params =
        PlatformWebViewControllerCreationParams();

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(finalUrl));
    AndroidWebViewController.enableDebugging(true);
    (controller.platform as AndroidWebViewController)
        .setMediaPlaybackRequiresUserGesture(false);

    _controller = controller;
  }

  ThemeMode themeMode = ThemeMode.system;
  final GlobalKey _globalKey = GlobalKey();

  Future<bool> _onBack(BuildContext context) async {
    var canGoBack = await _controller.canGoBack();

    if (canGoBack) {
      _controller.goBack();
      return false;
    } else {
      BackEventNotifier localNotifier =
          Provider.of<BackEventNotifier>(context, listen: false);
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Confirmation',
            style: TextStyle(color: Colors.purple),
          ),
          content: const Text('Do you want to exit the app?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                localNotifier.add(false);
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                localNotifier.add(true);
              },
              child: const Text("Yes"),
            ),
          ],
        ),
      );
      return localNotifier.isBack;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;
        late Color addressBarColor;
        if (lightDynamic != null && darkDynamic != null) {
          // On Android S+ devices, use the provided dynamic color scheme.
          // (Recommended) Harmonize the dynamic color scheme' built-in semantic colors.
          lightColorScheme = lightDynamic.harmonized();
          // (Optional) Customize the scheme as desired. For example, one might
          // want to use a brand color to override the dynamic [ColorScheme.secondary].
          lightColorScheme = lightColorScheme.copyWith(secondary: _brandBlue);
          // (Optional) If applicable, harmonize custom colors.
          lightCustomColors = lightCustomColors.harmonized(lightColorScheme);

          // Repeat for the dark color scheme.
          darkColorScheme = darkDynamic.harmonized();
          darkColorScheme = darkColorScheme.copyWith(secondary: _brandBlue);
          darkCustomColors = darkCustomColors.harmonized(darkColorScheme);

          //_isDemoUsingDynamicColors = true; // ignore, only for demo purposes
        } else {
          // Otherwise, use fallback schemes.
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: _brandBlue,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: _brandBlue,
            brightness: Brightness.dark,
          );
        }

        if (isLightMode) {
          debugPrint('Light mode');
          addressBarColor = lightColorScheme.primaryContainer;
        } else if (!isLightMode) {
          debugPrint('Dark mode');
          addressBarColor = darkColorScheme.primaryContainer;
        }
        return ChangeNotifierProvider(
          create: (context) => BackEventNotifier(),
          child: MaterialApp(
            themeMode: themeMode,
            theme: ThemeData(
              colorScheme: lightDynamic ??
                  Theme.of(context)
                      .colorScheme
                      .copyWith(brightness: Brightness.light),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: darkDynamic ??
                  Theme.of(context)
                      .colorScheme
                      .copyWith(brightness: Brightness.dark),
              useMaterial3: true,
            ),
            home: WillPopScope(
              onWillPop: () => _onBack(context),
              child: Scaffold(
                appBar: AppBar(
                  elevation: 0,
                  toolbarHeight: 0,
                ),
                backgroundColor: Colors.white38,
                key: _globalKey,
                body: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Opacity(
                          opacity: 0.97,
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(80),
                            child: TextField(
                              controller: _textController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isLightMode
                                    ? lightColorScheme.primaryContainer
                                    : darkColorScheme.primaryContainer,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                labelText: 'blablabla',
                                labelStyle: TextStyle(
                                  background: Paint()
                                    ..color = addressBarColor
                                    ..strokeWidth = 30
                                    ..strokeJoin = StrokeJoin.round
                                    ..strokeCap = StrokeCap.round
                                    ..style = PaintingStyle.stroke,
                                ),
                                suffixIcon:
                                    PopupMenuButton(itemBuilder: (context) {
                                  return [
                                    const PopupMenuItem<int>(
                                      value: 0,
                                      child: Text("parangoricotirimijuaro"),
                                    ),
                                    const PopupMenuItem<int>(
                                      value: 1,
                                      child: Text("Settings"),
                                    ),
                                    const PopupMenuItem<int>(
                                      value: 2,
                                      child: Text("Logout"),
                                    ),
                                  ];
                                }, onSelected: (value) {
                                  if (value == 0) {
                                    debugPrint("My account menu is selected.");
                                  } else if (value == 1) {
                                    debugPrint("Settings menu is selected.");
                                  } else if (value == 2) {
                                    debugPrint("Logout menu is selected.");
                                  }
                                }),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(80),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (value) {
                                String finalUrl = value.toLowerCase();
                                if (!finalUrl.startsWith('http://') &&
                                    !finalUrl.startsWith('https://')) {
                                  finalUrl = 'https://$finalUrl';
                                }
                                _textController.text = finalUrl;
                                _controller.loadRequest(Uri.parse(finalUrl));
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
