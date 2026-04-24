import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';

  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static Future<void> saveUserToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_isLoggedInKey, true);
  }

  static Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userData.toString());
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      // In a real app, you'd parse this back to a proper object
      return {'data': userData};
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  static Future<bool> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get Firebase ID token
      final idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        await saveUserToken(idToken);
        await saveUserData({
          'email': email,
          'uid': userCredential.user?.uid,
          'loginTime': DateTime.now().toString()
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> register(
      String email, String password, String name) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with name
      await userCredential.user?.updateDisplayName(name);

      // Get Firebase ID token
      final idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        await saveUserToken(idToken);
        await saveUserData({
          'email': email,
          'name': name,
          'uid': userCredential.user?.uid,
          'registrationTime': DateTime.now().toString()
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await logout();
  }

  static Future<String?> getFirebaseToken() async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken();
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isUserAuthenticated() async {
    return _firebaseAuth.currentUser != null;
  }
}
