import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vad/vad.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import '../services/chat_service.dart';

class LiveCallScreen extends StatefulWidget {
  const LiveCallScreen({super.key});

  @override
  State<LiveCallScreen> createState() => _LiveCallScreenState();
}

class _LiveCallScreenState extends State<LiveCallScreen>
    with TickerProviderStateMixin {
  late final VadHandler _vadHandler;
  late AnimationController _glowController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  double _micLevel = 0.0;
  double _smoothedLevel = 0.0;
  bool _isMuted = false;
  bool _isAiSpeaking = false;
  bool _isThinking = false;
  String _transcription = "";
  double _aiAmplitude = 0.0;

  // Color animation: blue (user) <-> gold (AI)
  late AnimationController _colorController;
  static const Color _userColor = Color(0xFF4A90E2);
  static const Color _aiColor = Color(0xFFFCE566);
  static const Color _mutedColor = Color(0xFF424242);
  late Animation<Color?> _waveColor;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60), // Fast repaint tick
    )..repeat();

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _waveColor = ColorTween(begin: _userColor, end: _aiColor)
        .animate(CurvedAnimation(parent: _colorController, curve: Curves.easeInOut));

    _vadHandler = VadHandler.create(isDebug: true);
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
        _setupVadHandler();
        if (!_isMuted) {
          await _vadHandler.startListening(
            baseAssetPath: 'assets/models/',
            positiveSpeechThreshold: 0.3,
            negativeSpeechThreshold: 0.35,
            minSpeechFrames: 2,
            redemptionFrames: 30, // Allows ~1 second of pause without cutting off
          );
          debugPrint('LiveCallScreen: VAD started listening');
        }
      } else {
        debugPrint('LiveCallScreen: Permission not granted');
      }
    } catch (e, stack) {
      debugPrint('LiveCallScreen: CRITICAL ERROR during mic init: $e');
      debugPrint('LiveCallScreen: Stack trace: $stack');
    }
  }

  void _setupVadHandler() {
    debugPrint('LiveCallScreen: Setting up VAD handler listeners...');

    _vadHandler.onSpeechStart.listen((_) {
      if (!mounted || _isMuted) return;
      debugPrint('LiveCallScreen: Speech started (User)');
      setState(() {
        _isAiSpeaking = false; // User speaking -> Blue
      });
    });

    _vadHandler.onSpeechEnd.listen((samples) async {
      if (!mounted || _isMuted) return;
      debugPrint('LiveCallScreen: Speech ended (User stopped)');
      setState(() {
        _isThinking = true; // Waiting for server response
        _isAiSpeaking = false;
        _transcription = "";
      });

      // Send to local API for transcription
      try {
        final float32List = Float32List.fromList(samples);
        final bytes = float32List.buffer.asUint8List();

        final apiUrl = '${ChatService.apiBaseUrl}/api/transcribe_raw';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/octet-stream'},
          body: bytes,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _transcription = data['text'] ?? '';
            });
            debugPrint('LiveCallScreen: Transcribed: $_transcription');
            _playTTS('LegalEase received: $_transcription');
          }
        } else {
          debugPrint(
            'LiveCallScreen: STT error: ${response.statusCode} - ${response.body}',
          );
          if (mounted) {
            setState(() {
              _transcription = "Error transcribing audio";
            });
          }
        }
      } catch (e) {
        debugPrint('LiveCallScreen: Error calling STT API: $e');
        if (mounted) {
          setState(() {
            _transcription = "API Connection Error";
          });
        }
      }
    });

    _vadHandler.onVADMisfire.listen((_) {
      if (!mounted || _isMuted) return;
      debugPrint('LiveCallScreen: VAD misfire');
      setState(() {
        _isThinking = false;
        _isAiSpeaking = false;
      });
    });

    _vadHandler.onFrameProcessed.listen((frameData) {
      if (!mounted) return;

      // Extract raw audio samples from the frame for amplitude
      double sumSquares = 0.0;
      for (final sample in frameData.frame) {
        sumSquares += sample * sample;
      }
      // Calculate RMS and scale smoothly to [0..1] range visually
      double rms = sqrt(sumSquares / frameData.frame.length);
      // Extreme sensitivity boost
      double level = (rms * 60.0).clamp(0.0, 1.0);

      setState(() {
        if (!_isMuted) {
          _micLevel = level;
        } else {
          _micLevel = 0.0;
        }

        final target = (_isMuted && !_isAiSpeaking) ? 0.0 : _micLevel;
        
        // Even faster tracking (0.8) for instant response
        _smoothedLevel += (target - _smoothedLevel) * 0.8;
      });
    });
  }

  Future<void> _playTTS(String text) async {
    if (text.isEmpty) return;
    try {
      final apiUrl = '${ChatService.apiBaseUrl}/api/tts';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        
        // AI audio is ready - switch from thinking to speaking
        if (mounted) {
          setState(() {
            _isThinking = false;
            _isAiSpeaking = true;
          });
        }
        
        // Simulate AI amplitude from playback using a timer
        Timer? aiPulseTimer;
        aiPulseTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
          if (!mounted) { aiPulseTimer?.cancel(); return; }
          setState(() {
            // Create organic-feeling amplitude using multiple sine waves
            final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
            _aiAmplitude = (0.4 + 
              0.25 * sin(t * 5.3) + 
              0.15 * sin(t * 8.7) + 
              0.1 * sin(t * 13.1)).clamp(0.0, 1.0);
          });
        });
        
        await _audioPlayer.play(BytesSource(bytes));

        _audioPlayer.onPlayerComplete.listen((_) {
          aiPulseTimer?.cancel();
          if (mounted) {
            setState(() {
              _isAiSpeaking = false;
              _aiAmplitude = 0.0;
            });
          }
        });
      } else {
        debugPrint(
          'LiveCallScreen: TTS error: ${response.statusCode} - ${response.body}',
        );
        if (mounted) {
          setState(() {
            _isAiSpeaking = false;
            _isThinking = false;
          });
        }
      }
    } catch (e) {
      debugPrint('LiveCallScreen: Error calling TTS API: $e');
      if (mounted) {
        setState(() {
          _isAiSpeaking = false;
          _isThinking = false;
        });
      }
    }
  }

  Future<void> _toggleMute() async {
    final bool willMute = !_isMuted;
    setState(() {
      _isMuted = willMute;
    });

    if (willMute) {
      await _vadHandler.stopListening();
      if (mounted) {
        setState(() {
          _micLevel = 0.0;
          _smoothedLevel = 0.0;
        });
      }
    } else {
      await _vadHandler.startListening(
        baseAssetPath: 'assets/models/',
        positiveSpeechThreshold: 0.3,
        negativeSpeechThreshold: 0.35,
        minSpeechFrames: 2,
        redemptionFrames: 30, // Allows ~1 second of pause without cutting off
      );
    }
  }

  @override
  void dispose() {
    _vadHandler.stopListening();
    _vadHandler.dispose();
    _glowController.dispose();
    _colorController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Drive color animation based on state
    if (_isAiSpeaking && _colorController.status != AnimationStatus.completed) {
      _colorController.forward();
    } else if (!_isAiSpeaking && _colorController.status != AnimationStatus.dismissed) {
      _colorController.reverse();
    }

    String statusText;
    Color topBarAuraColor;
    if (_isAiSpeaking) {
      statusText = "LegalEase Speaking";
      topBarAuraColor = _aiColor;
    } else if (_isThinking) {
      statusText = "Thinking...";
      topBarAuraColor = _userColor.withValues(alpha: 0.6);
    } else if (_isMuted) {
      statusText = "Muted";
      topBarAuraColor = _mutedColor;
    } else {
      statusText = "Listening...";
      topBarAuraColor = _userColor;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          // 1. Frosted Glass Overlay (Background texture)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),

          // 2. Oscilloscope Waveform (Foreground)
          Positioned.fill(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_glowController, _colorController]),
                builder: (context, child) {
                  // Flat when muted and not AI turn
                  final bool isFlat = _isMuted && !_isAiSpeaking && !_isThinking;

                  final double amplitude;
                  if (isFlat || _isThinking) {
                    amplitude = 0.0;
                  } else if (_isAiSpeaking) {
                    amplitude = _aiAmplitude;
                  } else {
                    amplitude = _smoothedLevel;
                  }

                  // Use animated color: blue for user, gold for AI
                  final Color waveColor = isFlat
                      ? _mutedColor
                      : (_waveColor.value ?? _userColor);

                  // Time-based phase for wave flow
                  final double t = DateTime.now().millisecondsSinceEpoch / 1000.0;

                  return SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: WaveformPainter(
                        amplitude: amplitude,
                        time: t,
                        color: waveColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. UI Layer
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: topBarAuraColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Space
                const Spacer(),

                // Bottom Action Cluster
                Padding(
                  padding: const EdgeInsets.only(bottom: 48.0, top: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mute Button (Glassmorphic)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                          child: InkWell(
                            onTap: _toggleMute,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: _isMuted 
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: _isMuted ? 1.0 : 0.2),
                                  width: 1.0,
                                ),
                              ),
                              child: Icon(
                                _isMuted ? Icons.mic_off : Icons.mic,
                                color: _isMuted ? Colors.black : Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 32),
                      
                      // End Call Button
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE53935).withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// A proper multi-harmonic waveform painter.
// Uses layered sine waves at different frequencies/phases/amplitudes
// that each contribute independently across the full width of the string,
// creating a rich, organic audio-visualizer look.
// A high-fidelity, organic waveform painter.
// Uses 12 layers of harmonics that modulate their own frequency and speed
// based on the incoming audio amplitude, creating an "electric" jitter.
class WaveformPainter extends CustomPainter {
  final double amplitude; // 0.0 (flat) to 1.0 (max)
  final double time;      // current time in seconds for wave flow
  final Color color;

  WaveformPainter({
    required this.amplitude,
    required this.time,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final double midY = size.height / 2;
    // Taller vertical range for more impact
    final double maxH = size.height * 0.8; 

    // Layered drawing for neon glow effect
    _drawLayer(canvas, size, midY, maxH, 8.0, 0.15); // Outer glow
    _drawLayer(canvas, size, midY, maxH, 3.5, 0.45); // Mid body
    _drawLayer(canvas, size, midY, maxH, 1.5, 1.00); // Sharp core
  }

  void _drawLayer(
    Canvas canvas, Size size, double midY, double maxH,
    double strokeWidth, double opacityScale,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacityScale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (strokeWidth >= 5.0) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    }

    final path = Path();
    const int steps = 160; // Enough resolution for a smooth line
    final double stepW = size.width / steps;

    for (int i = 0; i <= steps; i++) {
      final double x = i * stepW;
      final double xNorm = i / steps; // 0..1 range

      // Bell-curve envelope: tapers to 0 at edges
      final double env = exp(-pow((xNorm - 0.5) * 3.2, 2));

      // Sum 12 dynamic harmonics
      double y = 0.0;
      for (int h = 1; h <= 12; h++) {
        // As amplitude increases, the frequencies and speeds shift up
        // creating that "busy/electric" look when talking.
        final double freqBoost = 1.0 + (amplitude * h * 0.2);
        final double speedBoost = 1.0 + (amplitude * h * 0.5);
        
        final double freq = (h * 1.37) * freqBoost;
        final double speed = (h * 0.73) * speedBoost;
        final double phase = h * 2.15; // unique offset per layer
        
        // Higher harmonics have lower base amplitude but get boosted by voice
        final double baseWeight = 1.0 / (h * 0.8 + 0.2);
        final double weight = baseWeight * (0.2 + amplitude * 0.8);
        
        y += sin(xNorm * pi * freq + time * speed + phase) * weight;
      }

      // Normalization factor (approximate sum of weights)
      y /= 6.0;

      final double py = midY - y * env * amplitude * maxH;

      if (i == 0) {
        path.moveTo(x, py);
      } else {
        path.lineTo(x, py);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter old) =>
      old.amplitude != amplitude ||
      old.time != time ||
      old.color != color;
}
