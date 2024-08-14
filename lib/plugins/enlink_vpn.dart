import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MethodChannelFlutterVpn {
  @visibleForTesting
  final methodChannel = const MethodChannel('helper_enlink_vpn');

  @visibleForTesting
  final eventChannel = const EventChannel('helper_enlink_vpn_event');

  Future<bool> start() async {
    if (!Platform.isAndroid) return true;
    return (await methodChannel.invokeMethod<bool>('start'))!;
  }

  Future<bool> connect({
    required String address,
    required Int mask,
    required String dns,
    String? apps,
  }) async {
    if (!Platform.isAndroid) return true;
    return (await methodChannel.invokeMethod('connect', {
      'address': address,
      'mask': mask,
      'dns': dns,
      if (apps != null) 'apps': apps
    }))!;
  }

  Future<bool> write({required ByteData data}) async {
    if (!Platform.isAndroid) return true;
    return (await methodChannel.invokeMethod('write', data))!;
  }
}
