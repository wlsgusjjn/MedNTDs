import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import '../core/llama_ffi.dart';
import '../data/disease_manual.dart';
import '../data/history_database.dart';

/// [AIInferenceService]
/// Handles the multimodal AI logic, including model initialization,
/// image embedding extraction, and multi-step medical reasoning.
class AIInferenceService {
  final LlamaFFI _ffi = LlamaFFI();

  /// Loads the required GGUF models (Text, CLIP, and LoRA) from provided paths.
  /// Returns a record containing the native pointers for inference.
  (Pointer<LlamaModel>, Pointer<LlamaAdapterLora>, Pointer<MtmdBridgeContext>) initialize(
      String modelPath, String clipPath, String loraPath) {

    // A. Load the main text model (e.g., MedGemma)
    final modelPathPtr = modelPath.toNativeUtf8();
    final Pointer<LlamaModel> m = _ffi.loadModel(modelPath);
    malloc.free(modelPathPtr);
    if (m.address == 0) throw Exception("Failed to load text model!");

    // B. Load the LoRA adapter for fine-tuned medical reasoning
    final Pointer<LlamaAdapterLora> l = _ffi.loadLoraAdapter(m, loraPath);
    if (l.address == 0) throw Exception("Failed to load LoRA adapter!");

    int n_cores = Platform.numberOfProcessors;
    print("System processor cores available: $n_cores");

    // C. Load the Mtmd model for image + text inference
    final Pointer<MtmdBridgeContext> mtmdM = _ffi.mtmdInit(modelPath, clipPath, n_cores, 256);
    print("--- All multimodal models successfully loaded ---");
    return (m, l, mtmdM);
  }

  /// Runs the full diagnostic pipeline:
  /// 1. Extract image embeddings -> 2. Initial visual analysis ->
  /// 3. Keyword matching with WHO guidelines -> 4. Final professional suggestion.
  Future<String> runDiagnosis(
    Pointer<LlamaAdapterLora> loraAdapter,
    Pointer<MtmdBridgeContext> mtmdM,
    String imagePath,
    Uint8List originalBytes,  // Original encoded bytes for storage
  ) async {
    int maxNewTokens = 20;

    _ffi.resetSession(mtmdM);

    // Apply LoRA adapter to focus the model on medical knowledge
    _ffi.applyLoraAdapterMtmd(mtmdM, loraAdapter, 1.0);
    print("LoRA adapter applied for medical reasoning.");

    final stopwatch = Stopwatch()..start();

    // Phase 1: Ask the AI to identify what it sees in the image
    _ffi.mtmdLoadImage(mtmdM, imagePath);
    String prompt = "<__media__><<start_of_turn>user\nWhat skin features are visible in this image?<end_of_turn>\n<start_of_turn>model\n";
    final chunks = _ffi.mtmdTokenize(mtmdM, prompt);
    if (chunks.address == 0) {
      throw Exception("Tokenize failed: chunks is null");
    }

    // Step 1: Generate embeddings using CLIP
    final emb = _ffi.getEmbedding(mtmdM, chunks);
    print("Time spent generating embeddings: ${stopwatch.elapsedMilliseconds}ms");

    final resEval = _ffi.mtmdEval(mtmdM, chunks, emb);

    String answerText = _ffi.generate_response(mtmdM, maxNewTokens);
    print("#1 Visual Analysis: $answerText");

    // Step 2: Check if identified features match any disease guidelines in our manual
    final String manual = await DiseaseManual.getManualForContext(answerText);
    if (manual.isNotEmpty) {
      // If a match is found, update prompt with WHO guidelines for professional suggestion
      prompt = DiseaseManual.promptWithInfo(manual, answerText);
      maxNewTokens = 1024;
    }
    else {
      maxNewTokens = 256;
    }
    // Reset LoRA before final generation
    _ffi.applyLoraAdapterMtmd(mtmdM, loraAdapter, 0.0);
    print("LFinal reasoning phase initiated.");

    final resEval2 = _ffi.mtmdEval(mtmdM, chunks, emb);

    // Phase 2: Generate the final medical suggestion/guidance
    answerText = _ffi.generate_response(mtmdM, maxNewTokens);
    print("#2 Final Clinical Response: $answerText");

    // Step 3: Automatically save the diagnosis and original image to History DB
    if (answerText.isNotEmpty) {
       await HistoryDatabase.instance.saveRecord(originalBytes, answerText);
    }
    return answerText;
  }
}