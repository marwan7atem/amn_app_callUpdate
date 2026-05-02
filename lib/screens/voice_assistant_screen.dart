import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

import '../services/usage_logger.dart';
import 'car_control_screen.dart';
import 'car_status_screen.dart';
import 'driver_status_screen.dart';
import 'emergency_contacts_screen.dart';
import 'emergency_history_screen.dart';
import 'emergency_numbers_screen.dart';
import 'emergency_services_screen.dart';
import 'first_aid_screen.dart';
import 'hospital_insurance_screen.dart';
import 'parking_map_screen.dart';
import 'pairing_unpaired_screen.dart';
import 'sos_emergency_screen.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  late final stt.SpeechToText _speech;
  late final FlutterTts _tts;

  bool _available = false;
  bool _initializing = true;
  bool _listening = false;
  bool _thinking = false;
  bool _handlingFinalResult = false;
  String _recognizedText = '';
  String _assistantReply = 'Tap the microphone and tell AMN what you need.';
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
            ? 'I am ready. Try saying "open parking map" or "call emergency".'
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
    } catch (_) {
      // The visible reply is still useful if the device cannot speak.
    }
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _containsAny(String text, List<String> phrases) {
    return phrases.any(text.contains);
  }

  bool _isEmergencyWord(String text) {
    return _containsAny(text, [
      'emergency',
      'emergenc',
      'emerg',
      'sos',
      'accident',
      'crash',
    ]);
  }

  bool _isEmergencyCallCommand(String text) {
    return _isEmergencyWord(text) &&
        _containsAny(text, ['call', 'dial', 'phone', 'start', 'help']);
  }

  bool _isActionableCommand(String recognized) {
    final text = _normalize(recognized);
    if (text.isEmpty) return false;

    return _isEmergencyCallCommand(text) ||
        _containsAny(text, [
          'help',
          'commands',
          'what can you do',
          'open emergency',
          'emergency service',
          'contact',
          'hospital',
          'doctor',
          'clinic',
          'insurance',
          'first aid',
          'cpr',
          'emergency number',
          'ambulance number',
          'police number',
          'history',
          'car status',
          'car health',
          'engine',
          'fuel',
          'battery',
          'tire',
          'tyre',
          'oil',
          'driver status',
          'driver behavior',
          'fatigue',
          'attention',
          'safety score',
          'parking',
          'parking map',
          'find parking',
          'where is my car',
          'pair',
          'pairing',
          'bluetooth',
          'connect car',
          'connect vehicle',
          'control',
          'car control',
          'drive mode',
          'charging',
          'speed limit',
          'hello',
          'hi',
          'hey',
        ]);
  }

  Future<void> _callEmergencyNumber() async {
    UsageLogger.logAction('voice_command_call_emergency');
    const emergencyNumber = '122';
    final uri = Uri(scheme: 'tel', path: emergencyNumber);
    await launchUrl(uri);
  }

  Future<void> _navigateTo({
    required String routeName,
    required String reply,
    required WidgetBuilder builder,
  }) async {
    UsageLogger.logAction('voice_command_$routeName');
    if (!mounted) return;

    Navigator.push(context, MaterialPageRoute(builder: builder));

    await _setAssistantReply(reply, speak: true);
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

  Future<void> _handleCommand(String recognized) async {
    final text = _normalize(recognized);
    if (text.isEmpty) {
      await _setAssistantReply(
        "I did not catch that. Please try again.",
        speak: true,
      );
      return;
    }

    if (_containsAny(text, ['help', 'what can you do', 'commands'])) {
      await _setAssistantReply(
        'You can ask me to open emergency services, SOS, contacts, hospitals, first aid, emergency numbers, history, car status, driver status, parking map, pairing, or car controls.',
        speak: true,
      );
      return;
    }

    if (_isEmergencyCallCommand(text)) {
      try {
        await _callEmergencyNumber();
        await _setAssistantReply(
          'Calling emergency services now.',
          speak: true,
        );
      } catch (_) {
        await _navigateTo(
          routeName: 'sos',
          reply:
              'I could not open the phone dialer, so I opened the SOS screen instead.',
          builder: (_) => const SosEmergencyScreen(),
        );
      }
      return;
    }

    if (_containsAny(text, ['sos', 'open sos', 'start sos'])) {
      await _navigateTo(
        routeName: 'sos',
        reply: 'Opening SOS.',
        builder: (_) => const SosEmergencyScreen(),
      );
      return;
    }

    if (_containsAny(text, [
      'emergency service',
      'emergency services',
      'open emergency',
      'accident',
      'crash',
    ])) {
      await _navigateTo(
        routeName: 'emergency_services',
        reply: 'Opening emergency services.',
        builder: (_) => const EmergencyServicesScreen(),
      );
      return;
    }

    if (_containsAny(text, [
      'contact',
      'contacts',
      'emergency contact',
      'notify family',
      'call family',
    ])) {
      await _navigateTo(
        routeName: 'emergency_contacts',
        reply: 'Opening your emergency contacts.',
        builder: (_) => const EmergencyContactsScreen(),
      );
      return;
    }

    if (_containsAny(text, [
      'hospital',
      'doctor',
      'clinic',
      'insurance',
      'medical help',
    ])) {
      await _navigateTo(
        routeName: 'hospital_insurance',
        reply: 'Opening hospitals and insurance.',
        builder: (_) => const HospitalInsuranceScreen(),
      );
      return;
    }

    if (_containsAny(text, [
      'first aid',
      'cpr',
      'bleeding',
      'choking',
      'medical tips',
    ])) {
      await _navigateTo(
        routeName: 'first_aid',
        reply: 'Opening first aid tips.',
        builder: (_) => const FirstAidScreen(),
      );
      return;
    }

    if (_containsAny(text, [
      'emergency number',
      'emergency numbers',
      'ambulance number',
      'police number',
      'fire number',
    ])) {
      await _navigateTo(
        routeName: 'emergency_numbers',
        reply: 'Opening emergency numbers for Egypt.',
        builder: (_) => const EmergencyNumbersScreen(),
      );
      return;
    }

    if (_containsAny(text, [
      'history',
      'emergency history',
      'previous emergency',
      'old sos',
    ])) {
      await _navigateTo(
        routeName: 'emergency_history',
        reply: 'Opening emergency history.',
        builder: (_) => const EmergencyHistoryScreen(),
      );
      return;
    }

    if (_containsAny(text, [
      'car status',
      'car health',
      'engine',
      'fuel',
      'battery',
      'tire',
      'tyre',
      'oil',
    ])) {
      await _navigateTo(
        routeName: 'car_status',
        reply: 'Opening car status.',
        builder: (_) => const CarStatusScreen(),
      );
      return;
    }

    if (_containsAny(text, [
      'driver status',
      'driver behavior',
      'fatigue',
      'attention',
      'safety score',
    ])) {
      await _navigateTo(
        routeName: 'driver_status',
        reply: 'Opening driver status.',
        builder: (_) => const DriverStatusScreen(),
      );
      return;
    }

    if (_containsAny(text, [
      'parking',
      'park',
      'parking map',
      'find parking',
      'where is my car',
    ])) {
      await _navigateTo(
        routeName: 'parking_map',
        reply: 'Opening parking map.',
        builder: (_) => const ParkingMapScreen(),
      );
      return;
    }

    if (_containsAny(text, [
      'pair',
      'pairing',
      'bluetooth',
      'connect car',
      'connect vehicle',
    ])) {
      await _navigateTo(
        routeName: 'pairing',
        reply: 'Opening vehicle pairing.',
        builder: (_) => const PairingUnpairedScreen(),
      );
      return;
    }

    if (_containsAny(text, [
      'control',
      'controls',
      'car control',
      'drive mode',
      'charging',
      'speed limit',
    ])) {
      await _navigateTo(
        routeName: 'car_controls',
        reply: 'Opening car controls.',
        builder: (_) => const CarControlScreen(),
      );
      return;
    }

    if (_containsAny(text, ['hello', 'hi', 'hey'])) {
      await _setAssistantReply(
        'Hello. I am listening. Ask me for emergency help, car status, parking, hospitals, or first aid.',
        speak: true,
      );
      return;
    }

    await _setAssistantReply(
      'I heard "$recognized", but I do not know that command yet. Say "help" to hear what I can do.',
      speak: true,
    );
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
      _assistantReply = 'Understanding your request...';
    });

    await _handleCommand(_recognizedText);
    _handlingFinalResult = false;
  }

  void _scheduleCommandHandling() {
    _commandDebounce?.cancel();
    if (!_isActionableCommand(_recognizedText)) return;

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
        ? 'Tap and say a command'
        : 'Microphone unavailable';

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(
                statusText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 34),
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
                children: const [
                  _CommandChip(label: 'Call emergency'),
                  _CommandChip(label: 'Open parking map'),
                  _CommandChip(label: 'Show car status'),
                  _CommandChip(label: 'First aid tips'),
                  _CommandChip(label: 'Help'),
                ],
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
                text: _thinking
                    ? 'Understanding your request...'
                    : _assistantReply,
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
