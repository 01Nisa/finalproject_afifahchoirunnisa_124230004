import 'package:flutter/material.dart';

class ApiConstants {
  static const String metMuseumBaseUrl =
      'https://collectionapi.metmuseum.org/public/collection/v1';
  static const List<int> artworkObjectIds = [
    437391,
    436835,
    438017,
    438761,
    436834,
    437390,
    438013,
    437394,
    437395,
    437396,
    437397,
    437398,
    437399,
    437400,
    437401,
    437402,
    437403,
    437404,
    437405,
    437406,
    437407,
    437408
  ];

  static const String googleApiKey = 'YOUR_GOOGLE_API_KEY_HERE';
  static const String geocodingBaseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
}

class AppColors {
  static const Color primary = Color(0xFFD4A017);
  static const Color primaryLight = Color(0xFFE5C158);
  static const Color primaryDark = Color(0xFFB8860B);

  static const Color secondary = Color(0xFF6B4E31);
  static const Color secondaryLight = Color(0xFF8B6F47);
  static const Color secondaryDark = Color(0xFF4A3520);

  static const Color accent = Color(0xFFB33C3C);
  static const Color accentLight = Color(0xFFCD5C5C);

 
  static const Color background = Color(0xFFF5F0E1); 
  static const Color surface = Color(0xFFFFF8E8); 
  static const Color surfaceVariant = Color(0xFFF9F5ED);

  static const Color textPrimary = Color(0xFF4A3520); 
  static const Color textSecondary = Color(0xFF6B5B4F);
  static const Color textTertiary = Color(0xFF9B8A7C);

  static const Color success = Color(0xFF5B8C5A); 
  static const Color error = Color(0xFFB33C3C); 
  static const Color warning = Color(0xFFD4A017);
  static const Color info = Color(0xFF6B4E31);

  static const Color border = Color(0xFFD4C4B0);
  static const Color divider = Color(0xFFC4B5A3);

  static const Color shadow = Color(0x1A4A3520);

  static const Color vintageCream = Color(0xFFFFF8E8);
  static const Color vintageGold = Color(0xFFD4A017);
  static const Color vintageBrown = Color(0xFF6B4E31);
  static const Color vintageRed = Color(0xFFB33C3C);
  static const Color vintageBg = Color(0xFFF5F0E1);
}

class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    fontFamily: 'Poppins',
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
    fontFamily: 'Poppins',
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
    fontFamily: 'Poppins',
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: AppColors.textSecondary,
    fontFamily: 'Poppins',
  );
}


class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
}


class CurrencyConstants {
  static const Map<String, double> exchangeRates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 149.50,
    'IDR': 15750.0,
    'CNY': 7.24,
    'AUD': 1.52,
  };

  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'IDR': 'Rp',
    'CNY': '¥',
    'AUD': 'A\$',
  };

  static const List<String> availableCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'IDR',
    'CNY',
    'AUD'
  ];
}

class TimezoneConstants {
  static const Map<String, int> timezoneOffsets = {
    'UTC': 0,
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'EST': -5,
    'PST': -8,
    'JST': 9,
    'GMT': 0,
  };

  static const List<String> availableTimezones = [
    'UTC',
    'WIB',
    'WITA',
    'WIT',
    'EST',
    'PST',
    'JST',
    'GMT'
  ];
}


class AppConstants {
  static const String appName = 'ARVA';
  static const String appVersion = '1.0.0';

  static const Duration sessionTimeout = Duration(hours: 24);

  static const String usersBox = 'users_box';
  static const String registeredAuctionsBox = 'registered_auctions_box';
  static const String feedbackBox = 'feedback_box';
  static const String sessionBox = 'session_box';
  static const String bidsBox = 'bids_box';

  static const int itemsPerPage = 10;


  // Change defaults to Indonesian settings
  static const String defaultCurrency = 'IDR';
  static const String defaultTimezone = 'WIB';
  static const String defaultLanguage = 'id';

 
  static const String placeholderImageUrl =
      'https://via.placeholder.com/400x300?text=No+Image';

  static const int auctionDurationMinutes = 60;
}

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const Duration auctionDuration =
      Duration(minutes: AppConstants.auctionDurationMinutes);
}

class AppValidators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }

    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }

    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }

    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }

    return null;
  }

  static String? phone(String? value) {
    // phone is optional in some forms; allow empty
    if (value == null || value.trim().isEmpty) return null;

    // disallow letters
    final hasLetters = RegExp(r'[A-Za-z]').hasMatch(value);
    if (hasLetters) {
      return 'Nomor telepon tidak boleh mengandung huruf';
    }

    // count digits only and require minimum 12 digits
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 12) {
      return 'Nomor telepon minimal 12 digit';
    }

    // basic allowed characters check (digits, +, -, spaces, parentheses)
    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Format nomor telepon tidak valid';
    }

    return null;
  }
}
