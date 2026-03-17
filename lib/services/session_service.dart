import 'app_state.dart';

class SessionService {
  static String? _authToken;
  static String? _userId;

  static String? get authToken => _authToken;
  static String? get userId => _userId;
  static bool get isAuthenticated =>
      (_authToken?.isNotEmpty ?? false) && (_userId?.isNotEmpty ?? false);
  static String get storageScope =>
      isAuthenticated ? 'user:${_userId!}' : 'guest';

  static Future<void> init() async {
    _authToken = null;
    _userId = null;
    userNameNotifier.value = '';
    userEmailNotifier.value = '';
    userPhoneNotifier.value = '';
    isGuestNotifier.value = !isAuthenticated;
  }

  static Future<void> saveSession({
    required String token,
    required String userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    _authToken = token;
    _userId = userId;
    userNameNotifier.value = name;
    userEmailNotifier.value = email;
    userPhoneNotifier.value = phone;
    isGuestNotifier.value = false;
  }

  static Future<void> clearSession() async {
    _authToken = null;
    _userId = null;
    isGuestNotifier.value = true;
    userNameNotifier.value = '';
    userEmailNotifier.value = '';
    userPhoneNotifier.value = '';
  }

  static Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    userNameNotifier.value = name;
    userEmailNotifier.value = email;
    userPhoneNotifier.value = phone;
  }

  static Map<String, String> authHeaders() {
    if (!isAuthenticated) {
      return const {};
    }
    return {'Authorization': 'Bearer $_authToken'};
  }
}
