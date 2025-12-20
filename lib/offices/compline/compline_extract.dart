import 'dart:convert';
import '../../tools/data_loader.dart';
import '../../tools/file_paths.dart';

/// Helper function to search for celebrationTitle key in a JSON file
Future<String> complineTitleExtract(
  String title,
  DataLoader dataLoader,
) async {
  String complineTitle = '';
  try {
    String content = await dataLoader.loadJson('$specialFilePath/$title.json');
    if (content.isEmpty) {
      content = await dataLoader.loadJson('$sanctoralFilePath/$title.json');
    }
    if (content.isEmpty) {
      return '';
    }

    final jsonData = json.decode(content) as Map<String, dynamic>;

    // Return the celebrationTitle value if it exists
    // First, get the 'celebration' Map
    final celebration = jsonData['celebration'] as Map<String, dynamic>?;

    // Then, get the 'title' value from that Map
    if (celebration != null) {
      complineTitle = celebration['title'] as String? ?? '';
    }
  } catch (e) {
    // If any error occurs (file not found, parse error, etc.), return empty string
    return '';
  }
  return complineTitle;
}
