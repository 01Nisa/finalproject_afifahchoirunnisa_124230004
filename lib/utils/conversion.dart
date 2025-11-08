import 'package:intl/intl.dart';
import 'constants.dart';

class ConversionHelper {
  /// Convert [amount] from [fromCurrency] (defaults to app default) to [targetCurrency].
  ///
  /// Exchange rates are stored in [CurrencyConstants.exchangeRates] as the
  /// number of units of that currency per 1 USD (e.g. IDR: 15750 means
  /// 1 USD = 15750 IDR). The conversion formula is:
  /// amount_in_usd = amount / rate[from]
  /// amount_in_target = amount_in_usd * rate[target]
  static double convertCurrency(
    double amount,
    String targetCurrency, {
    String fromCurrency = AppConstants.defaultCurrency,
  }) {
    if (fromCurrency == targetCurrency) return amount;

    final rateFrom = CurrencyConstants.exchangeRates[fromCurrency] ?? 1.0;
    final rateTo = CurrencyConstants.exchangeRates[targetCurrency] ?? 1.0;

    // Convert from source currency to USD, then to target currency
    final amountUsd = amount / rateFrom;
    return amountUsd * rateTo;
  }

  static String formatCurrency(
    double amount,
    String? currency, {
    bool showSymbol = true,
    int decimalPlaces = 0,
  }) {
    final cur = _normalizeCurrency(currency);
    final symbol = CurrencyConstants.currencySymbols[cur] ?? '\$';

    String formattedAmount;

    if (cur == 'IDR' || cur == 'JPY') {
      formattedAmount = NumberFormat.currency(
        symbol: showSymbol ? symbol : '',
        decimalDigits: 0,
        locale: _getCurrencyLocale(cur),
      ).format(amount);
    } else {
      formattedAmount = NumberFormat.currency(
        symbol: showSymbol ? symbol : '',
        decimalDigits: decimalPlaces,
        locale: _getCurrencyLocale(cur),
      ).format(amount);
    }

    return formattedAmount;
  }

  static String formatConvertedCurrency(
    double amount,
    String? targetCurrency, {
    bool showSymbol = true,
    int decimalPlaces = 0,
  }) {
    final tgt = _normalizeCurrency(targetCurrency);
    final converted = convertCurrency(amount, tgt);
    return formatCurrency(
      converted,
      tgt,
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

    static String _normalizeCurrency(String? currency) {
      if (currency == null) return AppConstants.defaultCurrency;
      final t = currency.trim();
      return t.isEmpty ? AppConstants.defaultCurrency : t;
    }

    static String _normalizeTimezone(String? timezone) {
      if (timezone == null) return AppConstants.defaultTimezone;
      final t = timezone.trim();
      return t.isEmpty ? AppConstants.defaultTimezone : t;
    }

  static String formatCompactCurrency(
    double amount,
    String? targetCurrency,
  ) {
    final tgt = _normalizeCurrency(targetCurrency);
    final converted = convertCurrency(amount, tgt);
    final symbol = CurrencyConstants.currencySymbols[tgt] ?? '\$';

    if (converted >= 1000000) {
      return '$symbol${(converted / 1000000).toStringAsFixed(1)}M';
    } else if (converted >= 1000) {
      return '$symbol${(converted / 1000).toStringAsFixed(0)}K';
    } else {
      return formatCurrency(converted, tgt, decimalPlaces: 0);
    }
  }

  /// Convert [dateTime] which is assumed to be in the app default timezone
  /// (see [AppConstants.defaultTimezone]) into [targetTimezone]. This computes
  /// the UTC instant from the source offset then applies the target offset.
  static DateTime convertTimezone(
    DateTime dateTime,
    String targetTimezone,
  ) {
    final sourceTz = AppConstants.defaultTimezone;
    final srcOffset = TimezoneConstants.timezoneOffsets[sourceTz];
    final tgt = _normalizeTimezone(targetTimezone);
    final tgtOffset = TimezoneConstants.timezoneOffsets[tgt];
    if (srcOffset == null || tgtOffset == null) return dateTime;

    // Interpret the provided dateTime as local in source timezone, convert
    // to UTC, then apply target offset.
    final utc = dateTime.subtract(Duration(hours: srcOffset));
    return utc.add(Duration(hours: tgtOffset));
  }

  static String formatDateTime(
    DateTime dateTime,
    String? timezone, {
    bool showTime = true,
    bool showTimezone = true,
  }) {
    final tz = _normalizeTimezone(timezone);
    final converted = convertTimezone(dateTime, tz);

    String pattern;
    if (showTime) {
      pattern = 'dd MMM yyyy, HH:mm';
    } else {
      pattern = 'dd MMM yyyy';
    }

    final formatted = DateFormat(pattern).format(converted);

    if (showTimezone) {
      return '$formatted $tz';
    } else {
      return formatted;
    }
  }

  static String formatDateTimeIndonesian(
    DateTime dateTime,
    String? timezone, {
    bool showTime = true,
  }) {
    final tz = _normalizeTimezone(timezone);
    final converted = convertTimezone(dateTime, tz);

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
      return '$day $month $year, $hour:$minute $tz';
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
    final tz = _normalizeTimezone(timezone);
    final offset = TimezoneConstants.timezoneOffsets[tz];
    if (offset == null) return tz;

    final sign = offset >= 0 ? '+' : '';
    return '$tz (UTC$sign$offset)';
  }

  static bool isValidCurrency(String currency) {
    return CurrencyConstants.availableCurrencies.contains(currency);
  }

  static bool isValidTimezone(String timezone) {
    return TimezoneConstants.availableTimezones.contains(timezone);
  }
}
