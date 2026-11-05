import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/supabase_service.dart';
import '../models/ai_insight.dart';
import '../models/chat_message.dart';
import '../../auth/providers/auth_provider.dart';
import '../../budgets/providers/budget_provider.dart';
import '../../savings/providers/savings_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../../shared/providers/app_settings_provider.dart';

class AiState {
  final List<ChatMessage> messages;
  final bool isThinking;
  final List<AiInsightModel> insights;
  final String? errorMessage;

  const AiState({
    this.messages = const [],
    this.isThinking = false,
    this.insights = const [],
    this.errorMessage,
  });

  AiState copyWith({
    List<ChatMessage>? messages,
    bool? isThinking,
    List<AiInsightModel>? insights,
    String? errorMessage,
  }) {
    return AiState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      insights: insights ?? this.insights,
      errorMessage: errorMessage,
    );
  }
}

class AiNotifier extends StateNotifier<AiState> {
  final Ref _ref;

  AiNotifier(this._ref) : super(const AiState()) {
    _initChat();
    refreshInsights();
  }

  final _uuid = const Uuid();

  void _initChat() {
    state = state.copyWith(
      messages: [
        ChatMessage(
          id: 'welcome-msg',
          sender: MessageSender.assistant,
          text:
              'Hello! I am **NEXORA AI**, your personal financial intelligence partner.\n\nI analyze your live spending, budget limits, and savings goals to give you contextual advice. How can I assist you with your money today?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          disclaimer: AiService.disclaimerText,
        ),
      ],
    );
  }

  void refreshInsights() {
    final auth = _ref.read(authProvider);
    final txState = _ref.read(transactionProvider);
    final budgets = _ref.read(calculatedBudgetsProvider);
    final settings = _ref.read(appSettingsProvider);

    final generated = AiService.generateInsights(
      userId: auth.user?.id ?? 'demo-user-1',
      monthlyIncome: auth.user?.monthlyIncome ?? 6500.0,
      monthlyExpenses: txState.currentMonthExpenses,
      transactions: txState.transactions,
      budgets: budgets,
      currencySymbol: settings.currencySymbol,
    );

    state = state.copyWith(insights: generated);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      sender: MessageSender.user,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    // Append user message and set thinking indicator
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isThinking: true,
      errorMessage: null,
    );

    try {
      final auth = _ref.read(authProvider);
      final txState = _ref.read(transactionProvider);
      final budgets = _ref.read(calculatedBudgetsProvider);
      final savings = _ref.read(savingsProvider);
      final settings = _ref.read(appSettingsProvider);

      final result = await AiService.askAssistant(
        question: text,
        monthlyIncome: auth.user?.monthlyIncome ?? 6500.0,
        monthlyExpenses: txState.currentMonthExpenses,
        transactions: txState.transactions,
        budgets: budgets,
        savingsGoals: savings.goals,
        currencySymbol: settings.currencySymbol,
      );

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        sender: MessageSender.assistant,
        text: result['reply'] ?? 'Analysis complete.',
        timestamp: DateTime.now(),
        disclaimer: result['disclaimer'] ?? AiService.disclaimerText,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isThinking: false,
      );

      // Save to Supabase chat_history if connected
      if (!SupabaseService.isDemoMode && SupabaseService.client != null) {
        try {
          final user = SupabaseService.client!.auth.currentUser;
          if (user != null) {
            await SupabaseService.client!.from('chat_history').insert([
              userMsg.toMap()..['user_id'] = user.id,
              aiMsg.toMap()..['user_id'] = user.id,
            ]);
          }
        } catch (e) {
          debugPrint('Error saving chat to Supabase: $e');
        }
      }
    } catch (e) {
      state = state.copyWith(
        isThinking: false,
        errorMessage: 'Could not process query: $e',
      );
    }
  }

  void clearChat() {
    _initChat();
  }
}

final aiProvider = StateNotifierProvider<AiNotifier, AiState>((ref) {
  return AiNotifier(ref);
});

