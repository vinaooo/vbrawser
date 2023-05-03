// ignore_for_file: use_build_context_synchronously, library_prefixes
//import 'package:html/parser.dart' as htmlParser;

import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:html/parser.dart' show parse;
import 'package:dynamic_color/dynamic_color.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:provider/provider.dart';

import 'package:google_search_suggestions/google_search_suggestions.dart';

const _brandBlue = Color(0xFF1E88E5);

var brightness =
    SchedulerBinding.instance.platformDispatcher.platformBrightness;
bool isLightMode = brightness == Brightness.light;

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

  String _title = '';

  Future<String> getTitle() async {
    String title = '';
    try {
      String url = _textController.text;
      if (await canLaunchUrlString(url)) {
        final response = await http.get(Uri.parse(url));
        final document = parse(response.body);
        title = document.querySelector('title')!.text;
      }
    } catch (e) {
      debugPrint('Error getting title: $e');
    }
    setState(() {
      _title = title;
    });
    return title;
  }

  @override
  void initState() {
    super.initState();
    getTitle();
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

          // Repeat for the dark color scheme.
          darkColorScheme = darkDynamic.harmonized();
          darkColorScheme = darkColorScheme.copyWith(secondary: _brandBlue);

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
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Opacity(
                            opacity: 0.97,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: TextField(
                                onTap: () => MyBottomSheet.show(context),
                                controller: _textController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isLightMode
                                      ? lightColorScheme.primaryContainer
                                      : darkColorScheme.primaryContainer,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  helperText: _title,
                                  labelText: _title,
                                  alignLabelWithHint: true,
                                  labelStyle: TextStyle(
                                    background: Paint()
                                      ..color = addressBarColor
                                      ..strokeWidth = 30
                                      ..strokeJoin = StrokeJoin.round
                                      ..strokeCap = StrokeCap.round
                                      ..style = PaintingStyle.stroke,
                                  ),
                                  suffixIcon: SizedBox(
                                    width: 10,
                                    height: 10,
                                    child:
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
                                        debugPrint(
                                            "My account menu is selected.");
                                      } else if (value == 1) {
                                        debugPrint(
                                            "Settings menu is selected.");
                                      } else if (value == 2) {
                                        debugPrint("Logout menu is selected.");
                                      }
                                    }),
                                  ),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(80),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onSubmitted: (value) => handleSubmitted(value),
                              ),
                            )),
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

  Future<void> handleSubmitted(String value) async {
    String finalUrl = value.toLowerCase();
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }
    setState(() {
      _textController.text = finalUrl;
      _controller.loadRequest(Uri.parse(finalUrl));
      _title = 'Carregando...';
    });
    await getTitle();
  }
}

class MyBottomSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Add'),
                onTap: () {
                  // Perform add action
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                onTap: () {
                  // Perform edit action
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
                onTap: () {
                  // Perform delete action
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
