import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStore {
  static const _completedKey = 'linguamate_onboarding_completed_v147';
  static const _languageKey = 'linguamate_onboarding_language_v147';
  static const _goalKey = 'linguamate_onboarding_goal_v147';

  const OnboardingStore();

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<String> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'English';
  }

  Future<String> loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_goalKey) ?? '日常英文';
  }

  Future<void> complete({
    required String language,
    required String goal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
    await prefs.setString(_languageKey, language);
    await prefs.setString(_goalKey, goal);
  }

  Future<void> skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
  }
}
