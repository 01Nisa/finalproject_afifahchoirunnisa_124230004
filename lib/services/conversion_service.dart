class ConversionService {
  static const Map<String, double> _exchangeRates = {
    'USD': 1.0, 
    'EUR': 0.92, 
    'GBP': 0.79, 
    'IDR': 15750.0, 
    'JPY': 149.5, 
    'CNY': 7.24, 
    'SGD': 1.35, 
    'AUD': 1.52,
  };

  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'IDR': 'Rp',
    'JPY': '¥',
    'CNY': '¥',
    'SGD': 'S\$',
    'AUD': 'A\$',
  };

  static const Map<String, String> _currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'IDR': 'Indonesian Rupiah',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Yuan',
    'SGD': 'Singapore Dollar',
    'AUD': 'Australian Dollar',
  };

  static double convertFromUSD(double amountUSD, String toCurrency) {
    final rate = _exchangeRates[toCurrency] ?? 1.0;
    return amountUSD * rate;
  }

  static double convert(double amount, String fromCurrency, String toCurrency) {
    final fromRate = _exchangeRates[fromCurrency] ?? 1.0;
    final amountInUSD = amount / fromRate;

    return convertFromUSD(amountInUSD, toCurrency);
  }

  static String formatCurrency(double amount, String currency) {
    final symbol = _currencySymbols[currency] ?? currency;

    String formatted;
    if (currency == 'IDR' || currency == 'JPY') {
      formatted = amount.toStringAsFixed(0);
    } else {
      formatted = amount.toStringAsFixed(2);
    }

    formatted = formatted.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return '$symbol$formatted';
  }

  static List<Map<String, String>> getAvailableCurrencies() {
    return _exchangeRates.keys.map((code) {
      return {
        'code': code,
        'name': _currencyNames[code] ?? code,
        'symbol': _currencySymbols[code] ?? code,
      };
    }).toList();
  }

  static String getCurrencySymbol(String currency) {
    return _currencySymbols[currency] ?? currency;
  }

  static String getCurrencyName(String currency) {
    return _currencyNames[currency] ?? currency;
  }

  static const Map<String, int> _timezoneOffsets = {
    'WIB': 7, // Waktu Indonesia Barat (UTC+7)
    'WITA': 8, // Waktu Indonesia Tengah (UTC+8)
    'WIT': 9, // Waktu Indonesia Timur (UTC+9)
    'London': 0, // London (UTC+0/GMT)
    'London+1': 1, // Central European Time (UTC+1)
    'New York': -5, // Eastern Time (UTC-5)
    'Tokyo': 9, // Japan Standard Time (UTC+9)
    'Singapore': 8, // Singapore Time (UTC+8)
  };

  static const Map<String, String> _timezoneNames = {
    'WIB': 'Waktu Indonesia Barat',
    'WITA': 'Waktu Indonesia Tengah',
    'WIT': 'Waktu Indonesia Timur',
    'London': 'Greenwich Mean Time',
    'London+1': 'Central European Time',
    'New York': 'Eastern Standard Time',
    'Tokyo': 'Japan Standard Time',
    'Singapore': 'Singapore Time',
  };

  static DateTime convertToTimezone(DateTime utcTime, String timezone) {
    final offset = _timezoneOffsets[timezone] ?? 0;
    return utcTime.add(Duration(hours: offset));
  }

  static DateTime convertBetweenTimezones(
    DateTime time,
    String fromTimezone,
    String toTimezone,
  ) {
    final fromOffset = _timezoneOffsets[fromTimezone] ?? 0;
    final toOffset = _timezoneOffsets[toTimezone] ?? 0;
    final offsetDiff = toOffset - fromOffset;

    return time.add(Duration(hours: offsetDiff));
  }

  static String formatDateTime(DateTime dateTime, {bool includeTime = true}) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;

    if (!includeTime) {
      return '$day/$month/$year';
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  static String formatDateWithMonth(DateTime dateTime) {
    const months = [
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

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  static String getTimezoneOffsetString(String timezone) {
    final offset = _timezoneOffsets[timezone] ?? 0;
    final sign = offset >= 0 ? '+' : '';
    return 'UTC$sign$offset';
  }

  static List<Map<String, String>> getAvailableTimezones() {
    return _timezoneOffsets.keys.map((code) {
      return {
        'code': code,
        'name': _timezoneNames[code] ?? code,
        'offset': getTimezoneOffsetString(code),
      };
    }).toList();
  }

  static String getTimezoneName(String timezone) {
    return _timezoneNames[timezone] ?? timezone;
  }

  static String formatRelativeTime(DateTime targetTime) {
    final now = DateTime.now();
    final difference = targetTime.difference(now);

    if (difference.isNegative) {
      return 'Sudah berlalu';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return '$days hari lagi';
    } else if (hours > 0) {
      return '$hours jam lagi';
    } else if (minutes > 0) {
      return '$minutes menit lagi';
    } else {
      return 'Segera dimulai';
    }
  }

  static Map<String, int> getCountdown(DateTime targetTime) {
    final now = DateTime.now();
    final difference = targetTime.difference(now);

    if (difference.isNegative) {
      return {'days': 0, 'hours': 0, 'minutes': 0, 'seconds': 0};
    }

    return {
      'days': difference.inDays,
      'hours': difference.inHours % 24,
      'minutes': difference.inMinutes % 60,
      'seconds': difference.inSeconds % 60,
    };
  }

  static String formatCountdown(DateTime targetTime) {
    final countdown = getCountdown(targetTime);
    final days = countdown['days']!;
    final hours = countdown['hours']!;
    final minutes = countdown['minutes']!;

    if (days > 0) {
      return '$days hari $hours jam';
    } else if (hours > 0) {
      return '$hours jam $minutes menit';
    } else {
      return '$minutes menit';
    }
  }
}
