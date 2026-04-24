import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';

class TrainingTimerCard extends StatefulWidget {
  const TrainingTimerCard({super.key});

  @override
  State<TrainingTimerCard> createState() => _TrainingTimerCardState();
}

class _TrainingTimerCardState extends State<TrainingTimerCard>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _uiTimer;

  // --- Audio ---
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- Stopwatch State ---
  bool _isStopwatchRunning = false;
  DateTime? _stopwatchStartTs;
  int _stopwatchAccumulatedMs = 0;
  int _currentStopwatchElapsedMs = 0;

  // --- Timer State ---
  bool _isTimerRunning = false;
  DateTime? _timerEndTs;
  int _timerRemainingMsWhenPaused = 0;
  int _currentTimerRemainingMs = 0;
  bool _hasFiredTimerDone = false;

  // Minimal configurable interval (for ticking UI)
  final Duration _tickInterval = const Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);

    // Configure audio safely
    _audioPlayer.setReleaseMode(ReleaseMode.stop);

    // Start global UI tick that drives everything based on timestamps
    _uiTimer = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiTimer?.cancel();
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Upon resume, recalculate time right away
      _onTick();
    }
  }

  // --- Alarm State ---
  DateTime? _alarmEndTs;

  void _onTick() {
    final now = DateTime.now();
    bool shouldUpdateState = false;

    // Handle Alarm Auto-Stop
    if (_alarmEndTs != null && now.isAfter(_alarmEndTs!)) {
      _stopAlarm();
      shouldUpdateState = true;
    }

    // 1) Update Stopwatch
    if (_isStopwatchRunning && _stopwatchStartTs != null) {
      final elapsed = now.difference(_stopwatchStartTs!).inMilliseconds +
          _stopwatchAccumulatedMs;
      if (elapsed != _currentStopwatchElapsedMs) {
        _currentStopwatchElapsedMs = elapsed;
        shouldUpdateState = true;
      }
    }

    // 2) Update Timer
    if (_isTimerRunning && _timerEndTs != null) {
      final remaining = _timerEndTs!.difference(now).inMilliseconds;
      if (remaining <= 0) {
        _currentTimerRemainingMs = 0;
        _isTimerRunning = false;
        _timerRemainingMsWhenPaused = 0;
        if (!_hasFiredTimerDone) {
          _hasFiredTimerDone = true;
          _playBeepSound(); // Start looping alarm
        }
        shouldUpdateState = true;
      } else {
        if (remaining != _currentTimerRemainingMs) {
          _currentTimerRemainingMs = remaining;
          shouldUpdateState = true;
        }
      }
    }

    // Trigger rebuild only if something changed
    if (shouldUpdateState && mounted) {
      setState(() {});
    }
  }

  void _stopAlarm() {
    _alarmEndTs = null;
    _audioPlayer.stop();
  }

  Future<void> _playBeepSound() async {
    try {
      _alarmEndTs = DateTime.now().add(const Duration(seconds: 5));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer
          .play(AssetSource('sounds/timer_done_half_silence.wav'));
    } catch (e) {
      debugPrint("Error playing timer sound: $e");
    }
  }

  // Helper to init audio context on web if needed
  bool _audioInitiated = false;
  Future<void> _initializeAudioContext() async {
    if (!_audioInitiated) {
      _audioInitiated = true;
      try {
        await _audioPlayer
            .setSource(AssetSource('sounds/timer_done_half_silence.wav'));
      } catch (e) {
        debugPrint("Error initializing audio context: $e");
      }
    }
  }

  // --- Stopwatch Controls ---
  void _toggleStopwatch() {
    _initializeAudioContext();
    _stopAlarm(); // Stop alarm if ringing
    setState(() {
      if (_isStopwatchRunning) {
        // Pausing
        _isStopwatchRunning = false;
        _stopwatchAccumulatedMs +=
            DateTime.now().difference(_stopwatchStartTs!).inMilliseconds;
        _currentStopwatchElapsedMs = _stopwatchAccumulatedMs;
      } else {
        // Starting
        _isStopwatchRunning = true;
        _stopwatchStartTs = DateTime.now();
      }
    });
  }

  void _resetStopwatch() {
    _stopAlarm(); // Stop alarm if ringing
    setState(() {
      _isStopwatchRunning = false;
      _stopwatchAccumulatedMs = 0;
      _currentStopwatchElapsedMs = 0;
      _stopwatchStartTs = null;
    });
  }

  // --- Timer Controls ---
  void _addTimerTime(int milliseconds) {
    _stopAlarm(); // Stop alarm if ringing
    setState(() {
      if (_isTimerRunning) {
        // Add to the end timestamp
        _timerEndTs = _timerEndTs?.add(Duration(milliseconds: milliseconds));
        int remaining = _timerEndTs!.difference(DateTime.now()).inMilliseconds;
        if (remaining < 0) remaining = 0;
        _currentTimerRemainingMs = remaining;
      } else {
        // Add to paused remaining time
        _timerRemainingMsWhenPaused += milliseconds;
        if (_timerRemainingMsWhenPaused < 0) _timerRemainingMsWhenPaused = 0;
        _currentTimerRemainingMs = _timerRemainingMsWhenPaused;
      }
      // Reset trigger flag if we added time above 0
      if (_currentTimerRemainingMs > 0) {
        _hasFiredTimerDone = false;
      }
    });
  }

  void _toggleTimer() {
    _initializeAudioContext();
    _stopAlarm(); // Stop alarm if ringing
    setState(() {
      if (_isTimerRunning) {
        // Pausing
        _isTimerRunning = false;
        _timerRemainingMsWhenPaused =
            _timerEndTs!.difference(DateTime.now()).inMilliseconds;
        if (_timerRemainingMsWhenPaused < 0) _timerRemainingMsWhenPaused = 0;
        _currentTimerRemainingMs = _timerRemainingMsWhenPaused;
      } else {
        // Starting (only if there is time left)
        if (_currentTimerRemainingMs > 0) {
          _isTimerRunning = true;
          _hasFiredTimerDone = false;
          _timerEndTs = DateTime.now()
              .add(Duration(milliseconds: _timerRemainingMsWhenPaused));
        }
      }
    });
  }

  void _resetTimer() {
    _stopAlarm(); // Stop alarm if ringing
    setState(() {
      _isTimerRunning = false;
      _timerRemainingMsWhenPaused = 0;
      _currentTimerRemainingMs = 0;
      _timerEndTs = null;
      _hasFiredTimerDone = false;
    });
  }

  String _formatMMSS(int totalMilliseconds) {
    int totalSeconds = totalMilliseconds ~/ 1000;
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2128), // Dark UI matching standard cards
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.transparent,
            dividerColor: Colors.transparent,
            labelColor: Colors.greenAccent,
            unselectedLabelColor: Colors.grey,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: [
              Tab(text: loc.get('tabStopwatch')),
              Tab(text: loc.get('tabTimer')),
            ],
          ),
          const Divider(height: 1, color: Colors.white10),
          SizedBox(
            height:
                160, // Fixed height for consistent card size (increased from 140 to fix overflow)
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStopwatchTab(loc),
                _buildTimerTab(loc),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopwatchTab(AppLocalizations loc) {
    final timeStr = _formatMMSS(_currentStopwatchElapsedMs);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          timeStr,
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2.0,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _resetStopwatch,
              icon: const Icon(Icons.refresh),
              color: Colors.grey,
              tooltip: loc.get('btnReset'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _toggleStopwatch,
              icon: Icon(_isStopwatchRunning ? Icons.pause : Icons.play_arrow),
              label: Text(_isStopwatchRunning
                  ? loc.get('btnPause')
                  : loc.get('btnPlay')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isStopwatchRunning
                    ? Colors.redAccent
                    : Colors.greenAccent.shade400,
                foregroundColor:
                    _isStopwatchRunning ? Colors.white : Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTimerTab(AppLocalizations loc) {
    final timeStr = _formatMMSS(_currentTimerRemainingMs);
    final isDone = _currentTimerRemainingMs == 0 && _hasFiredTimerDone;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Presets
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimerPresetBtn(loc.get('timerSub10s'), -10000),
              _buildTimerPresetBtn(loc.get('timerAdd10s'), 10000),
              _buildTimerPresetBtn(loc.get('timerAdd30s'), 30000),
              _buildTimerPresetBtn(loc.get('timerAdd1m'), 60000),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          timeStr,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: isDone ? Colors.redAccent : Colors.white,
            letterSpacing: 2.0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _resetTimer,
              icon: const Icon(Icons.refresh),
              color: Colors.grey,
              tooltip: loc.get('btnReset'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _toggleTimer,
              icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
              label: Text(
                  _isTimerRunning ? loc.get('btnPause') : loc.get('btnPlay')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTimerRunning
                    ? Colors.redAccent
                    : Colors.greenAccent.shade400,
                foregroundColor:
                    _isTimerRunning ? Colors.white : Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTimerPresetBtn(String label, int msDiff) {
    return InkWell(
      onTap: () => _addTimerTime(msDiff),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
