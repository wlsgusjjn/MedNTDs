import 'package:flutter/services.dart';

/// [DiseaseManual]
/// A utility class responsible for managing medical reference materials.
/// It implements a RAG (Retrieval-Augmented Generation) workflow by:
/// 1. Mapping AI visual keywords to specific disease asset folders.
/// 2. Loading text-based medical guidelines from the app assets.
/// 3. Formatting structured prompts for the second stage of AI reasoning.
class DiseaseManual {
  // Mapping of disease keywords to their respective asset directory paths.
  // These directories should contain .txt files with clinical guidelines.
  static const Map<String, String> diseasePaths = {
    'buruli ulcer': 'assets/docs/buruli-ulcer/',
    'cutaneous leishmaniasis': 'assets/docs/cutaneous-leishmaniasis/',
    'leprosy': 'assets/docs/leprosy/',
    'lymphatic filariasis': 'assets/docs/lymphatic-filariasis/',
    'mycetoma': 'assets/docs/mycetoma/',
    'scabies': 'assets/docs/scabies/',
    'tungiasis': 'assets/docs/tungiasis/',
    'yaws': 'assets/docs/yaws/',
  };

  /// [promptWithInfo]
  /// Constructs a structured "Chain of Thought" prompt for the LLM.
  /// It combines raw visual observations with loaded medical guidelines
  /// to generate a professional clinical evaluation without a definitive diagnosis.
  static String promptWithInfo(String content, String answerText) {
    return """<__media__><start_of_turn>user\nYou are a professional Medical Assistant. 
Your task is to analyze skin images based on the provided [Medical Reference Guidelines].

1. Identify clinical features (lesions, texture, color) from the image.
2. Explain how to prevent further transmission based on the guidelines.
3. Provide a brief, empathetic clinical suggestion for the patient.

Strictly follow a clinical, professional tone and avoid a definitive diagnosis.

[Medical Reference Guidelines]:
$content

[Observation]:
$answerText

[Instructions]:
Analyze the image based on medical guidelines and provide a professional evaluation:

1. **Feature Analysis**: Identify specific skin lesions and their precise anatomical locations.
2. **Guideline Correlation**: Explain how observed features match the disease characteristics in the guidelines.
3. **Patient Guidance**: 
   - Assess the potential **severity** and explain the likely **infection route**.
   - Provide clear instructions on **preventing further spread** (e.g., hygiene, contact).
4. **Clinical Action**: Strictly avoid definitive diagnosis but categorize the **urgency of medical evaluation** (e.g., immediate vs. routine) based on potential risks.

*Tone: Clinical, empathetic, and objective.*
<end_of_turn>\n<start_of_turn>model\n
""";
  }

  /// [getManualForContext]
  /// Scans the initial AI visual analysis text for specific disease keywords.
  /// If a keyword is found, it triggers the loading of the corresponding guideline files.
  static Future<String> getManualForContext(String diagnosisText) async {
    for (var disease in diseasePaths.keys) {
      if (diagnosisText.toLowerCase().contains(disease)) {
        return await _loadManualFiles(diseasePaths[disease]!);
      }
    }
    // Returns an empty string if no specific disease is recognized
    return "";
  }

  /// [_loadManualFiles]
  /// Dynamically loads all text (.txt) files from the specified asset folder.
  /// Uses AssetManifest to discover files within the subdirectories.
  static Future<String> _loadManualFiles(String folderPath) async {
    try {
      // Load the manifest to find all files included in the project assets
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

      // Filter the assets that match our target folder and have a .txt extension
      final files = manifest.listAssets().where((path) =>
        path.startsWith(folderPath) && path.endsWith('.txt'));

      StringBuffer fullText = StringBuffer();
      for (var path in files) {
        // Read file content as a string and append it to the buffer
        final content = await rootBundle.loadString(path);
        fullText.writeln(content);
      }
      return fullText.toString();
    } catch (e) {
      // Silent error handling: returns empty if assets are missing or unreadable
      return "";
    }
  }
}