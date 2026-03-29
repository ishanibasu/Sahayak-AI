import 'dart:convert'; // ← correct placement: top of file
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/emergency_request.dart';

class GeminiService {
  static const _apiKey = 'AIzaSyCADKDIzgO24HULWu59q5ZhWT_XP93nlV8';

  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
    generationConfig: GenerationConfig(
      //responseMimeType: 'application/json',
      maxOutputTokens: 256,
    ),
  );

  Future<({int score, CriticalityLevel level, String reasoning})>
      analyzeEmergency(String description) async {
    const prompt = '''
You are a 911 dispatch triage AI. Analyze the emergency description and respond 
ONLY with valid JSON in this exact schema:
{
  "score": <integer 1-100, where 100 = immediate life threat>,
  "level": <"critical" | "high" | "medium" | "low">,
  "reasoning": <one short sentence>
}

Rules:
- "critical" (80-100): Cardiac arrest, not breathing, severe bleeding, violence
- "high" (60-79): Injury, chest pain, unconscious person
- "medium" (30-59): Moderate injury, distress without immediate threat
- "low" (1-29): Non-urgent situations
''';

    try {
      final response = await _model.generateContent([
        Content.text('$prompt\n\nEmergency description: "$description"'),
      ]);

      final text = response.text ?? '{}';
      final parsed = _parseJson(text);

      return (
        score: (parsed['score'] as int?) ?? 50,
        level: CriticalityLevel.values.firstWhere(
          (e) => e.name == parsed['level'],
          orElse: () => CriticalityLevel.medium,
        ),
        reasoning: (parsed['reasoning'] as String?) ?? '',
      );
    } catch (_) {
      // Fallback if Gemini is unavailable
      return (
        score: 50,
        level: CriticalityLevel.medium,
        reasoning: 'AI unavailable'
      );
    }
  }

  Map<String, dynamic> _parseJson(String text) {
    try {
      // Strip markdown code fences if present
      final jsonRegex = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegex.firstMatch(text);
      if (match == null) return {};
      return jsonDecode(match.group(0)!) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
