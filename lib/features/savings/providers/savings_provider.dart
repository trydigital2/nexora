import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/supabase_service.dart';
import '../models/savings_goal.dart';

class SavingsState {
  final List<SavingsGoalModel> goals;
  final bool isLoading;
  final String? errorMessage;
  final SavingsGoalModel? recentlyCompletedGoal;

  const SavingsState({
    this.goals = const [],
    this.isLoading = false,
    this.errorMessage,
    this.recentlyCompletedGoal,
  });

  double get totalSavings => goals.fold(0.0, (sum, g) => sum + g.currentAmount);
  double get totalTarget => goals.fold(0.0, (sum, g) => sum + g.targetAmount);

  SavingsState copyWith({
    List<SavingsGoalModel>? goals,
    bool? isLoading,
    String? errorMessage,
    SavingsGoalModel? recentlyCompletedGoal,
    bool clearRecentlyCompleted = false,
  }) {
    return SavingsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      recentlyCompletedGoal:
          clearRecentlyCompleted ? null : (recentlyCompletedGoal ?? this.recentlyCompletedGoal),
    );
  }
}

class SavingsNotifier extends StateNotifier<SavingsState> {
  SavingsNotifier() : super(const SavingsState()) {
    loadGoals();
  }

  final _uuid = const Uuid();

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
        final client = SupabaseService.client!;
        final user = client.auth.currentUser;
        if (user != null) {
          final data = await client
              .from('savings_goals')
              .select('*, savings_contributions(*)')
              .eq('user_id', user.id);

          final list = (data as List).map((m) {
            final contribs = (m['savings_contributions'] as List?)
                    ?.map((c) => SavingsContribution.fromMap(c))
                    .toList() ??
                [];
            return SavingsGoalModel.fromMap(m, contributions: contribs);
          }).toList();

          state = state.copyWith(goals: list, isLoading: false);
          return;
        }
      }

      state = state.copyWith(
        goals: _generateDemoGoals(),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading savings goals: $e');
      state = state.copyWith(
        goals: _generateDemoGoals(),
        isLoading: false,
      );
    }
  }

  Future<bool> addGoal({
    required String title,
    required double targetAmount,
    required DateTime targetDate,
    double initialAmount = 0.0,
    String iconName = 'savings',
    String colorHex = '#7257E8',
    String? notes,
  }) async {
    final now = DateTime.now();
    final newGoal = SavingsGoalModel(
      id: _uuid.v4(),
      userId: 'user-active',
      title: title.trim(),
      targetAmount: targetAmount,
      currentAmount: initialAmount,
      targetDate: targetDate,
      iconName: iconName,
      colorHex: colorHex,
      notes: notes?.trim(),
      createdAt: now,
      updatedAt: now,
      contributions: initialAmount > 0
          ? [
              SavingsContribution(
                id: _uuid.v4(),
                goalId: 'initial',
                userId: 'user-active',
                amount: initialAmount,
                note: 'Initial deposit',
                date: now,
                createdAt: now,
              ),
            ]
          : [],
    );

    state = state.copyWith(goals: [...state.goals, newGoal]);

    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        final user = SupabaseService.client!.auth.currentUser;
        if (user != null) {
          await SupabaseService.client!.from('savings_goals').insert(
                newGoal.copyWith(userId: user.id).toMap(),
              );
        }
      } catch (e) {
        debugPrint('Error inserting savings goal in Supabase: $e');
      }
    }
    return true;
  }

  Future<bool> addContribution({
    required String goalId,
    required double amount,
    String? note,
  }) async {
    final index = state.goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return false;

    final goal = state.goals[index];
    final newCurrent = goal.currentAmount + amount;
    final isNowCompleted = newCurrent >= goal.targetAmount;

    final now = DateTime.now();
    final contribution = SavingsContribution(
      id: _uuid.v4(),
      goalId: goalId,
      userId: goal.userId,
      amount: amount,
      note: note,
      date: now,
      createdAt: now,
    );

    final updatedGoal = goal.copyWith(
      currentAmount: newCurrent,
      isCompleted: isNowCompleted,
      updatedAt: now,
      contributions: [contribution, ...goal.contributions],
    );

    final updatedList = List<SavingsGoalModel>.from(state.goals);
    updatedList[index] = updatedGoal;

    state = state.copyWith(
      goals: updatedList,
      recentlyCompletedGoal: isNowCompleted ? updatedGoal : null,
    );

    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        await SupabaseService.client!.from('savings_goals').update({
          'current_amount': newCurrent,
          'is_completed': isNowCompleted,
          'updated_at': now.toIso8601String(),
        }).eq('id', goalId);

        await SupabaseService.client!.from('savings_contributions').insert(
              contribution.toMap(),
            );
      } catch (e) {
        debugPrint('Error updating savings contribution in Supabase: $e');
      }
    }
    return true;
  }

  void clearRecentlyCompleted() {
    state = state.copyWith(clearRecentlyCompleted: true);
  }

  Future<bool> deleteGoal(String id) async {
    state = state.copyWith(
      goals: state.goals.where((g) => g.id != id).toList(),
    );

    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        await SupabaseService.client!.from('savings_goals').delete().eq('id', id);
      } catch (e) {
        debugPrint('Error deleting savings goal in Supabase: $e');
      }
    }
    return true;
  }

  List<SavingsGoalModel> _generateDemoGoals() {
    final now = DateTime.now();
    return [
      SavingsGoalModel(
        id: 'goal-1',
        userId: 'demo-user-1',
        title: 'Emergency Reserve Fund',
        targetAmount: 15000.00,
        currentAmount: 11250.00,
        targetDate: DateTime(now.year + 1, 3, 31),
        iconName: 'shield',
        colorHex: '#35C99A',
        notes: '6 months of living expenses in high-yield account',
        createdAt: DateTime(now.year, now.month - 4, 1),
        updatedAt: now,
      ),
      SavingsGoalModel(
        id: 'goal-2',
        userId: 'demo-user-1',
        title: 'MacBook Pro M4 Max',
        targetAmount: 3499.00,
        currentAmount: 2600.00,
        targetDate: DateTime(now.year, now.month + 2, 15),
        iconName: 'laptop',
        colorHex: '#7257E8',
        notes: 'High performance machine for AI development',
        createdAt: DateTime(now.year, now.month - 2, 1),
        updatedAt: now,
      ),
      SavingsGoalModel(
        id: 'goal-3',
        userId: 'demo-user-1',
        title: 'Tokyo & Kyoto Vacation',
        targetAmount: 4800.00,
        currentAmount: 1950.00,
        targetDate: DateTime(now.year, now.month + 5, 10),
        iconName: 'flight',
        colorHex: '#FF7A00',
        notes: 'Autumn cherry blossom & tech tour',
        createdAt: DateTime(now.year, now.month - 1, 1),
        updatedAt: now,
      ),
      SavingsGoalModel(
        id: 'goal-4',
        userId: 'demo-user-1',
        title: 'Electric Vehicle Down Payment',
        targetAmount: 10000.00,
        currentAmount: 10000.00,
        targetDate: DateTime(now.year, now.month - 1, 1),
        iconName: 'car',
        colorHex: '#38BDF8',
        isCompleted: true,
        notes: 'Goal reached! Ready for allocation',
        createdAt: DateTime(now.year - 1, 6, 1),
        updatedAt: now,
      ),
    ];
  }
}

final savingsProvider =
    StateNotifierProvider<SavingsNotifier, SavingsState>((ref) {
  return SavingsNotifier();
});

