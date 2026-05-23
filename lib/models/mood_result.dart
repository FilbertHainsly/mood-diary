// Model untuk menampung hasil prediksi mood dari API.
class MoodResult {
  final String mood;
  final double confidence;

  MoodResult({
    required this.mood,
    required this.confidence,
  });

  // Parsing JSON response dari API menjadi objek MoodResult.
  factory MoodResult.fromJson(Map<String, dynamic> json) {
    return MoodResult(
      mood: json['mood']?.toString() ?? 'Unknown',
      // Confidence bisa dikirim sebagai int/double, jadi kita pakai num.
      confidence: (json['confidence'] is num)
          ? (json['confidence'] as num).toDouble()
          : double.tryParse(json['confidence']?.toString() ?? '0') ?? 0.0,
    );
  }
}
