import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _uuid = const Uuid();

  late Box<UserModel> _usersBox;
  late Box<SessionModel> _sessionBox;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _usersBox = await Hive.openBox<UserModel>(AppConstants.usersBox);
      _sessionBox = await Hive.openBox<SessionModel>(AppConstants.sessionBox);
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize AuthService: $e');
    }
  }

  String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  bool _verifyPassword(String password, String hash) {
    try {
      return BCrypt.checkpw(password, hash);
    } catch (e) {
      return false;
    }
  }

  String _generateSessionToken() {
    return _uuid.v4();
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final existingUser = _usersBox.values.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception(''),
      );

      if (existingUser.email.isNotEmpty) {
        return {
          'success': false,
          'message': 'Email sudah terdaftar',
        };
      }
    } catch (e) {}

    try {
      final userId = _uuid.v4();
      final passwordHash = _hashPassword(password);

      final newUser = UserModel(
        id: userId,
        email: email.toLowerCase(),
        passwordHash: passwordHash,
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
      );

      await _usersBox.put(userId, newUser);

      return {
        'success': true,
        'message': 'Registrasi berhasil',
        'user': newUser,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // basic email format validation (reuse app validator logic)
      final emailError = AppValidators.email(email);
      if (emailError != null) {
        return {
          'success': false,
          'message': 'Format email tidak valid',
        };
      }

      // find user by email
      final matches = _usersBox.values
          .where((u) => u.email.toLowerCase() == email.toLowerCase());

      if (matches.isEmpty) {
        return {
          'success': false,
          'message': 'Email belum terdaftar',
        };
      }

      final user = matches.first;

      // verify password
      if (!_verifyPassword(password, user.passwordHash)) {
        return {
          'success': false,
          'message': 'Password salah',
        };
      }

      final sessionToken = _generateSessionToken();
      final session = SessionModel(
        userId: user.id,
        sessionToken: sessionToken,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(AppConstants.sessionTimeout),
      );

      await _sessionBox.put('current_session', session);

      return {
        'success': true,
        'message': 'Login berhasil',
        'user': user,
        'session': session,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  Future<void> logout() async {
    try {
      await _sessionBox.delete('current_session');
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final session = _sessionBox.get('current_session');

      if (session == null) return false;

      if (session.isExpired) {
        await logout();
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  SessionModel? getCurrentSession() {
    try {
      return _sessionBox.get('current_session');
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final session = getCurrentSession();
      if (session == null || session.isExpired) {
        return null;
      }

      return _usersBox.get(session.userId);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshSession() async {
    try {
      final session = getCurrentSession();
      if (session != null && !session.isExpired) {
        final updatedSession = SessionModel(
          userId: session.userId,
          sessionToken: session.sessionToken,
          createdAt: session.createdAt,
          expiresAt: DateTime.now().add(AppConstants.sessionTimeout),
        );

        await _sessionBox.put('current_session', updatedSession);
      }
    } catch (e) {
      throw Exception('Failed to refresh session: $e');
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _usersBox.get(userId);

      if (user == null) {
        return {
          'success': false,
          'message': 'User tidak ditemukan',
        };
      }

      if (!_verifyPassword(currentPassword, user.passwordHash)) {
        return {
          'success': false,
          'message': 'Password saat ini salah',
        };
      }

      final newPasswordHash = _hashPassword(newPassword);
      final updatedUser = user.copyWith(
        passwordHash: newPasswordHash,
        updatedAt: DateTime.now(),
      );

      await _usersBox.put(userId, updatedUser);

      return {
        'success': true,
        'message': 'Password berhasil diubah',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> deleteAccount(String userId) async {
    try {
      await _usersBox.delete(userId);
      await logout();

      return {
        'success': true,
        'message': 'Akun berhasil dihapus',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}
