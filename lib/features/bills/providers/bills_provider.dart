import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
import '../models/recurring_bill.dart';

class BillsState {
  final List<RecurringBillModel> bills;
  final bool isLoading;
  final String? errorMessage;

  const BillsState({
    this.bills = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  List<RecurringBillModel> get unpaidBills => bills.where((b) => !b.isPaid).toList();
  List<RecurringBillModel> get paidBills => bills.where((b) => b.isPaid).toList();

  double get totalUnpaidAmount =>
      unpaidBills.fold(0.0, (sum, b) => sum + b.amount);

  BillsState copyWith({
    List<RecurringBillModel>? bills,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BillsState(
      bills: bills ?? this.bills,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BillsNotifier extends StateNotifier<BillsState> {
  BillsNotifier() : super(const BillsState()) {
    loadBills();
  }

  final _uuid = const Uuid();

  Future<void> loadBills() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
        final client = SupabaseService.client!;
        final user = client.auth.currentUser;
        if (user != null) {
          final data = await client
              .from('recurring_bills')
              .select()
              .eq('user_id', user.id)
              .order('due_date', ascending: true);

          final list = (data as List).map((m) => RecurringBillModel.fromMap(m)).toList();
          state = state.copyWith(bills: list, isLoading: false);
          return;
        }
      }

      state = state.copyWith(
        bills: _generateDemoBills(),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading bills: $e');
      state = state.copyWith(
        bills: _generateDemoBills(),
        isLoading: false,
      );
    }
  }

  Future<bool> addBill({
    required String title,
    required double amount,
    required String category,
    required DateTime dueDate,
    String frequency = 'Monthly',
    int reminderDaysBefore = 2,
    String? notes,
  }) async {
    final now = DateTime.now();
    final newBill = RecurringBillModel(
      id: _uuid.v4(),
      userId: 'user-active',
      title: title.trim(),
      amount: amount,
      category: category,
      dueDate: dueDate,
      frequency: frequency,
      reminderDaysBefore: reminderDaysBefore,
      notes: notes?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final updated = [...state.bills, newBill];
    updated.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    state = state.copyWith(bills: updated);

    // Schedule notification
    NotificationService().showBillReminder(
      billTitle: newBill.title,
      amount: newBill.amount,
      dueDateFormatted: '${dueDate.month}/${dueDate.day}',
      currencySymbol: '\$',
    );

    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        final user = SupabaseService.client!.auth.currentUser;
        if (user != null) {
          await SupabaseService.client!.from('recurring_bills').insert(
                newBill.copyWith(userId: user.id).toMap(),
              );
        }
      } catch (e) {
        debugPrint('Error inserting recurring bill in Supabase: $e');
      }
    }
    return true;
  }

  Future<bool> togglePaidStatus(String id) async {
    final index = state.bills.indexWhere((b) => b.id == id);
    if (index == -1) return false;

    final bill = state.bills[index];
    final updated = bill.copyWith(
      isPaid: !bill.isPaid,
      updatedAt: DateTime.now(),
    );

    final list = List<RecurringBillModel>.from(state.bills);
    list[index] = updated;
    state = state.copyWith(bills: list);

    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        await SupabaseService.client!.from('recurring_bills').update({
          'is_paid': updated.isPaid,
          'updated_at': updated.updatedAt.toIso8601String(),
        }).eq('id', id);
      } catch (e) {
        debugPrint('Error toggling bill paid in Supabase: $e');
      }
    }
    return true;
  }

  Future<bool> deleteBill(String id) async {
    state = state.copyWith(
      bills: state.bills.where((b) => b.id != id).toList(),
    );

    if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
      try {
        await SupabaseService.client!.from('recurring_bills').delete().eq('id', id);
      } catch (e) {
        debugPrint('Error deleting recurring bill in Supabase: $e');
      }
    }
    return true;
  }

  List<RecurringBillModel> _generateDemoBills() {
    final now = DateTime.now();
    return [
      RecurringBillModel(
        id: 'bill-1',
        userId: 'demo-user-1',
        title: 'High-Speed Fiber Internet',
        amount: 85.00,
        category: 'Bills & Utilities',
        dueDate: DateTime(now.year, now.month, 12),
        frequency: 'Monthly',
        isPaid: false,
        reminderDaysBefore: 3,
        notes: 'Gigabit fiber connection',
        createdAt: now,
        updatedAt: now,
      ),
      RecurringBillModel(
        id: 'bill-2',
        userId: 'demo-user-1',
        title: 'Electricity & Green Power',
        amount: 145.20,
        category: 'Bills & Utilities',
        dueDate: DateTime(now.year, now.month, 18),
        frequency: 'Monthly',
        isPaid: false,
        reminderDaysBefore: 2,
        notes: 'City power utility statement',
        createdAt: now,
        updatedAt: now,
      ),
      RecurringBillModel(
        id: 'bill-3',
        userId: 'demo-user-1',
        title: 'Apartment Rent',
        amount: 1850.00,
        category: 'Bills & Utilities',
        dueDate: DateTime(now.year, now.month, 2),
        frequency: 'Monthly',
        isPaid: true,
        reminderDaysBefore: 5,
        notes: 'Paid on the 1st of month',
        createdAt: now,
        updatedAt: now,
      ),
      RecurringBillModel(
        id: 'bill-4',
        userId: 'demo-user-1',
        title: 'Spotify & Cloud Backups',
        amount: 24.98,
        category: 'Entertainment',
        dueDate: DateTime(now.year, now.month, 24),
        frequency: 'Monthly',
        isPaid: false,
        reminderDaysBefore: 1,
        notes: 'Family audio stream and 2TB cloud storage',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}

final billsProvider = StateNotifierProvider<BillsNotifier, BillsState>((ref) {
  return BillsNotifier();
});

