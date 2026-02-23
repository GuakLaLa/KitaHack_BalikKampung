import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIPriorityService {
  static Future<Map<String, dynamic>> evaluatePriority({
    required String victimStatus,
    required String waterLevel,
    required int peopleAffected,
    required bool elderly,
    required bool disabled,
    required bool children,
    required String description,
  }) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      print("API KEY BEING USED: $apiKey");

      if (apiKey == null || apiKey.isEmpty) {
        print("Gemini API key missing. Using fallback.");
        return _fallbackPriority(
          victimStatus,
          waterLevel,
          peopleAffected,
          elderly,
          disabled,
          children,
        );
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final prompt = """
You are an emergency flood rescue AI.

Evaluate the rescue priority based on:

Victim Status: $victimStatus
Water Level: $waterLevel
People Affected: $peopleAffected
Elderly: $elderly
Disabled: $disabled
Children: $children

User Situation Description:
$description

Rules:
- High = Life threatening / severe danger
- Medium = Needs rescue but not critical
- Low = Safe / minor urgency

Return ONLY valid JSON without explanation:

{
  "priorityScore": number (0–100),
  "priorityLevel": "High" | "Medium" | "Low",
  "reason": "short explanation"
}
""";

      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      final text = response.text;

      if (text == null || text.isEmpty) {
        print("Gemini returned empty response. Using fallback.");
        return _fallbackPriority(
          victimStatus,
          waterLevel,
          peopleAffected,
          elderly,
          disabled,
          children,
        );
      }

      print("Gemini RAW response:");
      print(text);

      final cleaned = text
          .replaceAll("```json", "")
          .replaceAll("```", "")
          .trim();

      final Map<String, dynamic> jsonData = jsonDecode(cleaned);

      return {
        "priorityScore": jsonData["priorityScore"] ?? 0,
        "priorityLevel": jsonData["priorityLevel"] ?? "Low",
        "reason": jsonData["reason"] ?? "AI evaluation",
      };
    } catch (e) {
      print("Gemini error: $e");
      return _fallbackPriority(
        victimStatus,
        waterLevel,
        peopleAffected,
        elderly,
        disabled,
        children,
      );
    }
  }

  ///Smart Fallback Logic (Rule-based backup)
  static Map<String, dynamic> _fallbackPriority(
    String victimStatus,
    String waterLevel,
    int peopleAffected,
    bool elderly,
    bool disabled,
    bool children,
  ) {
    int score = 0;

    // Victim condition
    if (victimStatus.toLowerCase().contains("trapped")) {
      score += 30;
    } else if (victimStatus.toLowerCase().contains("safe but stranded")) {
      score += 20;
    } else if (victimStatus.toLowerCase().contains("safe")) {
      score += 10;
    } else {
      score += 10;
    }

    // Water level
    switch (waterLevel) {
      case "Foot":
        score += 5;
        break;
      case "Knee":
        score += 10;
        break;
      case "Waist":
        score += 20;
        break;
      case "Chest":
        score += 30;
        break;
      case "Head / Above Head":
        score += 40;
        break;
    }

    // People affected
    if (peopleAffected >= 10) {
      score += 25;
    } else if (peopleAffected >= 5) {
      score += 15;
    } else {
      score += 5;
    }

    // Vulnerable groups
    if (elderly) score += 10;
    if (disabled) score += 15;
    if (children) score += 10;

    String level = "Low";
    if (score >= 70) {
      level = "High";
    } else if (score >= 40) {
      level = "Medium";
    } else {
      level = "Low";
    }

    return {
      "priorityScore": score,
      "priorityLevel": level,
      "reason": "Fallback rule-based evaluation used.",
    };
  }
}