import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class LiveCallScreen extends StatefulWidget {
  const LiveCallScreen({super.key});

  @override
  State<LiveCallScreen> createState() => _LiveCallScreenState();
}

class _LiveCallScreenState extends State<LiveCallScreen>
    with SingleTickerProviderStateMixin {
  late AudioRecorder _audioRecorder;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  late AnimationController _glowController;

  double _micLevel = 0.0;
  double _smoothedLevel = 0.0;
  bool _isMuted = false;
  // ignore: prefer_final_fields
  bool _isAiSpeaking = false; // Mock for future AI integration

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _audioRecorder = AudioRecorder();
    _initMic();
  }

  Future<void> _initMic() async {
    debugPrint('LiveCallScreen: Starting mic initialization...');
    try {
      final status = await Permission.microphone.request();
      debugPrint('LiveCallScreen: Microphone permission status: $status');

      if (status.isPermanentlyDenied) {
        debugPrint(
          'LiveCallScreen: Mic permanently denied. Opening settings...',
        );
        openAppSettings();
        return;
      }

      if (status.isGranted) {
        final hasPermission = await _audioRecorder.hasPermission();
        debugPrint(
          'LiveCallScreen: AudioRecorder hasPermission check: $hasPermission',
        );

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );

        // Android specific: Check if encoder is supported
        final isSupported = await _audioRecorder.isEncoderSupported(
          config.encoder,
        );
        debugPrint(
          'LiveCallScreen: Encoder ${config.encoder} supported: $isSupported',
        );

        debugPrint('LiveCallScreen: Starting recorder...');
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/temp_audio.m4a';

        await _audioRecorder.start(config, path: path);
        debugPrint('LiveCallScreen: Recorder started successfully');

        _startAmplitudeTimer();
      } else {
        debugPrint('LiveCallScreen: Permission not granted');
      }
    } catch (e, stack) {
      debugPrint('LiveCallScreen: CRITICAL ERROR during mic init: $e');
      debugPrint('LiveCallScreen: Stack trace: $stack');
    }
  }

  void _startAmplitudeTimer() {
    debugPrint('LiveCallScreen: Starting amplitude listener...');
    _amplitudeSubscription = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 50))
        .listen(
          (amp) {
            if (!mounted) return;

            setState(() {
              double level = (amp.current + 50) / 50;
              _micLevel = level.clamp(0.0, 1.0);

              // If user starts speaking while AI is speaking, interrupt (change to blue)
              if (_micLevel > 0.1 && _isAiSpeaking && !_isMuted) {
                _isAiSpeaking = false;
              }

              // Smoothly transition amplitude for the gas/flow effect
              final target = (_isMuted && !_isAiSpeaking) ? 0.0 : _micLevel;
              _smoothedLevel += (target - _smoothedLevel) * 0.3;
            });
          },
          onError: (err) {
            debugPrint('LiveCallScreen: Amplitude stream error: $err');
          },
          cancelOnError: false,
        );
    debugPrint('LiveCallScreen: Amplitude listener attached');
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });

    if (_isMuted && !_isAiSpeaking) {
      _micLevel = 0.0;
      _smoothedLevel = 0.0;
    }
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _audioRecorder.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131315), // Deep dark background
      body: SafeArea(
        child: Column(
          children: [
            // Top bar (Live indicator)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Live",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Visualization area (Upper large rectangle with glow inside)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF1C1C1E,
                  ), // Slightly lighter dark background
                  borderRadius: BorderRadius.circular(24.0),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Bottom-up Animated Gas Flow / Glow (contained within rectangle)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          // Color switches between yellow for AI (future) and blueish for user
                          final baseColor = _isAiSpeaking
                              ? const Color(0xFFFCE566)
                              : const Color(0xFF4A90E2);

                          // Calculate intensity (AI simulates amplitude, User uses real mic level)
                          final intensity = _isAiSpeaking
                              ? 0.4 + (_glowController.value * 0.4)
                              : (_smoothedLevel > 0.0)
                              ? _smoothedLevel +
                                    (_glowController.value *
                                        _smoothedLevel *
                                        0.8)
                              : 0.0;

                          return Container(
                            height:
                                150 +
                                (intensity.clamp(0.0, 2.0) *
                                    300), // Rises when louder
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  baseColor.withValues(
                                    alpha: (0.6 * intensity).clamp(0.0, 1.0),
                                  ),
                                  baseColor.withValues(
                                    alpha: (0.15 * intensity).clamp(0.0, 1.0),
                                  ),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Transcript area (Lower small rectangle)
            Container(
              height: 80, // roughly 2 lines of text
              margin: const EdgeInsets.symmetric(horizontal: 12.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16.0),
              ),
              alignment: Alignment.center,
              child: const Text(
                "Transcript will appear here...",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Bottom Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mute Button
                InkWell(
                  onTap: _toggleMute,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _isMuted
                          ? Colors.white
                          : const Color(0xFF2A2A2E), // Dark grey
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.black : Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // End Call Button
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935), // Red
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
