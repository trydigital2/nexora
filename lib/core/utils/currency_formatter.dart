import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(
    double amount, {
    String currencyCode = 'USD',
    String? symbol,
    bool hideBalance = false,
    bool showSign = false,
  }) {
    if (hideBalance) {
      return '••••••••';
    }

    final currencySymbol = symbol ?? _getSymbol(currencyCode);
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    final formatted = formatter.format(amount.abs());
    if (showSign) {
      if (amount > 0) return '+$formatted';
      if (amount < 0) return '-$formatted';
    }
    return amount < 0 ? '-$formatted' : formatted;
  }

  static String formatCompact(
    double amount, {
    String currencyCode = 'USD',
    String? symbol,
    bool hideBalance = false,
  }) {
    if (hideBalance) {
      return '••••';
    }
    final currencySymbol = symbol ?? _getSymbol(currencyCode);
    final compactFormatter = NumberFormat.compactCurrency(
      locale: 'en_US',
      symbol: currencySymbol,
      decimalDigits: 1,
    );
    return compactFormatter.format(amount);
  }

  static String _getSymbol(String code) {
    switch (code.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'CA\$';
      case 'AUD':
        return 'AU\$';
      case 'SGD':
        return 'SG\$';
      case 'USD':
      default:
        return '\$';
    }
  }
}

