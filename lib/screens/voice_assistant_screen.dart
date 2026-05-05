import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/usage_logger.dart';
import '../services/voice_command_sync_service.dart';
import 'car_status_screen.dart';
import 'edit_profile_screen.dart';
import 'emergency_contacts_screen.dart';
import 'hospital_insurance_screen.dart';
import 'pairing_unpaired_screen.dart';
import 'parking_map_screen.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  late final stt.SpeechToText _speech;
  late final FlutterTts _tts;
  final _sync = VoiceCommandSyncService.instance;

  bool _available = false;
  bool _initializing = true;
  bool _listening = false;
  bool _thinking = false;
  bool _handlingFinalResult = false;
  bool _bridgeConnected = false;
  String _recognizedText = '';
  String _assistantReply = 'Tap the microphone and tell AMN what you need.';
  String _bridgeStatus = 'Checking car voice bridge...';
  String _baseUrl = '';
  List<Map<String, dynamic>> _catalog = const [];
  Timer? _commandDebounce;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initAssistant();
    UsageLogger.logScreenView('VoiceAssistantScreen');
  }

  Future<void> _initAssistant() async {
    await _initTts();
    await _initSpeech();
    _catalog = await _sync.loadCatalog();
    _baseUrl = await _sync.getBaseUrl();
    await _refreshBridgeStatus();
    if (!mounted) return;
    setState(() {
      _initializing = false;
    });
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _maybeHandleFinalUtterance();
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _listening = false;
            _thinking = false;
            _assistantReply =
                'I could not access the microphone. Please allow microphone and speech recognition permissions, then try again.';
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _available = available;
        _assistantReply = available
            ? 'I am ready. Say a command and I will route it correctly.'
            : 'Microphone or speech recognition is not available on this device.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _available = false;
        _assistantReply =
            'Voice assistant could not start. Please check app permissions and try again.';
      });
    }
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\\s]"), ' ')
        .replaceAll(RegExp(r'\\s+'), ' ')
        .trim();
  }

  String _patternFromPhrase(String phrase) {
    final placeholder = RegExp(r'\\[(\\w+)\\]');
    final normalized = _normalize(phrase.replaceAll(placeholder, '__slot__'));
    return RegExp.escape(normalized)
        .replaceAll('__slot__', '(.+)')
        .replaceAll(r'\\ ', r'\\s+');
  }

  Map<String, dynamic>? _findCatalogMatch(String recognized) {
    final normalized = _normalize(recognized);
    for (final item in _catalog) {
      final phrases = (item['phrases'] as List?) ?? const [];
      for (final phrase in phrases) {
        final rawPhrase = phrase.toString();
        final pattern = _patternFromPhrase(rawPhrase);
        if (RegExp(pattern).hasMatch(normalized)) {
          return item;
        }
      }
    }
    return null;
  }

  bool _isLikelyActionableCommand(String recognized) {
    return _findCatalogMatch(recognized) != null;
  }

  Future<void> _setAssistantReply(String reply, {bool speak = false}) async {
    if (!mounted) return;
    setState(() {
      _assistantReply = reply;
      _thinking = false;
    });
    if (speak) {
      await _speak(reply);
    }
  }

  Future<void> _refreshBridgeStatus() async {
    final payload = await _sync.getBridgeStatus();
    if (!mounted) return;
    setState(() {
      _bridgeConnected =
          payload['bridge_connected'] == true && payload['ok'] == true;
      if (_bridgeConnected) {
        final lastIntent =
            ((payload['last_result'] as Map?)?['intent'] ?? 'idle').toString();
        _bridgeStatus = 'Connected to car software | Last intent: $lastIntent';
      } else {
        _bridgeStatus =
            payload['error']?.toString() ?? 'Car voice bridge is offline.';
      }
    });
  }

  Future<bool> _handleLocalAppAction(Map<String, dynamic> item) async {
    final action = (item['app_action'] ?? '').toString();
    final reply = (item['confirmation'] ?? 'Done.').toString();

    Widget? screen;
    switch (action) {
      case 'open_profile':
        screen = const EditProfileScreen();
        break;
      case 'open_emergency_contacts':
        screen = const EmergencyContactsScreen();
        break;
      case 'open_hospital_insurance':
        screen = const HospitalInsuranceScreen();
        break;
      case 'open_pairing':
        screen = const PairingUnpairedScreen();
        break;
      case 'open_car_status':
        screen = const CarStatusScreen();
        break;
      case 'open_parking_map':
        screen = const ParkingMapScreen();
        break;
      default:
        return false;
    }

    if (!mounted) return false;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    await _setAssistantReply(reply, speak: true);
    return true;
  }

  Future<void> _handleCommand(String recognized) async {
    final text = recognized.trim();
    if (text.isEmpty) {
      await _setAssistantReply(
        'I did not catch that. Please try again.',
        speak: true,
      );
      return;
    }

    final match = _findCatalogMatch(text);
    if (match == null) {
      await _setAssistantReply(
        'That command is not in the AMN command list yet.',
        speak: true,
      );
      return;
    }

    final targets = ((match['targets'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();

    if (targets.contains('software')) {
      await _refreshBridgeStatus();
      if (!_bridgeConnected) {
        await _setAssistantReply(
          'The car software is not reachable right now. Check the Pi voice bridge connection first.',
          speak: true,
        );
        return;
      }

      final result = await _sync.sendCommand(text, source: 'app');
      final reply = (result['reply'] ?? 'Command received.').toString();
      await UsageLogger.logAction(
        'voice_command_sent_to_car',
        data: <String, dynamic>{
          'command': text,
          'intent': result['intent']?.toString() ?? '',
          'ok': result['ok'] == true,
        },
      );
      await _setAssistantReply(reply, speak: true);
      await _refreshBridgeStatus();
      return;
    }

    final handled = await _handleLocalAppAction(match);
    if (!handled) {
      await _setAssistantReply(
        'This command is recognized, but its app action is not connected yet.',
        speak: true,
      );
    }
  }

  Future<void> _maybeHandleFinalUtterance() async {
    if (_handlingFinalResult) return;
    if (_recognizedText.trim().isEmpty) return;

    _handlingFinalResult = true;
    _commandDebounce?.cancel();
    try {
      await _speech.stop();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _listening = false;
      _thinking = true;
      _assistantReply = 'Processing your command...';
    });

    await _handleCommand(_recognizedText);
    _handlingFinalResult = false;
  }

  void _scheduleCommandHandling() {
    _commandDebounce?.cancel();
    if (!_isLikelyActionableCommand(_recognizedText)) return;

    _commandDebounce = Timer(const Duration(milliseconds: 900), () {
      if (!mounted || _handlingFinalResult) return;
      _maybeHandleFinalUtterance();
    });
  }

  Future<void> _toggleListening() async {
    if (_initializing) return;

    if (!_available) {
      await _initSpeech();
      if (!_available) {
        await _setAssistantReply(
          'I still cannot access speech recognition. Please enable microphone permission in device settings.',
          speak: true,
        );
        return;
      }
    }

    if (_listening) {
      await _speech.stop();
      UsageLogger.logAction('voice_assistant_stop');
      await _maybeHandleFinalUtterance();
      return;
    }

    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _recognizedText = '';
      _assistantReply = 'Listening...';
      _thinking = false;
      _handlingFinalResult = false;
    });

    final started = await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _recognizedText = result.recognizedWords;
        });
        _scheduleCommandHandling();
        if (result.finalResult) {
          _maybeHandleFinalUtterance();
        }
      },
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
      ),
    );

    if (!mounted) return;
    if (started) {
      setState(() {
        _listening = true;
      });
      UsageLogger.logAction('voice_assistant_start');
    } else {
      await _setAssistantReply(
        'I could not start listening. Please try again.',
        speak: true,
      );
    }
  }

  Future<void> _showBridgeConfigDialog() async {
    final controller = TextEditingController(text: _baseUrl);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          title: const Text(
            'Pi Voice Bridge URL',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'http://192.168.1.126:8876',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      await _sync.setBaseUrl(controller.text);
      _baseUrl = await _sync.getBaseUrl();
      await _refreshBridgeStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pi voice bridge URL updated.')),
      );
    }
  }

  @override
  void dispose() {
    _commandDebounce?.cancel();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _initializing
        ? 'Preparing voice assistant...'
        : _listening
            ? 'Listening...'
            : _available
                ? 'Tap and speak a command'
                : 'Microphone unavailable';

    final commandChips = _catalog.take(5).map((item) {
      final phrases = (item['phrases'] as List?) ?? const [];
      final label =
          phrases.isNotEmpty ? phrases.first.toString() : item['intent'].toString();
      return _CommandChip(label: label);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Voice Assistant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _showBridgeConfigDialog,
            icon: const Icon(Icons.settings_ethernet, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _bridgeConnected
                        ? Colors.green.withValues(alpha: 0.4)
                        : Colors.red.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _bridgeConnected
                          ? 'Car bridge connected'
                          : 'Car bridge offline',
                      style: TextStyle(
                        color: _bridgeConnected
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _bridgeStatus,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _baseUrl,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                statusText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: _listening ? 124 : 112,
                  height: _listening ? 124 : 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _listening
                          ? const [Colors.redAccent, Colors.orangeAccent]
                          : const [Color(0xFF2E7DFF), Color(0xFF8E24AA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_listening ? Colors.redAccent : Colors.blue)
                            .withValues(alpha: 0.45),
                        blurRadius: _listening ? 38 : 26,
                        spreadRadius: _listening ? 8 : 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    _listening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: commandChips,
              ),
              const SizedBox(height: 26),
              Expanded(
                child: _AssistantPanel(
                  title: 'You said',
                  text: _recognizedText.isEmpty
                      ? 'Your voice command will appear here.'
                      : _recognizedText,
                ),
              ),
              const SizedBox(height: 14),
              _AssistantPanel(
                title: 'AMN reply',
                text: _thinking ? 'Processing your command...' : _assistantReply,
                fixedHeight: 138,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandChip extends StatelessWidget {
  final String label;

  const _CommandChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}

class _AssistantPanel extends StatelessWidget {
  final String title;
  final String text;
  final double? fixedHeight;

  const _AssistantPanel({
    required this.title,
    required this.text,
    this.fixedHeight,
  });

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );

    if (fixedHeight == null) return panel;
    return SizedBox(height: fixedHeight, child: panel);
  }
}
