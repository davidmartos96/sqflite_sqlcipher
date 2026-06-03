import 'dart:core';

import 'package:flutter/services.dart';

/// Sqflite channel name
const String channelName = 'com.davidmartos96.sqflite_sqlcipher';

/// Sqflite channel
const MethodChannel channel = MethodChannel(channelName);

/// Invoke a native method
Future<T?> invokeMethod<T>(String method, [dynamic arguments]) =>
    channel.invokeMethod<T>(method, arguments);
