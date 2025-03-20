import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

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
        useMaterial3: true, // Enables Material 3 design
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ], // Ensures only numbers
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            const SizedBox(height: 20),
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
                  FilledButton(
                    onPressed: _openSpotify,
                    child: const Text('Spotify'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () => _openBrowser('https://www.google.com'),
                    child: const Text('Browser'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
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
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _todos.removeAt(i);
                          });
                        },
                      ),
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
                onPressed: () {}, // Disable normal tap exit
                child: const Text('Exit Focus Mode (Hold)'),
              ),
            ),

            if (_isHolding)
              Column(
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 200, // Set the desired width
                    child: LinearProgressIndicator(
                      value: _holdProgress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
