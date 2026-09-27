import 'package:shared_preferences/shared_preferences.dart';

class DailyGoalStore {
  static const _key = 'linguamate_daily_goal_v120';
  static const defaultGoal = 10;
  static const supportedGoals = <int>[5, 10, 15, 20];

  const DailyGoalStore();

  Future<int> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_key);
    return supportedGoals.contains(value) ? value! : defaultGoal;
  }

  Future<void> save(int goal) async {
    final normalized =
        supportedGoals.contains(goal) ? goal : defaultGoal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, normalized);
  }
}
