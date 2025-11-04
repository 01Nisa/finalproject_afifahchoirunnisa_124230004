import 'package:intl/intl.dart';
import 'constants.dart';

class ConversionHelper {
  static double convertCurrency(
    double amountUSD,
    String targetCurrency,
  ) {
    if (targetCurrency == 'USD') return amountUSD;

    final rate = CurrencyConstants.exchangeRates[targetCurrency];
    if (rate == null) return amountUSD;

    return amountUSD * rate;
  }

  static String formatCurrency(
    double amount,
    String currency, {
    bool showSymbol = true,
    int decimalPlaces = 0,
  }) {
    final symbol = CurrencyConstants.currencySymbols[currency] ?? '\$';

    String formattedAmount;

    if (currency == 'IDR' || currency == 'JPY') {
      formattedAmount = NumberFormat.currency(
        symbol: showSymbol ? symbol : '',
        decimalDigits: 0,
        locale: _getCurrencyLocale(currency),
      ).format(amount);
    } else {
      formattedAmount = NumberFormat.currency(
        symbol: showSymbol ? symbol : '',
        decimalDigits: decimalPlaces,
        locale: _getCurrencyLocale(currency),
      ).format(amount);
    }

    return formattedAmount;
  }

  static String formatConvertedCurrency(
    double amountUSD,
    String targetCurrency, {
    bool showSymbol = true,
    int decimalPlaces = 0,
  }) {
    final converted = convertCurrency(amountUSD, targetCurrency);
    return formatCurrency(
      converted,
      targetCurrency,
      showSymbol: showSymbol,
      decimalPlaces: decimalPlaces,
    );
  }

  static String _getCurrencyLocale(String currency) {
    switch (currency) {
      case 'USD':
        return 'en_US';
      case 'EUR':
        return 'de_DE';
      case 'GBP':
        return 'en_GB';
      case 'JPY':
        return 'ja_JP';
      case 'IDR':
        return 'id_ID';
      case 'CNY':
        return 'zh_CN';
      case 'AUD':
        return 'en_AU';
      default:
        return 'en_US';
    }
  }

  static String formatCompactCurrency(
    double amountUSD,
    String targetCurrency,
  ) {
    final converted = convertCurrency(amountUSD, targetCurrency);
    final symbol = CurrencyConstants.currencySymbols[targetCurrency] ?? '\$';

    if (converted >= 1000000) {
      return '$symbol${(converted / 1000000).toStringAsFixed(1)}M';
    } else if (converted >= 1000) {
      return '$symbol${(converted / 1000).toStringAsFixed(0)}K';
    } else {
      return formatCurrency(converted, targetCurrency, decimalPlaces: 0);
    }
  }

  static DateTime convertTimezone(
    DateTime dateTime,
    String targetTimezone,
  ) {
    final offset = TimezoneConstants.timezoneOffsets[targetTimezone];
    if (offset == null) return dateTime;

    final utcTime = dateTime.toUtc();

    return utcTime.add(Duration(hours: offset));
  }

  static String formatDateTime(
    DateTime dateTime,
    String timezone, {
    bool showTime = true,
    bool showTimezone = true,
  }) {
    final converted = convertTimezone(dateTime, timezone);

    String pattern;
    if (showTime) {
      pattern = 'dd MMM yyyy, HH:mm';
    } else {
      pattern = 'dd MMM yyyy';
    }

    final formatted = DateFormat(pattern).format(converted);

    if (showTimezone) {
      return '$formatted $timezone';
    } else {
      return formatted;
    }
  }

  static String formatDateTimeIndonesian(
    DateTime dateTime,
    String timezone, {
    bool showTime = true,
  }) {
    final converted = convertTimezone(dateTime, timezone);

    final monthsIndo = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    final day = converted.day;
    final month = monthsIndo[converted.month];
    final year = converted.year;

    if (showTime) {
      final hour = converted.hour.toString().padLeft(2, '0');
      final minute = converted.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute $timezone';
    } else {
      return '$day $month $year';
    }
  }

  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      final absDiff = difference.abs();
      if (absDiff.inDays > 0) {
        return '${absDiff.inDays} hari yang lalu';
      } else if (absDiff.inHours > 0) {
        return '${absDiff.inHours} jam yang lalu';
      } else if (absDiff.inMinutes > 0) {
        return '${absDiff.inMinutes} menit yang lalu';
      } else {
        return 'Baru saja';
      }
    } else {
      if (difference.inDays > 0) {
        return 'dalam ${difference.inDays} hari';
      } else if (difference.inHours > 0) {
        return 'dalam ${difference.inHours} jam';
      } else if (difference.inMinutes > 0) {
        return 'dalam ${difference.inMinutes} menit';
      } else {
        return 'Sebentar lagi';
      }
    }
  }

  static String formatCountdown(Duration duration) {
    if (duration.isNegative) return 'Selesai';

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (days > 0) {
      return '${days}h ${hours}j ${minutes}m';
    } else if (hours > 0) {
      return '${hours}j ${minutes}m ${seconds}d';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}d';
    } else {
      return '${seconds}d';
    }
  }

  static String getTimezoneDisplayName(String timezone) {
    final offset = TimezoneConstants.timezoneOffsets[timezone];
    if (offset == null) return timezone;

    final sign = offset >= 0 ? '+' : '';
    return '$timezone (UTC$sign$offset)';
  }

  static bool isValidCurrency(String currency) {
    return CurrencyConstants.availableCurrencies.contains(currency);
  }

  static bool isValidTimezone(String timezone) {
    return TimezoneConstants.availableTimezones.contains(timezone);
  }
}
