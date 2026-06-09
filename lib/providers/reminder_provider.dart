import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/medication_plan.dart';

/// 用药提醒Provider - 本地存储版
class ReminderProvider extends ChangeNotifier {
  List<MedicationPlan> _plans = [];
  bool _isLoading = false;

  List<MedicationPlan> get plans => _plans;
  bool get isLoading => _isLoading;

  Box get _box => Hive.box('medication_data');

  ReminderProvider() {
    loadPlans();
  }

  void loadPlans() {
    _isLoading = true;
    notifyListeners();

    final data = _box.get('plans', defaultValue: '[]');
    final list = jsonDecode(data) as List;
    _plans = list.map((e) => MedicationPlan.fromJson(e)).toList();
    _isLoading = false;
    notifyListeners();
  }

  void _savePlans() {
    final data = jsonEncode(_plans.map((e) => e.toJson()).toList());
    _box.put('plans', data);
  }

  Future<void> addPlan(MedicationPlan plan) async {
    _plans.add(plan);
    _savePlans();
    notifyListeners();
  }

  Future<void> updatePlan(MedicationPlan plan) async {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index >= 0) {
      _plans[index] = plan;
      _savePlans();
      notifyListeners();
    }
  }

  Future<void> deletePlan(String id) async {
    _plans.removeWhere((p) => p.id == id);
    _savePlans();
    notifyListeners();
  }

  List<MedicationPlan> getPendingPlans() {
    final now = DateTime.now();
    return _plans.where((p) =>
      p.isActive &&
      p.startTime != null &&
      p.startTime!.isBefore(now) &&
      (p.endTime == null || p.endTime!.isAfter(now))
    ).toList();
  }

  List<MedicationPlan> getPlansForDate(DateTime date) {
    return _plans.where((p) {
      if (!p.isActive) return false;
      if (p.startTime != null && p.startTime!.isAfter(date)) return false;
      if (p.endTime != null && p.endTime!.isBefore(date)) return false;
      return true;
    }).toList();
  }
}
