import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Required for SQLite on Desktop
import 'ui/screens/diagnostic_screen.dart';

void main() async {
  // Ensure that plugin services are initialized before the app starts
  WidgetsFlutterBinding.ensureInitialized();

  /// [Platform-Specific Database Initialization]
  /// The standard sqflite package does not support Desktop (Windows/Linux) out of the box.
  /// We use sqflite_common_ffi to manually initialize the database factory for these platforms.
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI (Foreign Function Interface) for SQLite
    sqfliteFfiInit();
    // Set the global databaseFactory to the FFI implementation
    databaseFactory = databaseFactoryFfi;
  }

  /// [Camera Initialization]
  /// Fetches the list of available cameras on the device (Mobile or Laptop Webcam).
  /// This list is passed to the DiagnosticScreen for the CameraPreview.
  final cameras = await availableCameras();

  runApp(MaterialApp(
    theme: ThemeData.dark(),
    home: DiagnosticScreen(cameras: cameras),
  ));
}