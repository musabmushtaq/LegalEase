import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:vad/vad.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class LiveCallScreen extends StatefulWidget {
  const LiveCallScreen({super.key});

  @override
  State<LiveCallScreen> createState() => _LiveCallScreenState();
}

class _LiveCallScreenState extends State<LiveCallScreen>
    with SingleTickerProviderStateMixin {
  late final VadHandler _vadHandler;
  late AnimationController _glowController;

  double _micLevel = 0.0;
  double _smoothedLevel = 0.0;
  bool _isMuted = false;
  // ignore: prefer_final_fields
  bool _isAiSpeaking = false; // Mock for future AI integration
  String _transcription = ""; // Stores the live transcription

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

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
        await _vadHandler.startListening(
          positiveSpeechThreshold: 0.5,
          negativeSpeechThreshold: 0.35,
          minSpeechFrames: 2,
        );
        debugPrint('LiveCallScreen: VAD started listening');
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
        _isAiSpeaking = true; // Speech ended -> AI turn (Yellow)
        _transcription = "Transcribing...";
      });

      // Send to local API for transcription
      try {
        final float32List = Float32List.fromList(samples);
        final bytes = float32List.buffer.asUint8List();

        final base = Platform.isAndroid
            ? 'http://10.0.2.2:8000'
            : 'http://127.0.0.1:8000';
        final apiUrl = '$base/api/transcribe_raw';

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
          }
        } else {
          debugPrint(
            'LiveCallScreen: STT error: \${response.statusCode} - \${response.body}',
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
        _isAiSpeaking = true; // Misfire -> Back to AI/idle
      });
    });

    _vadHandler.onFrameProcessed.listen((frameData) {
      if (!mounted) return;

      // Extract raw audio samples from the frame for amplitude
      double sumSquares = 0.0;
      for (final sample in frameData.frame) {
        sumSquares += sample * sample;
      }
      // Calculate RMS and scale up to [0..1] range visually
      double rms = sqrt(sumSquares / frameData.frame.length);
      double level = (rms * 10).clamp(0.0, 1.0);

      setState(() {
        if (!_isMuted) {
          _micLevel = level;
        } else {
          _micLevel = 0.0;
        }

        // Smoothly transition amplitude for the gas/flow effect
        final target = (_isMuted && !_isAiSpeaking) ? 0.0 : _micLevel;
        _smoothedLevel += (target - _smoothedLevel) * 0.3;
      });
    });
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });

    if (_isMuted) {
      await _vadHandler.stopListening();
      setState(() {
        _micLevel = 0.0;
        _smoothedLevel = 0.0;
      });
    } else {
      await _vadHandler.startListening();
    }
  }

  @override
  void dispose() {
    _vadHandler.dispose();
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
              child: Text(
                _transcription.isEmpty
                    ? "Transcript will appear here..."
                    : _transcription,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.fade,
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
