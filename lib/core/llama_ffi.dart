import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

/// [Opaque Pointers]
/// These classes represent raw C++ memory addresses (pointers).
/// They are 'Opaque' because Flutter doesn't need to know the internal structure
/// of the Llama model; it just needs to hold the address to pass it back to C++.
base class LlamaModel extends Opaque {}
base class LlamaAdapterLora extends Opaque {}
base class MtmdBridgeContext extends Opaque {}
base class MtmdInputChunks extends Opaque {}

/// [DecodeParams]
/// A structure that mirrors the C++ 'DecodeParams' struct exactly.
/// This allows Flutter to pass hyper-parameters like Temperature and TopK
/// directly to the native AI engine.
base class DecodeParams extends Struct {
  @Float()
  external double temperature;        // Controls randomness: Higher = more creative
  @Int32()
  external int topK;                  // Limits vocabulary to top K most likely words
  @Float()
  external double repetitionPenalty;  // Penalizes repeated phrases
  @Int32()
  external int maxNewTokens;          // Maximum length of the generated response
}

/// [LlamaFFI]
/// The low-level bridge between Dart and the Native C++ library (DLL/SO).
/// It handles library loading, function mapping, and raw memory allocation.
class LlamaFFI {
  late DynamicLibrary _lib;

  // Native C++ Function Definitions mapped to Dart Functions
  late Pointer<LlamaModel> Function(Pointer<Utf8>) _loadModel;
  late Pointer<Float> Function(Pointer<MtmdBridgeContext>, Pointer<MtmdInputChunks>) _getEmbedding;
  late Pointer<LlamaAdapterLora> Function(Pointer<LlamaModel>, Pointer<Utf8>) _loadLoraAdapter;
  late int Function(Pointer<MtmdBridgeContext>, Pointer<LlamaAdapterLora>, double) _applyLoraAdapterMtmd;
  late Pointer<MtmdBridgeContext> Function(Pointer<Utf8>, Pointer<Utf8>, int, int) _mtmdInit;
  late int Function(Pointer<MtmdBridgeContext>, Pointer<Utf8> imagePath) _mtmdLoadImage;
  late Pointer<MtmdInputChunks> Function(Pointer<MtmdBridgeContext>, Pointer<Utf8> prompt) _mtmdTokenize;
  late int Function(Pointer<MtmdBridgeContext>, Pointer<MtmdInputChunks>, Pointer<Float>) _mtmdEval;
  late Pointer<Utf8> Function(Pointer<MtmdBridgeContext>, int) _generate_response;
  late void Function(Pointer<MtmdBridgeContext>) _resetSession;

  LlamaFFI() {
    // Load the platform-specific compiled binary
    _lib = Platform.isAndroid
        ? DynamicLibrary.open("libnative_bridge.so") // Android Shared Library
        : Platform.isWindows
        ? DynamicLibrary.open("native_bridge.dll")  // Windows Dynamic Link Library
        : DynamicLibrary.process();
    _init();
  }

