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

class _LiveCallScreenState extends State<LiveCallScreen> {
  late AudioRecorder _audioRecorder;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  // ignore: unused_field
  double _micLevel = 0.0;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131315), // Deep dark background
      body: Stack(
        children: [
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
