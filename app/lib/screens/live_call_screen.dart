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
    with SingleTickerProviderStateMixin {
  late final VadHandler _vadHandler;
  late AnimationController _glowController;
  final AudioPlayer _audioPlayer = AudioPlayer();

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
        if (!_isMuted) {
          await _vadHandler.startListening(
            baseAssetPath: 'assets/models/',
            positiveSpeechThreshold: 0.5,
            negativeSpeechThreshold: 0.35,
            minSpeechFrames: 2,
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
        _isAiSpeaking = true; // Speech ended -> AI turn (Yellow)
        _transcription = "Transcribing...";
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
      // Calculate RMS and scale smoothly to [0..1] range visually
      double rms = sqrt(sumSquares / frameData.frame.length);
      double level = (rms * 5).clamp(0.0, 1.0);

      setState(() {
        if (!_isMuted) {
          _micLevel = level;
        } else {
          _micLevel = 0.0;
        }

        // Envelope follower for organic fluid movement
        final target = (_isMuted && !_isAiSpeaking) ? 0.0 : _micLevel;
        
        if (target > _smoothedLevel) {
          // Fast attack: jump up quickly when sound starts
          _smoothedLevel += (target - _smoothedLevel) * 0.6;
        } else {
          // Slow release: fade down gently like a glowing ember
          _smoothedLevel += (target - _smoothedLevel) * 0.05;
        }
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
        await _audioPlayer.play(BytesSource(bytes));

        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isAiSpeaking = false;
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
          });
        }
      }
    } catch (e) {
      debugPrint('LiveCallScreen: Error calling TTS API: $e');
      if (mounted) {
        setState(() {
          _isAiSpeaking = false;
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
        positiveSpeechThreshold: 0.5,
        negativeSpeechThreshold: 0.35,
        minSpeechFrames: 2,
      );
    }
  }

  @override
  void dispose() {
    _vadHandler.stopListening(); // Force mic release
    _vadHandler.dispose();
    _glowController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color topBarAuraColor = _isAiSpeaking
        ? const Color(0xFFFCE566) // Gold for AI
        : _isMuted
            ? const Color(0xFF424242) // Dim grey for muted
            : const Color(0xFF4A90E2); // Blue for User

    return Scaffold(
      backgroundColor: const Color(0xFF09090B), // Ultra dark background
      body: Stack(
        children: [
          // 1. Glowing Aura (The Entity)
          Positioned.fill(
            child: Center(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  // Determine aura color based on state
                  final Color auraColor = _isAiSpeaking
                      ? const Color(0xFFFCE566) // Gold for AI
                      : _isMuted
                          ? const Color(0xFF424242) // Dim grey for muted (when AI not speaking)
                          : const Color(0xFF4A90E2); // Blue for User

                  // Calculate dynamic size based on amplitude and pulse
                  final double baseIntensity = _isAiSpeaking
                      ? 0.4 + (_glowController.value * 0.4)
                      : _isMuted
                          ? 0.1 // Flat intensity when muted
                          : (_smoothedLevel > 0.1)
                              ? _smoothedLevel + (_glowController.value * _smoothedLevel * 0.5)
                              : 0.2 + (_glowController.value * 0.1);

                  final double intensity = baseIntensity.clamp(0.0, 1.0);
                  final double orbSize = 200 + (intensity * 150);

                  return Container(
                    width: orbSize,
                    height: orbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          auraColor.withValues(alpha: 0.8),
                          auraColor.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.2, 0.6, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: auraColor.withValues(alpha: 0.5),
                          blurRadius: 100,
                          spreadRadius: intensity * 50,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Frosted Glass Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3), // Darken the glass
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
                        _isAiSpeaking ? "LegalEase Speaking" : (_isMuted ? "Muted" : "Listening..."),
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

                // Transcription Area (Center)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 800),
                        child: Text(
                          (_isMuted && !_isAiSpeaking)
                              ? ""
                              : _transcription.isEmpty ? "Say something..." : _transcription,
                          key: ValueKey((_isMuted && !_isAiSpeaking) ? "muted" : _transcription),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: (_transcription.isEmpty || (_isMuted && !_isAiSpeaking)) ? 0.3 : 0.9),
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            height: 1.4,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

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
