import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

/// Face Embedding Service
/// Extracts and stores face embeddings as double precision arrays
class FaceEmbeddingService {
  /// Extract face embedding from image file
  /// Returns a list of doubles representing the face embedding vector
  /// Used with face recognition algorithms (e.g., AWS Rekognition, FaceAPI, etc.)
  static Future<List<double>> extractFaceEmbedding(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Placeholder for face embedding extraction
      // In production, this would call your ML model or AWS Rekognition API
      // For now, returning a mock embedding vector (128 dimensions)
      final embedding = _generateMockEmbedding();
      return embedding;
    } catch (e) {
      throw Exception('Failed to extract face embedding: ${e.toString()}');
    }
  }

  /// Generate mock embedding vector (128-dimensional)
  /// In production, replace with actual ML model or API call
  static List<double> _generateMockEmbedding() {
    // AWS Rekognition uses 128-dimensional vectors
    // Replace this with actual embedding extraction
    return List<double>.generate(
      128,
      (index) => (index.toDouble() / 128.0) * 2.0 - 1.0,
    );
  }

  /// Serialize embedding to string for storage
  /// Converts list of doubles to comma-separated string
  static String serializeEmbedding(List<double> embedding) {
    return embedding
        .map((value) => value.toStringAsFixed(6))
        .toList()
        .join(',');
  }

  /// Deserialize embedding from string
  /// Converts comma-separated string back to list of doubles
  static List<double> deserializeEmbedding(String embeddingString) {
    return embeddingString
        .split(',')
        .map((value) => double.parse(value))
        .toList();
  }

  /// Calculate cosine similarity between two embeddings
  /// Returns value between 0 and 1 (1 = perfect match, 0 = no match)
  static double calculateSimilarity(
    List<double> embedding1,
    List<double> embedding2,
  ) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have the same length');
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    norm1 = norm1 > 0 ? sqrt(norm1) : 0.0;
    norm2 = norm2 > 0 ? sqrt(norm2) : 0.0;

    if (norm1 == 0.0 || norm2 == 0.0) {
      return 0.0;
    }

    return dotProduct / (norm1 * norm2);
  }

  /// Validate embedding vector
  static bool isValidEmbedding(List<double> embedding) {
    if (embedding.isEmpty || embedding.length != 128) {
      return false;
    }
    return embedding.every((value) => value.isFinite);
  }
}



