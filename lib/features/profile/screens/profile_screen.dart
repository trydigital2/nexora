import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/receipt_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transaction_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider);
    final nameController = TextEditingController(text: auth.user?.fullName ?? '');
    final incomeController = TextEditingController(
      text: (auth.user?.monthlyIncome ?? 6500).toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Update Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Full Name',
                controller: nameController,
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Monthly Expected Income',
                controller: incomeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.attach_money_rounded),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final income = double.tryParse(incomeController.text.trim()) ?? 6500.0;
                ref.read(authProvider.notifier).updateProfile(
                      fullName: nameController.text.trim(),
                      monthlyIncome: income,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    final settings = ref.read(appSettingsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Preferred Currency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: AppConstants.currencies.length,
                  separatorBuilder: (context, index) => Divider(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final curr = AppConstants.currencies[index];
                    final isSel = curr['code'] == settings.currencyCode;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isSel
                            ? AppColors.secondary.withValues(alpha: 0.2)
                            : (isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt),
                        child: Text(
                          curr['symbol']!,
                          style: TextStyle(
                            color: isSel ? AppColors.secondary : (isDark ? Colors.white : AppColors.primary),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        curr['name']!,
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        curr['code']!,
                        style: TextStyle(
                          color: isSel ? AppColors.secondary : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () {
                        ref.read(appSettingsProvider.notifier).setCurrency(curr['code']!);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSupabaseConfigDialog(BuildContext context, WidgetRef ref) {
    final urlController = TextEditingController(text: SupabaseService.defaultUrl);
    final keyController = TextEditingController(text: SupabaseService.defaultAnonKey);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Supabase Backend Configuration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect NEXORA to your live Supabase project to synchronize transactions, storage, and secure Edge Functions.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Supabase URL',
                hint: 'https://xxx.supabase.co',
                controller: urlController,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Supabase Anon Key',
                hint: 'eyJhbGciOi...',
                controller: keyController,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await SupabaseService.setCredentials(
                  urlController.text.trim(),
                  keyController.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Supabase credentials saved')),
                  );
                }
              },
              child: const Text('Save & Connect'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final settings = ref.watch(appSettingsProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Profile & Preferences'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card Header
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                          backgroundImage: user?.avatarUrl != null
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null
                              ? Text(
                                  (user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'A').toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () async {
                              final path = await ReceiptService().pickProfileImage();
                              if (path != null) {
                                ref.read(authProvider.notifier).updateProfile(avatarUrl: path);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Alex Morgan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'alex.morgan@nexora.finance',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Verified Fintech Member',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showEditProfileDialog(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Financial Preferences Section
              Text(
                'Financial Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.secondary),
                      title: const Text('Primary Currency'),
                      subtitle: Text('${settings.currencyCode} (${settings.currencySymbol})'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showCurrencyPicker(context, ref),
                    ),
                    Divider(color: isDark ? AppColors.borderDark : AppColors.border, height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.accent),
                      title: const Text('Monthly Income Target'),
                      subtitle: Text(CurrencyFormatter.format(user?.monthlyIncome ?? 6500, symbol: settings.currencySymbol)),
                      trailing: const Icon(Icons.edit_outlined, size: 18),
                      onTap: () => _showEditProfileDialog(context, ref),
                    ),
                    Divider(color: isDark ? AppColors.borderDark : AppColors.border, height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.visibility_off_outlined, color: Color(0xFF38BDF8)),
                      title: const Text('Hide Balance on Launch'),
                      subtitle: const Text('Obscures account balances from casual glance'),
                      value: settings.hideBalance,
                      activeThumbColor: AppColors.secondary,
                      onChanged: (val) {
                        ref.read(appSettingsProvider.notifier).toggleHideBalance();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // App Settings & Security Section
              Text(
                'Application & Security',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.secondary),
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Sleek fintech night visual experience'),
                      value: settings.themeMode == ThemeMode.dark,
                      activeThumbColor: AppColors.secondary,
                      onChanged: (val) {
                        ref.read(appSettingsProvider.notifier).setThemeMode(
                              val ? ThemeMode.dark : ThemeMode.light,
                            );
                      },
                    ),
                    Divider(color: isDark ? AppColors.borderDark : AppColors.border, height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.warning),
                      title: const Text('Smart Alerts & Push'),
                      subtitle: const Text('Budget limits and bill reminder notifications'),
                      value: settings.notificationsEnabled,
                      activeThumbColor: AppColors.secondary,
                      onChanged: (val) {
                        ref.read(appSettingsProvider.notifier).setNotificationsEnabled(val);
                      },
                    ),
                    Divider(color: isDark ? AppColors.borderDark : AppColors.border, height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.accent),
                      title: const Text('Biometric Authentication'),
                      subtitle: const Text('Require FaceID / TouchID on app resume'),
                      value: settings.biometricEnabled,
                      activeThumbColor: AppColors.secondary,
                      onChanged: (val) {
                        ref.read(appSettingsProvider.notifier).setBiometricsEnabled(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Cloud & Developer Settings
              Text(
                'Cloud & Data Management',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.secondary),
                      title: const Text('Supabase Connection'),
                      subtitle: Text(
                        SupabaseService.isDemoMode
                            ? 'Running in Demo & Local Persistence Mode'
                            : 'Connected to Supabase PostgreSQL',
                      ),
                      trailing: const Icon(Icons.settings_outlined, size: 20),
                      onTap: () => _showSupabaseConfigDialog(context, ref),
                    ),
                    Divider(color: isDark ? AppColors.borderDark : AppColors.border, height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.dataset_outlined, color: AppColors.accent),
                      title: const Text('Reload Seed Sample Data'),
                      subtitle: const Text('Restores realistic transactions, budgets, and bills'),
                      trailing: const Icon(Icons.refresh_rounded, size: 20),
                      onTap: () {
                        ref.read(transactionProvider.notifier).loadTransactions();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Financial ledger reloaded with sample fintech data')),
                        );
                      },
                    ),
                    Divider(color: isDark ? AppColors.borderDark : AppColors.border, height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.file_download_outlined, color: Color(0xFF38BDF8)),
                      title: const Text('Export Statement Report'),
                      subtitle: const Text('Generate formatted PDF ledger statement'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/analytics'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Sign Out Button
              AppButton(
                text: 'Sign Out',
                width: double.infinity,
                variant: AppButtonVariant.outline,
                textColor: AppColors.expense,
                icon: Icons.logout_rounded,
                onPressed: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/auth/login');
                  }
                },
              ),
              const SizedBox(height: 16),

              Center(
                child: Text(
                  '${AppConstants.appName} v${AppConstants.appVersion} • ${AppConstants.appTagline}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
