import 'dart:convert';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _currentTheme = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      _currentTheme =
      _currentTheme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: _currentTheme,
          theme: lightDynamic != null
              ? AppTheme.lightTheme(lightDynamic)
              : AppTheme.lightTheme(),
          darkTheme: darkDynamic != null
              ? AppTheme.darkTheme(darkDynamic)
              : AppTheme.darkTheme(),
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebViewController _webViewController;
  String htmlContent = '';
  bool _isDarkMode = true;

  final List<String> buttonNames = [
    'Vocabulary',
    'Time Table',
    'Announcements',
    'Home Works',
    'Notes',
    'Books',
    'Extras',
    'App Info',
    'Feedback',
  ];

  final List<String> htmlFilePaths = [
    'assets/vocabulary.html',
    'assets/timetable.html',
    'assets/announcements.html',
    'assets/homework.html',
    'assets/notes.html',
    'assets/books.html',
    'assets/extras.html',
    'assets/app_info.html',
    'assets/feedback.html',
  ];

  final List<IconData> icons = [
    Icons.text_format,
    Icons.calendar_today,
    Icons.announcement,
    Icons.book,
    Icons.edit_note,
    Icons.book,
    Icons.link,
    Icons.info,
    Icons.star,
  ];

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF2D2F33))
      ..addJavaScriptChannel(
          'ThemeChannel',
          onMessageReceived: (JavaScriptMessage message) {
            if (message.message == "ThemeChanged") {
              reloadWebView(_webViewController);
            }
          });
    loadHtmlFile('assets/mobile_view.html');
  }

  Future<void> loadHtmlFile(String assetPath) async {
    String content = await rootBundle.loadString(assetPath);
    setState(() {
      htmlContent = content;
      _webViewController.loadRequest(
        Uri.dataFromString(content, mimeType: 'text/html', encoding: utf8),
      );
    });
  }

  void reloadWebView(WebViewController controller) async {
    String darkModeCss = _isDarkMode
        ? '''
      body {
        background-color: #2D2F33;
        color: white;
      }
    '''
        : '''
      body {
        background-color: white;
        color: black;
      }
    ''';

    String jsCode = '''
    <script>
       const styleElement = document.createElement('style');
       styleElement.innerHTML = `$darkModeCss`;
       document.head.appendChild(styleElement);
    </script>
    ''';

    await controller.loadRequest(Uri.dataFromString(
        '<html><head>$jsCode</head><body>${htmlContent}</body></html>',
        mimeType: 'text/html',
        encoding: utf8));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Online Corner',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              (context.findAncestorStateOfType<_MyAppState>() as _MyAppState)
                  .toggleTheme();
              setState(() {
                _isDarkMode = (context
                    .findAncestorStateOfType<_MyAppState>() as _MyAppState)
                    ._currentTheme ==
                    ThemeMode.dark;
              });
              reloadWebView(_webViewController);
              _webViewController.runJavaScript(
                  "window.dispatchEvent(new Event('ThemeChanged'));");
            },
            icon: Icon(
              (context.findAncestorStateOfType<_MyAppState>() as _MyAppState)
                  ._currentTheme ==
                  ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: SizedBox(
                    height: 200,
                    child: WebViewWidget(controller: _webViewController),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int index = 0; index < 9; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Row(
                        children: [
                          Icon(
                            icons[index],
                            size: 32,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              width: 200,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (index != 7) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WebViewScreen(
                                          htmlFilePath: htmlFilePaths[index],
                                          cardName: buttonNames[index],
                                          isDarkMode: _isDarkMode,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AppInfoScreen(),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.8),
                                  foregroundColor: theme
                                      .colorScheme
                                      .onPrimaryContainer,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15.0, horizontal: 3.0),
                                  textStyle: GoogleFonts.bricolageGrotesque(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100.0),
                                  ),
                                  minimumSize: const Size(100, 48),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    buttonNames[index],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String htmlFilePath;
  final String cardName;
  final bool isDarkMode;

  const WebViewScreen(
      {Key? key,
        required this.htmlFilePath,
        required this.cardName,
        required this.isDarkMode})
      : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.isDarkMode ? const Color(0xFF2D2F33) : Colors.white)
      ..addJavaScriptChannel(
          'ThemeChannel',
          onMessageReceived: (JavaScriptMessage message) {
            if (message.message == "ThemeChanged") {
              reloadWebView(_webViewController);
            }
          });
    loadHtmlFile(widget.htmlFilePath);
  }

  void reloadWebView(WebViewController controller) async {
    String darkModeCss = widget.isDarkMode
        ? '''
      body {
        background-color: #2D2F33;
        color: white;
      }
    '''
        : '''
      body {
        background-color: white;
        color: black;
      }
    ''';

    String jsCode = '''
    <script>
       const styleElement = document.createElement('style');
       styleElement.innerHTML = `$darkModeCss`;
       document.head.appendChild(styleElement);
    </script>
    ''';

    String content = await rootBundle.loadString(widget.htmlFilePath);
    await controller.loadRequest(Uri.dataFromString(
        '<html><head>$jsCode</head><body>${content}</body></html>',
        mimeType: 'text/html',
        encoding: utf8));
  }

  Future<void> loadHtmlFile(String assetPath) async {
    try {
      reloadWebView(_webViewController);
    } catch (error) {
      print('Error loading HTML: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.cardName,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        centerTitle: true,
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}

class AppInfoScreen extends StatelessWidget {
  final String appVersion = '1.1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Info'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/icon.png', height: 100, width: 100),
            const SizedBox(height: 20),
            Text(
              'Online Corner',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Version $appVersion',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Made with ❤️ by Kreativ Devs',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppTheme {
  static ThemeData lightTheme([ColorScheme? lightDynamic]) {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: lightDynamic?.background ?? Colors.white,
      colorScheme: lightDynamic ??
          ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
      textTheme: GoogleFonts.bricolageGrotesqueTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            fontSize: 16.0,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
      ),
    );
  }

  static ThemeData darkTheme([ColorScheme? darkDynamic]) {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: darkDynamic?.background ?? const Color(0xFF2D2F33),
      colorScheme: darkDynamic ??
          ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
      textTheme: GoogleFonts.bricolageGrotesqueTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16.0,
            color: Colors.white,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
      ),
    );
  }
}