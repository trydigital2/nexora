import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/supabase_service.dart';
import '../models/budget.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transaction_provider.dart';

class BudgetState {
  final List<BudgetModel> rawBudgets;
  final bool isLoading;
  final String? errorMessage;

  const BudgetState({
    this.rawBudgets = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BudgetState copyWith({
    List<BudgetModel>? rawBudgets,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BudgetState(
      rawBudgets: rawBudgets ?? this.rawBudgets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  BudgetNotifier() : super(const BudgetState()) {
    loadBudgets();
  }

  final _uuid = const Uuid();

  Future<void> loadBudgets() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
        final client = SupabaseService.client!;
        final user = client.auth.currentUser;
        if (user != null) {
          final data = await client
              .from('budgets')
              .select()
              .eq('user_id', user.id);

          final list = (data as List).map((m) => BudgetModel.fromMap(m)).toList();
          state = state.copyWith(rawBudgets: list, isLoading: false);
          return;
        }
      }

      state = state.copyWith(
        rawBudgets: _generateDemoBudgets(),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading budgets: $e');
      state = state.copyWith(
        rawBudgets: _generateDemoBudgets(),
        isLoading: false,
      );
    }
  }

  Future<bool> addBudget({
    required String category,
    required double amount,
    int? month,
    int? year,
    double alertThreshold = 0.8,
  }) async {
    final now = DateTime.now();
    final newBudget = BudgetModel(
      id: _uuid.v4(),
      userId: 'user-active',
      category: category,
      amount: amount,
      month: month ?? now.month,
      year: year ?? now.year,
      alertThreshold: alertThreshold,
      createdAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      rawBudgets: [...state.rawBudgets, newBudget],
    );

    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        final user = SupabaseService.client!.auth.currentUser;
        if (user != null) {
          await SupabaseService.client!.from('budgets').insert(
                newBudget.copyWith(userId: user.id).toMap(),
              );
        }
      } catch (e) {
        debugPrint('Error inserting budget in Supabase: $e');
      }
    }
    return true;
  }

  Future<bool> updateBudget(BudgetModel budget) async {
    final index = state.rawBudgets.indexWhere((b) => b.id == budget.id);
    if (index == -1) return false;

    final updated = List<BudgetModel>.from(state.rawBudgets);
    updated[index] = budget.copyWith(updatedAt: DateTime.now());
    state = state.copyWith(rawBudgets: updated);

    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        await SupabaseService.client!
            .from('budgets')
            .update(budget.toMap())
            .eq('id', budget.id);
      } catch (e) {
        debugPrint('Error updating budget in Supabase: $e');
      }
    }
    return true;
  }

  Future<bool> deleteBudget(String id) async {
    state = state.copyWith(
      rawBudgets: state.rawBudgets.where((b) => b.id != id).toList(),
    );

    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        await SupabaseService.client!.from('budgets').delete().eq('id', id);
      } catch (e) {
        debugPrint('Error deleting budget in Supabase: $e');
      }
    }
    return true;
  }

  List<BudgetModel> _generateDemoBudgets() {
    final now = DateTime.now();
    return [
      BudgetModel(
        id: 'b-1',
        userId: 'demo-user-1',
        category: 'Food & Dining',
        amount: 600.00,
        month: now.month,
        year: now.year,
        alertThreshold: 0.8,
        createdAt: now,
        updatedAt: now,
      ),
      BudgetModel(
        id: 'b-2',
        userId: 'demo-user-1',
        category: 'Shopping',
        amount: 400.00,
        month: now.month,
        year: now.year,
        alertThreshold: 0.8,
        createdAt: now,
        updatedAt: now,
      ),
      BudgetModel(
        id: 'b-3',
        userId: 'demo-user-1',
        category: 'Bills & Utilities',
        amount: 2200.00,
        month: now.month,
        year: now.year,
        alertThreshold: 0.85,
        createdAt: now,
        updatedAt: now,
      ),
      BudgetModel(
        id: 'b-4',
        userId: 'demo-user-1',
        category: 'Transportation',
        amount: 250.00,
        month: now.month,
        year: now.year,
        alertThreshold: 0.8,
        createdAt: now,
        updatedAt: now,
      ),
      BudgetModel(
        id: 'b-5',
        userId: 'demo-user-1',
        category: 'Entertainment',
        amount: 150.00,
        month: now.month,
        year: now.year,
        alertThreshold: 0.8,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}

final budgetRawProvider =
    StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  return BudgetNotifier();
});

/// Computes active budgets populated with real spent sums from transactions
final calculatedBudgetsProvider = Provider<List<BudgetModel>>((ref) {
  final rawState = ref.watch(budgetRawProvider);
  final txState = ref.watch(transactionProvider);

  return rawState.rawBudgets.map((budget) {
    final spent = txState.transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.category.toLowerCase() == budget.category.toLowerCase() &&
            t.date.month == budget.month &&
            t.date.year == budget.year)
        .fold(0.0, (sum, t) => sum + t.amount);

    return budget.copyWith(spentAmount: spent);
  }).toList();
});

final totalBudgetSummaryProvider = Provider<Map<String, double>>((ref) {
  final budgets = ref.watch(calculatedBudgetsProvider);
  final totalAllocated = budgets.fold(0.0, (sum, b) => sum + b.amount);
  final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
  final totalRemaining = (totalAllocated - totalSpent).clamp(0.0, double.infinity);

  return {
    'allocated': totalAllocated,
    'spent': totalSpent,
    'remaining': totalRemaining,
    'percentage': totalAllocated > 0 ? (totalSpent / totalAllocated) : 0.0,
  };
});
