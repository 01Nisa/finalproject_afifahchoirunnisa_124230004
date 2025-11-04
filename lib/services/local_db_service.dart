import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/interest_model.dart';
import '../models/feedback_model.dart';
import '../models/tawaran_model.dart';
import '../utils/constants.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  bool _isInitialized = false;
  Box<UserModel>? _usersBox;
  Box<InterestModel>? _registeredAuctionsBox;
  Box<FeedbackModel>? _feedbackBox;
  Box<TawaranModel>? _bidsBox;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _usersBox = await Hive.openBox<UserModel>(AppConstants.usersBox);
      _registeredAuctionsBox = await Hive.openBox<InterestModel>(
        AppConstants.registeredAuctionsBox,
      );
      _feedbackBox = await Hive.openBox<FeedbackModel>(
        AppConstants.feedbackBox,
      );
      _bidsBox = await Hive.openBox<TawaranModel>(AppConstants.bidsBox);

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize LocalDbService: $e');
    }
  }

  Box<UserModel> get usersBox {
    if (!_isInitialized || _usersBox == null) {
      throw Exception('LocalDbService not initialized');
    }
    return _usersBox!;
  }

  Box<InterestModel> get registeredAuctionsBox {
    if (!_isInitialized || _registeredAuctionsBox == null) {
      throw Exception('LocalDbService not initialized');
    }
    return _registeredAuctionsBox!;
  }

  Box<FeedbackModel> get feedbackBox {
    if (!_isInitialized || _feedbackBox == null) {
      throw Exception('LocalDbService not initialized');
    }
    return _feedbackBox!;
  }

  Box<TawaranModel> get bidsBox {
    if (!_isInitialized || _bidsBox == null) {
      throw Exception('LocalDbService not initialized');
    }
    return _bidsBox!;
  }

  Future<void> clearAll() async {
    await _usersBox?.clear();
    await _registeredAuctionsBox?.clear();
    await _feedbackBox?.clear();
    await _bidsBox?.clear();
  }

  Future<void> closeAll() async {
    await _usersBox?.close();
    await _registeredAuctionsBox?.close();
    await _feedbackBox?.close();
    await _bidsBox?.close();
    _isInitialized = false;
  }
}
