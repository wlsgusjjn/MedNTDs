import 'dart:ffi';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/llama_ffi.dart';
import '../../services/ai_inference_service.dart';
import 'history_screen.dart';

/// [DiagnosticScreen]
/// The main interface for AI-powered skin analysis.
/// Supports real-time camera capture, gallery uploads, and manual GGUF model loading.
class DiagnosticScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const DiagnosticScreen({super.key, required this.cameras});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  Pointer<LlamaModel>? _model;
  Pointer<LlamaAdapterLora>? _lora;


  Pointer<MtmdBridgeContext>? _mtmdM;


  bool modelLoaded = false;

  CameraController? _controller;
  final AIInferenceService _aiService = AIInferenceService();
  final ImagePicker _imagePicker = ImagePicker();

  // State Variables (Original Style)
  bool _isCameraMode = true;              // Toggle between Camera Preview and Captured Image
  Uint8List? _capturedBytes;              // Stores the encoded (JPG/PNG) bytes of the image
  String answer = "";                     // AI analysis result text
  String status = "Please load models.";  // Current system status message

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  /// Initializes the hardware camera (Webcam on Windows, Camera Module on Android)
  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => status = "Camera Error: $e");
    }
  }


  /// Opens file pickers to manually load GGUF model files (Text model, CLIP, and LoRA)
  Future<void> _pickAndLoadModels() async {
    await Permission.manageExternalStorage.request();

    // Pick the three required model files
    FilePickerResult? modelFile = await FilePicker.platform.pickFiles(
        type: FileType.any, dialogTitle: "Select MedGemma GGUF"
    );
    FilePickerResult? clipFile = await FilePicker.platform.pickFiles(
        type: FileType.any, dialogTitle: "Select CLIP GGUF"
    );
    FilePickerResult? loraFile = await FilePicker.platform.pickFiles(
        type: FileType.any, dialogTitle: "Select LoRA GGUF"
    );

    if (modelFile != null && clipFile != null && loraFile != null) {
      setState(() => status = "Loading models... This may take a moment.");

      // Initialize the native pointers via the AI service
      final result2 = await _aiService.initialize(modelFile.files.single.path!, clipFile.files.single.path!, loraFile.files.single.path!);
      _model = result2.$1;
      _lora = result2.$2;
      _mtmdM = result2.$3;
      setState(() => status = "Models Loaded Successfully.");
      modelLoaded = true;
    }
  }

  /// Opens file pickers to manually load GGUF model files (Text model, CLIP, and LoRA)
  Future<void> _pickAndLoadModels2() async {
    await Permission.manageExternalStorage.request();

    // Pick the three required model files
    FilePickerResult? modelFile = await FilePicker.platform.pickFiles(
        type: FileType.any, dialogTitle: "Select MedGemma GGUF"
    );
    FilePickerResult? clipFile = await FilePicker.platform.pickFiles(
        type: FileType.any, dialogTitle: "Select CLIP GGUF"
    );
    FilePickerResult? loraFile = await FilePicker.platform.pickFiles(
        type: FileType.any, dialogTitle: "Select LoRA GGUF"
    );

    if (modelFile != null && clipFile != null && loraFile != null) {
      setState(() => status = "Loading models... This may take a moment.");

      // Initialize the native pointers via the AI service
      final result2 = await _aiService.initialize(modelFile.files.single.path!, clipFile.files.single.path!, loraFile.files.single.path!);
      //_lora = result2.$1;
      //_mtmdM = result2.$2;
      setState(() => status = "Models Loaded Successfully.");
      modelLoaded = true;
    }
  }

  /// Captures a frame from the live camera feed
  Future<void> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (!modelLoaded) {
      setState(() => status = "Error: Load models using the top button first!");
      return;
    }
    final file = await _controller!.takePicture();
    final bytes = await file.readAsBytes();
    setState(() {
      _capturedBytes = bytes;
      _isCameraMode = false;
    });
    _runInference(file.path, bytes);
  }

  /// Picks an image from the local gallery
  Future<void> pickImage() async {
    if (!modelLoaded) {
      setState(() => status = "Error: Load models using the top button first!");
      return;
    }
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _capturedBytes = bytes;
      _isCameraMode = false;
    });
    _runInference(file.path, bytes);
  }

  /// Orchestrates the AI analysis process
  Future<void> _runInference(String imagePath, bytes) async {
    if (!modelLoaded) {
      setState(() => status = "Error: Load models using the top button first!");
      return;
    }
    // Brief delay to allow UI to update (spinner/status)
    await Future.delayed(Duration(milliseconds: 1000));
    final stopwatch = Stopwatch()..start();
    setState(() => status = "AI is analyzing image...");
    // Run Native Inference and save to History DB
    final aiResponse = await _aiService.runDiagnosis(
      _lora!, _mtmdM!,
      imagePath,
      bytes,  // Pass original encoded bytes for DB storage
    );
    setState(() {
      answer = aiResponse;
      status = "Analysis Complete";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // AppBar added for Model Loading without breaking the main Row layout
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("MedNTDs", style: TextStyle(color: Colors.white)),
        actions: [
          _btn("Load GGUF Models", Colors.indigo, _pickAndLoadModels),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // ---------------- LEFT PANEL (Camera / Image) ----------------
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text("Camera View", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: _isCameraMode
                          ? (_controller != null && _controller!.value.isInitialized
                          ? CameraPreview(_controller!)
                          : const CircularProgressIndicator())
                          : (_capturedBytes != null
                          ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0), // Mirroring for Windows
                        child: Image.memory(_capturedBytes!),
                      )
                          : const Text("No Image", style: TextStyle(color: Colors.white70))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _btn("Capture", Colors.blue, captureImage),
                      const SizedBox(width: 12),
                      _btn("Upload", Colors.teal, pickImage),
                      const SizedBox(width: 12),
                      _btn("Reset", Colors.grey, () {
                        setState(() {
                          _isCameraMode = true;
                          _capturedBytes = null;
                          answer = "";
                          status = (modelLoaded) ? "Ready" : "Load models";
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // ---------------- RIGHT PANEL (AI Response) ----------------
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("AI Analysis", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent)),
                  const SizedBox(height: 10),
                  Text(status, style: const TextStyle(color: Colors.greenAccent)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: 100,
                          ),
                          child: answer.isEmpty ? Text(
                            "Waiting for medical image analysis...",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ) : MarkdownBody(
                            data: answer,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                              h1: const TextStyle(color: Colors.lightBlueAccent, fontSize: 20, fontWeight: FontWeight.bold),
                              h2: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              listBullet: const TextStyle(color: Colors.lightBlueAccent),
                              strong: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Custom button builder for consistent UI styling
  Widget _btn(String t, Color c, VoidCallback f) {
    return ElevatedButton(
      onPressed: f,
      style: ElevatedButton.styleFrom(backgroundColor: c),
      child: Text(t, style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}