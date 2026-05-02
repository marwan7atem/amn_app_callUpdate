import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AndroidCallBridgeService {
  AndroidCallBridgeService._();

  static final AndroidCallBridgeService instance = AndroidCallBridgeService._();
  static const MethodChannel _channel = MethodChannel('amn_app/android_calls');
  static const String _portKey = 'android_call_bridge_port';
  static const String _tokenKey = 'android_call_bridge_token';

  HttpServer? _server;
  bool _started = false;
  String _authToken = '';

  Future<void> start() async {
    if (_started || kIsWeb || !Platform.isAndroid) {
      return;
    }

    await _channel.invokeMethod('initializeBridge');
    final prefs = await SharedPreferences.getInstance();
    final port = prefs.getInt(_portKey) ?? 8765;
    _authToken = prefs.getString(_tokenKey) ?? '';

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
    _started = true;
    unawaited(_listen());
  }

  Future<void> _listen() async {
    final server = _server;
    if (server == null) {
      return;
    }

    await for (final request in server) {
      unawaited(_handleRequest(request));
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (!_isAuthorized(request)) {
        await _writeJson(
          request.response,
          401,
          {'ok': false, 'state': 'error', 'error': 'Unauthorized'},
        );
        return;
      }

      final path = request.uri.path;
      if (request.method == 'GET' && path == '/status') {
        final result = await _invokeNative('getCallStatus');
        await _writeJson(request.response, _httpStatusFromResult(result), result);
        return;
      }

      if (request.method != 'POST') {
        await _writeJson(
          request.response,
          404,
          {'ok': false, 'state': 'error', 'error': 'Route not found'},
        );
        return;
      }

      final body = await utf8.decoder.bind(request).join();
      final payload = body.isEmpty ? <String, dynamic>{} : jsonDecode(body) as Map<String, dynamic>;

      switch (path) {
        case '/answer':
          await _writeNativeResponse(request.response, 'answerCall');
          return;
        case '/reject':
          await _writeNativeResponse(request.response, 'rejectCall');
          return;
        case '/end':
          await _writeNativeResponse(request.response, 'endCall');
          return;
        case '/mute':
          await _writeNativeResponse(request.response, 'setMuted', payload);
          return;
        case '/speaker':
          await _writeNativeResponse(request.response, 'setSpeaker', payload);
          return;
        default:
          await _writeJson(
            request.response,
            404,
            {'ok': false, 'state': 'error', 'error': 'Route not found'},
          );
      }
    } catch (exc) {
      await _writeJson(
        request.response,
        500,
        {'ok': false, 'state': 'error', 'error': exc.toString()},
      );
    }
  }

  Future<void> _writeNativeResponse(
    HttpResponse response,
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    final result = await _invokeNative(method, arguments);
    await _writeJson(response, _httpStatusFromResult(result), result);
  }

  Future<Map<String, dynamic>> _invokeNative(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    try {
      final raw = await _channel.invokeMethod(method, arguments ?? <String, dynamic>{});
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      return {
        'ok': false,
        'state': 'error',
        'error': 'Native bridge returned an invalid payload.',
        'http_status': 500,
      };
    } on PlatformException catch (exc) {
      return {
        'ok': false,
        'state': 'error',
        'error': exc.message ?? exc.code,
        'http_status': 500,
      };
    } catch (exc) {
      return {
        'ok': false,
        'state': 'error',
        'error': exc.toString(),
        'http_status': 500,
      };
    }
  }

  Future<void> _writeJson(HttpResponse response, int statusCode, Map<String, dynamic> payload) async {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(payload));
    await response.close();
  }

  int _httpStatusFromResult(Map<String, dynamic> result) {
    final dynamic raw = result['http_status'];
    if (raw is int) {
      return raw;
    }
    return result['ok'] == true ? 200 : 500;
  }

  bool _isAuthorized(HttpRequest request) {
    final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
    if (_authToken.isEmpty) {
      return true;
    }
    return authHeader == 'Bearer $_authToken';
  }
}
