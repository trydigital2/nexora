import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/receipt_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  final String? initialType;

  const TransactionFormScreen({
    super.key,
    this.transactionId,
    this.initialType,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _selectedType;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late String _selectedPaymentMethod;
  String? _receiptPath;
  bool _isRecurring = false;
  bool _isSaving = false;
  TransactionModel? _existingTx;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType != null
        ? TransactionType.fromString(widget.initialType!)
        : TransactionType.expense;

    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _selectedCategory = 'Food & Dining';
    _selectedDate = DateTime.now();
    _selectedPaymentMethod = 'Debit Card';

    // If editing existing transaction
    if (widget.transactionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final txState = ref.read(transactionProvider);
        final found = txState.transactions.firstWhere(
          (t) => t.id == widget.transactionId,
          orElse: () => txState.transactions.first,
        );
        setState(() {
          _existingTx = found;
          _selectedType = found.type;
          _titleController.text = found.title;
          _amountController.text = found.amount.toStringAsFixed(2);
          _notesController.text = found.notes ?? '';
          _selectedCategory = found.category;
          _selectedDate = found.date;
          _selectedPaymentMethod = found.paymentMethod;
          _receiptPath = found.receiptUrl;
          _isRecurring = found.isRecurring;
        });
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt(ImageSource source) async {
    final path = await ReceiptService().pickReceiptImage(source: source);
    if (path != null) {
      setState(() {
        _receiptPath = path;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0.0;
    setState(() => _isSaving = true);

    bool success;
    if (_existingTx != null) {
      final updated = _existingTx!.copyWith(
        title: _titleController.text.trim(),
        amount: amount,
        type: _selectedType,
        category: _selectedCategory,
        notes: _notesController.text.trim(),
        date: _selectedDate,
        paymentMethod: _selectedPaymentMethod,
        receiptUrl: _receiptPath,
        isRecurring: _isRecurring,
      );
      success = await ref.read(transactionProvider.notifier).updateTransaction(updated);
    } else {
      success = await ref.read(transactionProvider.notifier).addTransaction(
            title: _titleController.text.trim(),
            amount: amount,
            type: _selectedType,
            category: _selectedCategory,
            notes: _notesController.text.trim(),
            date: _selectedDate,
            paymentMethod: _selectedPaymentMethod,
            receiptUrl: _receiptPath,
            isRecurring: _isRecurring,
          );
    }

    setState(() => _isSaving = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_existingTx != null ? 'Transaction updated' : 'Transaction recorded'),
          backgroundColor: AppColors.accent,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(appSettingsProvider);
    final isEditing = widget.transactionId != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Record Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Transaction Type Toggle (Expense, Income, Transfer)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _typeTab(TransactionType.expense, 'Expense', AppColors.expense),
                      _typeTab(TransactionType.income, 'Income', AppColors.income),
                      _typeTab(TransactionType.transfer, 'Transfer', AppColors.secondary),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Amount Input
                Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.validateAmount,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _selectedType == TransactionType.income
                        ? AppColors.income
                        : (_selectedType == TransactionType.expense
                            ? AppColors.expense
                            : AppColors.secondary),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        settings.currencySymbol,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Title / Merchant
                AppTextField(
                  label: 'Description / Payee',
                  hint: 'e.g. Starbucks, Salary, Apple Store',
                  controller: _titleController,
                  prefixIcon: const Icon(Icons.title_rounded, size: 20),
                  validator: (v) => Validators.validateRequired(v, 'Description'),
                ),
                const SizedBox(height: 20),

                // 4. Category Selector
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.categories.map((c) {
                    final isSel = _selectedCategory.toLowerCase() == c.name.toLowerCase() ||
                        _selectedCategory.toLowerCase() == c.id.toLowerCase();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = c.name;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? c.color
                              : (isDark ? AppColors.darkSurfaceAlt : AppColors.surface),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel
                                ? c.color
                                : (isDark ? AppColors.borderDark : AppColors.border),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              c.icon,
                              size: 16,
                              color: isSel ? Colors.white : c.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 5. Date and Payment Method Row
                Row(
                  children: [
                    // Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceAlt : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? AppColors.borderDark : AppColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      DateFormatter.formatShort(_selectedDate),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Payment Method
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceAlt : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.border,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPaymentMethod,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded),
                                items: AppConstants.paymentMethods.map((m) {
                                  return DropdownMenuItem(
                                    value: m,
                                    child: Text(m, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedPaymentMethod = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 6. Notes
                AppTextField(
                  label: 'Notes (Optional)',
                  hint: 'Add context, invoice number, tags...',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // 7. Receipt Attachment
                Text(
                  'Receipt Attachment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                if (_receiptPath != null)
                  Stack(
                    children: [
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                          image: _receiptPath!.startsWith('http')
                              ? DecorationImage(
                                  image: NetworkImage(_receiptPath!),
                                  fit: BoxFit.cover,
                                )
                              : DecorationImage(
                                  image: FileImage(File(_receiptPath!)),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _receiptPath = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickReceipt(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickReceipt(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),

                // 8. Save Button
                AppButton(
                  text: isEditing ? 'Save Changes' : 'Confirm Transaction',
                  width: double.infinity,
                  isLoading: _isSaving,
                  onPressed: _saveTransaction,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeTab(TransactionType type, String label, Color activeColor) {
    final isSel = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: isSel ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

