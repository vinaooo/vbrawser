import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:provider/provider.dart';

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
  String finalUrl = 'https://uol.com';
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
        return ChangeNotifierProvider(
          create: (context) => BackEventNotifier(),
          child: MaterialApp(
            themeMode: themeMode,
            theme: ThemeData(
              colorScheme: lightDynamic ?? Theme.of(context).colorScheme,
              brightness: Brightness.light,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: darkDynamic ?? Theme.of(context).colorScheme,
              useMaterial3: true,
              brightness: Brightness.dark,
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
                              decoration: const InputDecoration(
                                filled: true,
                                hintText: 'Enter a URL or search',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(80),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (value) {
                                finalUrl = value;
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
