import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

import 'package:path_provider/path_provider.dart';

class LiveCallScreen extends StatefulWidget {
  const LiveCallScreen({super.key});

  @override
  State<LiveCallScreen> createState() => _LiveCallScreenState();
}

class _LiveCallScreenState extends State<LiveCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _blobController;
  late AudioRecorder _audioRecorder;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  double _micLevel = 0.0;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _audioRecorder = AudioRecorder();
    _initMic();
  }

  Future<void> _initMic() async {
    debugPrint('LiveCallScreen: Starting mic initialization...');
    try {
      final status = await Permission.microphone.request();
      debugPrint('LiveCallScreen: Microphone permission status: $status');
      
      if (status.isPermanentlyDenied) {
        debugPrint('LiveCallScreen: Mic permanently denied. Opening settings...');
        openAppSettings();
        return;
      }

      if (status.isGranted) {
        final hasPermission = await _audioRecorder.hasPermission();
        debugPrint('LiveCallScreen: AudioRecorder hasPermission check: $hasPermission');

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );
        
        // Android specific: Check if encoder is supported
        final isSupported = await _audioRecorder.isEncoderSupported(config.encoder);
        debugPrint('LiveCallScreen: Encoder ${config.encoder} supported: $isSupported');

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
        if (!mounted || _isMuted) return;

        setState(() {
          double level = (amp.current + 50) / 50;
          _micLevel = level.clamp(0.0, 1.0);
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

    if (_isMuted) {
      _micLevel = 0.0;
    }
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _audioRecorder.dispose();
    _blobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131315), // Deep dark background
      body: Stack(
        children: [
          // Voice Reactive Blob
          Center(
            child: AnimatedBuilder(
              animation: _blobController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BlobPainter(
                    phase: _blobController.value * 2 * math.pi,
                    micLevel: _micLevel,
                  ),
                  child: const SizedBox(width: 300, height: 300),
                );
              },
            ),
          ),

          // Top bar (Live indicator)
          SafeArea(
            child: Padding(
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
          ),

          // Bottom Action Buttons
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Row(
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double phase;
  final double micLevel;

  _BlobPainter({required this.phase, required this.micLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = 70.0;
    // Mic level drastically increases deformation depth
    final deformationScale = 10.0 + (micLevel * 60.0);

    final path = Path();
    final paint = Paint()
      ..color = AppTheme.highlight.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    const int points = 180;
    for (int i = 0; i <= points; i++) {
      double angle = (i / points) * 2 * math.pi;

      // Alien liquid motion: Multi-layered Sine waves
      double distortion = math.sin(angle * 3 + phase) * 0.5 +
          math.cos(angle * 5 - phase * 1.5) * 0.3 +
          math.sin(angle * 2 + phase * 0.5) * 0.2;

      double r = baseRadius + (distortion * deformationScale);

      double x = center.dx + r * math.cos(angle);
      double y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Subtle inner glow
    canvas.drawPath(path, paint);

    // Main blob body
    paint
      ..maskFilter = null
      ..color = AppTheme.highlight.withValues(alpha: 0.9);
    canvas.drawPath(path, paint);

    // Highlight center
    canvas.drawCircle(
      center,
      baseRadius * 0.4,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) => true;
}
