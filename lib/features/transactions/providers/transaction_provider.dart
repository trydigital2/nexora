import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/supabase_service.dart';
import '../models/transaction.dart';

class TransactionFilterState {
  final String searchQuery;
  final TransactionType? selectedType;
  final String? selectedCategory;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilterState({
    this.searchQuery = '',
    this.selectedType,
    this.selectedCategory,
    this.startDate,
    this.endDate,
  });

  TransactionFilterState copyWith({
    String? searchQuery,
    TransactionType? selectedType,
    String? selectedCategory,
    DateTime? startDate,
    DateTime? endDate,
    bool clearType = false,
    bool clearCategory = false,
    bool clearDates = false,
  }) {
    return TransactionFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }
}

class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? errorMessage;
  final TransactionFilterState filter;

  const TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filter = const TransactionFilterState(),
  });

  List<TransactionModel> get filteredTransactions {
    return transactions.where((t) {
      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        final matchTitle = t.title.toLowerCase().contains(q);
        final matchNotes = t.notes?.toLowerCase().contains(q) ?? false;
        final matchCategory = t.category.toLowerCase().contains(q);
        if (!matchTitle && !matchNotes && !matchCategory) return false;
      }

      if (filter.selectedType != null && t.type != filter.selectedType) {
        return false;
      }

      if (filter.selectedCategory != null &&
          filter.selectedCategory != 'All' &&
          t.category.toLowerCase() != filter.selectedCategory!.toLowerCase()) {
        return false;
      }

      if (filter.startDate != null) {
        if (t.date.isBefore(filter.startDate!)) return false;
      }

      if (filter.endDate != null) {
        final endOfDay = DateTime(
          filter.endDate!.year,
          filter.endDate!.month,
          filter.endDate!.day,
          23,
          59,
          59,
        );
        if (t.date.isAfter(endOfDay)) return false;
      }

      return true;
    }).toList();
  }

  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalBalance => totalIncome - totalExpenses;

  // Monthly metrics for current month
  double get currentMonthIncome {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get currentMonthExpenses {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> get categoryBreakdown {
    final now = DateTime.now();
    final map = <String, double>{};
    for (final t in transactions.where((t) =>
        t.type == TransactionType.expense &&
        t.date.month == now.month &&
        t.date.year == now.year)) {
      map[t.category] = (map[t.category] ?? 0.0) + t.amount;
    }
    return map;
  }

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? errorMessage,
    TransactionFilterState? filter,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filter: filter ?? this.filter,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  TransactionNotifier() : super(const TransactionState()) {
    loadTransactions();
  }

  final _uuid = const Uuid();

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
        final client = SupabaseService.client!;
        final user = client.auth.currentUser;
        if (user != null) {
          final data = await client
              .from('transactions')
              .select()
              .eq('user_id', user.id)
              .order('date', ascending: false);

          final list = (data as List).map((m) => TransactionModel.fromMap(m)).toList();
          state = state.copyWith(transactions: list, isLoading: false);
          return;
        }
      }

      // Load rich seed demo data
      state = state.copyWith(
        transactions: _generateDemoTransactions(),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      state = state.copyWith(
        transactions: _generateDemoTransactions(),
        isLoading: false,
      );
    }
  }

  Future<bool> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String category,
    String? notes,
    required DateTime date,
    String paymentMethod = 'Debit Card',
    String? receiptUrl,
    bool isRecurring = false,
  }) async {
    final newId = _uuid.v4();
    final newTx = TransactionModel(
      id: newId,
      userId: 'user-active',
      title: title.trim(),
      amount: amount,
      type: type,
      category: category,
      notes: notes?.trim(),
      date: date,
      paymentMethod: paymentMethod,
      receiptUrl: receiptUrl,
      isRecurring: isRecurring,
      createdAt: DateTime.now(),
    );

    // Update local state immediately for instant optimistic UX
    final updatedList = [newTx, ...state.transactions];
    updatedList.sort((a, b) => b.date.compareTo(a.date));
    state = state.copyWith(transactions: updatedList);

    // Sync to Supabase if connected
    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        final user = SupabaseService.client!.auth.currentUser;
        if (user != null) {
          await SupabaseService.client!.from('transactions').insert(
                newTx.copyWith(userId: user.id).toMap(),
              );
        }
      } catch (e) {
        debugPrint('Error inserting transaction in Supabase: $e');
      }
    }
    return true;
  }

  Future<bool> updateTransaction(TransactionModel tx) async {
    final index = state.transactions.indexWhere((t) => t.id == tx.id);
    if (index == -1) return false;

    final updatedList = List<TransactionModel>.from(state.transactions);
    updatedList[index] = tx;
    updatedList.sort((a, b) => b.date.compareTo(a.date));
    state = state.copyWith(transactions: updatedList);

    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        await SupabaseService.client!
            .from('transactions')
            .update(tx.toMap())
            .eq('id', tx.id);
      } catch (e) {
        debugPrint('Error updating transaction in Supabase: $e');
      }
    }
    return true;
  }

  Future<bool> deleteTransaction(String id) async {
    final updatedList = state.transactions.where((t) => t.id != id).toList();
    state = state.copyWith(transactions: updatedList);

    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        await SupabaseService.client!.from('transactions').delete().eq('id', id);
      } catch (e) {
        debugPrint('Error deleting transaction in Supabase: $e');
      }
    }
    return true;
  }

  void updateFilter(TransactionFilterState filter) {
    state = state.copyWith(filter: filter);
  }

  void resetFilter() {
    state = state.copyWith(filter: const TransactionFilterState());
  }

  List<TransactionModel> _generateDemoTransactions() {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: 'tx-1',
        userId: 'demo-user-1',
        title: 'Monthly Tech Salary',
        amount: 6500.00,
        type: TransactionType.income,
        category: 'Salary',
        notes: 'Monthly direct deposit from Acme Corp',
        date: DateTime(now.year, now.month, 1),
        paymentMethod: 'Bank Transfer',
        createdAt: DateTime(now.year, now.month, 1),
      ),
      TransactionModel(
        id: 'tx-2',
        userId: 'demo-user-1',
        title: 'Luxury Apartment Rent',
        amount: 1850.00,
        type: TransactionType.expense,
        category: 'Bills & Utilities',
        notes: 'Downtown loft rent',
        date: DateTime(now.year, now.month, 2),
        paymentMethod: 'Bank Transfer',
        createdAt: DateTime(now.year, now.month, 2),
      ),
      TransactionModel(
        id: 'tx-3',
        userId: 'demo-user-1',
        title: 'Whole Foods Market',
        amount: 142.80,
        type: TransactionType.expense,
        category: 'Food & Dining',
        notes: 'Weekly organic groceries & produce',
        date: DateTime(now.year, now.month, 3, 14, 20),
        paymentMethod: 'Debit Card',
        createdAt: DateTime(now.year, now.month, 3),
      ),
      TransactionModel(
        id: 'tx-4',
        userId: 'demo-user-1',
        title: 'Dividend Payout - VOO',
        amount: 320.50,
        type: TransactionType.income,
        category: 'Investments',
        notes: 'Quarterly index fund dividend',
        date: DateTime(now.year, now.month, 4),
        paymentMethod: 'Bank Transfer',
        createdAt: DateTime(now.year, now.month, 4),
      ),
      TransactionModel(
        id: 'tx-5',
        userId: 'demo-user-1',
        title: 'Nordstrom Designer Apparel',
        amount: 289.00,
        type: TransactionType.expense,
        category: 'Shopping',
        notes: 'Winter jacket and boots',
        date: DateTime(now.year, now.month, 4, 18, 45),
        paymentMethod: 'Credit Card',
        createdAt: DateTime(now.year, now.month, 4),
      ),
      TransactionModel(
        id: 'tx-6',
        userId: 'demo-user-1',
        title: 'Uber Premier',
        amount: 38.50,
        type: TransactionType.expense,
        category: 'Transportation',
        notes: 'Ride to airport conference',
        date: DateTime(now.year, now.month, 5, 9, 10),
        paymentMethod: 'Credit Card',
        createdAt: DateTime(now.year, now.month, 5),
      ),
      TransactionModel(
        id: 'tx-7',
        userId: 'demo-user-1',
        title: 'Blue Bottle Coffee Roastery',
        amount: 18.25,
        type: TransactionType.expense,
        category: 'Food & Dining',
        notes: 'Morning pour-over and croissant',
        date: DateTime(now.year, now.month, 5, 8, 30),
        paymentMethod: 'Debit Card',
        createdAt: DateTime(now.year, now.month, 5),
      ),
      TransactionModel(
        id: 'tx-8',
        userId: 'demo-user-1',
        title: 'Netflix Premium 4K',
        amount: 22.99,
        type: TransactionType.expense,
        category: 'Entertainment',
        notes: 'Monthly streaming subscription',
        date: DateTime(now.year, now.month, 1),
        paymentMethod: 'Credit Card',
        createdAt: DateTime(now.year, now.month, 1),
      ),
      TransactionModel(
        id: 'tx-9',
        userId: 'demo-user-1',
        title: 'Equinox Gym Membership',
        amount: 195.00,
        type: TransactionType.expense,
        category: 'Healthcare',
        notes: 'Monthly fitness center fee',
        date: DateTime(now.year, now.month, 2),
        paymentMethod: 'Debit Card',
        createdAt: DateTime(now.year, now.month, 2),
      ),
      TransactionModel(
        id: 'tx-10',
        userId: 'demo-user-1',
        title: 'Consulting Project Bonus',
        amount: 850.00,
        type: TransactionType.income,
        category: 'Salary',
        notes: 'UI Architecture consultation payment',
        date: DateTime(now.year, now.month, 3),
        paymentMethod: 'Bank Transfer',
        createdAt: DateTime(now.year, now.month, 3),
      ),
    ];
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier();
});