  /// Looks up each function name in the compiled binary and links it to our Dart definitions.
  void _init() {

    _loadModel = _lib.lookupFunction<
        Pointer<LlamaModel> Function(Pointer<Utf8>),
        Pointer<LlamaModel> Function(Pointer<Utf8>)>('load_model');

    _getEmbedding = _lib.lookupFunction<
        Pointer<Float> Function(Pointer<MtmdBridgeContext>, Pointer<MtmdInputChunks>),
        Pointer<Float> Function(Pointer<MtmdBridgeContext>, Pointer<MtmdInputChunks>)>('get_image_embedding');

    _loadLoraAdapter = _lib.lookupFunction<
        Pointer<LlamaAdapterLora> Function(Pointer<LlamaModel>, Pointer<Utf8>),
        Pointer<LlamaAdapterLora> Function(Pointer<LlamaModel>, Pointer<Utf8>)>('load_lora_adapter');

    _applyLoraAdapterMtmd = _lib.lookupFunction<
        Int32 Function(Pointer<MtmdBridgeContext>, Pointer<LlamaAdapterLora>, Float),
        int Function(Pointer<MtmdBridgeContext>, Pointer<LlamaAdapterLora>, double)>('mtmd_bridge_apply_lora');

    _mtmdInit = _lib.lookupFunction<
        Pointer<MtmdBridgeContext> Function(Pointer<Utf8>, Pointer<Utf8>, Int32, Int32),
        Pointer<MtmdBridgeContext> Function(Pointer<Utf8>, Pointer<Utf8>, int, int)>('mtmd_bridge_init');

    _mtmdLoadImage = _lib.lookupFunction<
        Int32 Function(Pointer<MtmdBridgeContext>, Pointer<Utf8>),
        int Function(Pointer<MtmdBridgeContext>, Pointer<Utf8>)>('mtmd_bridge_load_image');

    _mtmdTokenize = _lib.lookupFunction<
        Pointer<MtmdInputChunks> Function(Pointer<MtmdBridgeContext>, Pointer<Utf8>),
        Pointer<MtmdInputChunks> Function(Pointer<MtmdBridgeContext>, Pointer<Utf8>)>('mtmd_bridge_tokenize');

    _mtmdEval = _lib.lookupFunction<
        Int32 Function(Pointer<MtmdBridgeContext>, Pointer<MtmdInputChunks>, Pointer<Float>),
        int Function(Pointer<MtmdBridgeContext>, Pointer<MtmdInputChunks>, Pointer<Float>)>('mtmd_bridge_eval');

    _generate_response = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<MtmdBridgeContext>, Int32),
        Pointer<Utf8> Function(Pointer<MtmdBridgeContext>,  int)>('mtmd_bridge_generate_response');

    _resetSession = _lib.lookupFunction<
        Void Function(Pointer<MtmdBridgeContext>),
        void Function(Pointer<MtmdBridgeContext>)>('mtmd_bridge_reset_session');
  }


  // --- Wrapper Methods: Converting Dart types to C-friendly Native types ---
  Pointer<LlamaModel> loadModel(String path) => _loadModel(path.toNativeUtf8());

  /// [getEmbedding]
  Pointer<Float> getEmbedding(Pointer<MtmdBridgeContext> ctx, Pointer<MtmdInputChunks> chunks) {
    return _getEmbedding(ctx, chunks);
  }

  /// [loadLoraAdapter]
  /// Load the LoRA adapter.
  Pointer<LlamaAdapterLora> loadLoraAdapter(Pointer<LlamaModel> model, String path) {
    return _loadLoraAdapter(model, path.toNativeUtf8());
  }

  /// [applyLoraAdapter]
  /// Adjusts the influence of the LoRA adapter (0.0 to 1.0).
  int applyLoraAdapterMtmd(Pointer<MtmdBridgeContext> ctx, Pointer<LlamaAdapterLora> adapter, double scale) {
    return _applyLoraAdapterMtmd(ctx, adapter, scale);
  }

  Pointer<MtmdBridgeContext> mtmdInit(
      String model, String mmproj, int threads, int nBatch) {
    return _mtmdInit(
      model.toNativeUtf8(),
      mmproj.toNativeUtf8(),
      threads,
      nBatch,
    );
  }

  bool mtmdLoadImage(Pointer<MtmdBridgeContext> ctx, String path) {
    return _mtmdLoadImage(ctx, path.toNativeUtf8()) != 0;
  }

  Pointer<MtmdInputChunks> mtmdTokenize(
      Pointer<MtmdBridgeContext> ctx, String prompt) {
    return _mtmdTokenize(ctx, prompt.toNativeUtf8());
  }

  bool mtmdEval(
      Pointer<MtmdBridgeContext> ctx, Pointer<MtmdInputChunks> chunks, Pointer<Float> emd) {
    return _mtmdEval(ctx, chunks, emd) != 0;
  }

  String generate_response(Pointer<MtmdBridgeContext> ctx, int n_predict) {
    final resPtr = _generate_response(ctx, n_predict);
    final str = resPtr.toDartString(); // Convert C return string back to Dart
    return str;
  }

  /// [freeEmbedding]
  /// Reset KV cache.
  void resetSession(Pointer<MtmdBridgeContext> ctx) => _resetSession(ctx);
}