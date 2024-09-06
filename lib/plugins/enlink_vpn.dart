import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MethodChannelFlutterVpn {
  @visibleForTesting
  final methodChannel = const MethodChannel('helper_enlink_vpn');

  Future<bool> start({
    required String user,
    required String token,
    String? dns,
    String? apps,
    String? routes,
  }) async {
    if (!Platform.isAndroid) return true;
    return (await methodChannel.invokeMethod('start', {
      'user': user,
      'token': token,
      if (dns != null) 'dns': dns,
      if (apps != null) 'apps': apps,
      if (routes != null) 'routes': routes,
    }))!;
  }

  Future<bool> stop() async {
    if (!Platform.isAndroid) return true;
    return (await methodChannel.invokeMethod('stop'))!;
  }
}
