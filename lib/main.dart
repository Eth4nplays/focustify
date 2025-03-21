import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:webview_windows/webview_windows.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focustify',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const MyHomePage(title: 'Focustify'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();

  void _startFocusMode() {
    String name = _nameController.text;
    int hours = int.tryParse(_hoursController.text) ?? 0;
    int minutes = int.tryParse(_minutesController.text) ?? 0;
    int seconds = int.tryParse(_secondsController.text) ?? 0;

    int totalSeconds = (hours * 3600) + (minutes * 60) + seconds;

    if (totalSeconds > 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => FocusScreen(
                title: 'Focus Mode',
                duration: totalSeconds,
                name: name,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Configure Session', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Session name',
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            const Text('Session Duration', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Hours',
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _secondsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Seconds',
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _startFocusMode,
              child: const Text('Start Focus Mode'),
            ),
          ],
        ),
      ),
    );
  }
}

class FocusScreen extends StatefulWidget {
  final int duration;
  final String name;

  const FocusScreen({
    super.key,
    required this.title,
    required this.duration,
    required this.name,
  });

  final String title;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  int _remainingTime = 0;
  Timer? _timer;
  double _timerProgress = 0.0;
  String name = 'Focus Mode';

  List<String> _todos = [];
  TextEditingController _todoController = TextEditingController();

  Timer? _holdTimer;
  double _holdProgress = 0.0;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();

    if (widget.name.isEmpty) {
      name = 'Focus Session';
    } else {
      name = widget.name;
    }

    _remainingTime = widget.duration;
    _startCountdown();

    Future.delayed(Duration.zero, () async {
      await windowManager.setFullScreen(true);
    });
  }

  void _startHolding() {
    _isHolding = true;
    _holdProgress = 0.0;

    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _holdProgress += 0.01;
      });

      if (_holdProgress >= 1.0) {
        _exitFocusMode();
        timer.cancel();
      }
    });
  }

  void _stopHolding() {
    _isHolding = false;
    _holdTimer?.cancel();
    setState(() {
      _holdProgress = 0.0;
    });
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
          _timerProgress = 1.0 - (_remainingTime / widget.duration);
        });
      } else {
        _exitFocusMode();
      }
    });
  }

  void _exitFocusMode() async {
    _timer?.cancel();
    await windowManager.setFullScreen(false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyHomePage(title: 'Focustify'),
        ),
      );
    }
  }

  void _openSpotify() {
    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start spotify']);
    } else if (Platform.isMacOS) {
      Process.run('open', ['-a', 'Spotify']);
    } else if (Platform.isLinux) {
      Process.run('spotify', []);
    }
  }

  void _openBrowser(String url) {
    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start $url']);
    } else if (Platform.isMacOS) {
      Process.run('open', [url]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [url]);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _todoController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(value: _timerProgress, minHeight: 5),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen =
              constraints.maxWidth > 800; // Adjust for responsiveness

          return Padding(
            padding: const EdgeInsets.all(20),
            child:
                isWideScreen
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _buildFocusContent(),
                          ),
                        ),
                        const SizedBox(width: 20),
                        const VerticalDivider(),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [_buildTodoList()],
                          ),
                        ),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ..._buildFocusContent(),
                        const SizedBox(height: 20),
                        _buildTodoList(),
                      ],
                    ),
          );
        },
      ),
    );
  }

  // Helper method to build Focus Mode section
  List<Widget> _buildFocusContent() {
    return [
      Text(name, style: TextStyle(fontSize: 24)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _formatTime(_remainingTime),
          style: const TextStyle(fontSize: 20),
        ),
      ),
      const SizedBox(height: 10),
      const Divider(),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(onPressed: _openSpotify, child: const Text('Spotify')),
            const SizedBox(width: 10),
            FilledButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Browser()),
                  ),
              child: const Text('Browser'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      const Divider(),
      const SizedBox(height: 10),
      GestureDetector(
        onLongPressStart: (_) => _startHolding(),
        onLongPressEnd: (_) => _stopHolding(),
        child: FilledButton(
          onPressed: () {},
          child: const Text('Exit Focus Mode (Hold)'),
        ),
      ),
      if (_isHolding)
        Column(
          children: [
            const SizedBox(height: 10),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _holdProgress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
    ];
  }

  // Helper method to build To-Do List section
  Widget _buildTodoList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('To-Do List', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 10),
        TextField(
          controller: _todoController,
          decoration: InputDecoration(
            hintText: 'Add a task...',
            border: OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  if (_todoController.text.isNotEmpty) {
                    _todos.add(_todoController.text);
                    _todoController.clear();
                  }
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 5),
        for (int i = 0; i < _todos.length; i++)
          ListTile(
            title: Text(_todos[i]),
            trailing: IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                setState(() {
                  _todos.removeAt(i);
                });
              },
            ),
          ),
      ],
    );
  }
}

class Browser extends StatefulWidget {
  @override
  _BrowserState createState() => _BrowserState();
}

class _BrowserState extends State<Browser> {
  final WebviewController _controller = WebviewController();
  final List<String> _history = [];
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      await _controller.initialize();
      await _controller.loadUrl('https://google.com/');

      _controller.url.listen((url) {
        if (_history.isEmpty || _history.last != url) {
          _history.add(url);
          _currentIndex = _history.length - 1;
        }
        setState(() {});
      });

      setState(() {});
    } catch (e) {
      debugPrint("Error initializing WebView: $e");
    }
  }

  void _reloadWebView() {
    if (_controller.value.isInitialized) {
      _controller.reload();
    }
  }

  void _goBack() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _controller.loadUrl(_history[_currentIndex]);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Browser'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _currentIndex > 0 ? _goBack : null,
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: _reloadWebView),
        ],
      ),
      body:
          _controller.value.isInitialized
              ? Webview(_controller)
              : Center(child: CircularProgressIndicator()),
    );
  }
}
