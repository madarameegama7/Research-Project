import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final storage = const FlutterSecureStorage();

  String? validateEmail(String email) {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      return "Email is required";
    }

    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) {
      return "Password is required";
    }

    if (password.length < 8) {
      return "Password must be at least 8 characters";
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Password must contain at least one uppercase letter";
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Password must contain at least one lowercase letter";
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Password must contain at least one number";
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return "Password must contain at least one special character (!@#\$%^&*...)";
    }

    return null;
  }

  String? validateContactNumber(String contact) {
    final cleanContact = contact.replaceAll(RegExp(r'\s+'), '');

    if (cleanContact.isEmpty) {
      return "Contact number is required";
    }

    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(cleanContact)) {
      return "Contact number must be 10 digits";
    }

    if (cleanContact.startsWith('0')) {
      if (cleanContact.length < 10) {
        return "Contact number is too short";
      }
    }

    return null;
  }

  Future<Map<String, dynamic>?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String contact,
    required String role,
  }) async {
    try {
      // Validate email
      String? emailError = validateEmail(email);
      if (emailError != null) {
        print("Email validation error: $emailError");
        return {"error": emailError};
      }

      // Validate password
      String? passwordError = validatePassword(password);
      if (passwordError != null) {
        print("Password validation error: $passwordError");
        return {"error": passwordError};
      }

      // Validate contact number
      String? contactError = validateContactNumber(contact);
      if (contactError != null) {
        print("Contact validation error: $contactError");
        return {"error": contactError};
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) return null;

      String? token = await user.getIdToken();
      if (token == null) return null;

      // send user profile to backend
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/users/register"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "firebaseUid": user.uid,
          "email": email,
          "firstName": firstName,
          "lastName": lastName,
          "contact": contact,
          "role": role,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // save token locally
        await storage.write(key: "token", value: token);
        await storage.write(key: "uid", value: user.uid);
        await storage.write(key: "role", value: role);

        return data;
      }

      print("Signup backend error: ${response.body}");
      return null;
    } catch (e) {
      print("Signup error: $e");
      return null;
    }
  }

  // LOGIN
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) return null;

      String? token = await user.getIdToken();
      if (token == null) return null;

      print("🔥 FIREBASE TOKEN (LOGIN):");
      print(token);
      print("🔥 END TOKEN");

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/users/me"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await storage.write(key: "token", value: token);
        await storage.write(key: "uid", value: user.uid);
        await storage.write(key: "role", value: data["role"]);

        return data;
      }

      print("Login backend error: ${response.body}");
      return null;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  // GET CURRENT USER FROM BACKEND
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      String? token = await storage.read(key: "token");
      if (token == null) return null;

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/users/me"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print("Get user error: $e");
      return null;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    await storage.deleteAll();
  }

  // FORGOT PASSWORD
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print("Password reset error: $e");
      return false;
    }
  }

  // GOOGLE LOGIN
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final UserCredential result = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final user = result.user;
      if (user == null) return null;

      final token = await user.getIdToken();

      // check if user exists in backend
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/users/me"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: "token", value: token);
        await storage.write(key: "uid", value: user.uid);
        await storage.write(key: "role", value: data["role"]);
        return data;
      }

      // if new Google user, register
      final regResponse = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/users/register"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "firebaseUid": user.uid,
          "email": user.email,
          "firstName": user.displayName?.split(" ").first,
          "lastName": user.displayName?.split(" ").last,
          "contact": "",
          "role": "farmer", // Default role for Google signup
        }),
      );

      if (regResponse.statusCode == 200 || regResponse.statusCode == 201) {
        final data = jsonDecode(regResponse.body);
        await storage.write(key: "token", value: token);
        await storage.write(key: "uid", value: user.uid);
        await storage.write(key: "role", value: data["role"]);
        return data;
      }

      return null;
    } catch (e) {
      print("Google sign in error: $e");
      return null;
    }
  }

  // CURRENT FIREBASE USER
  User? get currentUser => _auth.currentUser;

  // UPDATE CURRENT USER (profile fields)
  Future<Map<String, dynamic>?> updateCurrentUser(
    Map<String, dynamic> body,
  ) async {
    try {
      String? token = await storage.read(key: "token");
      if (token == null) return null;

      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/api/users/me"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      print('Update user failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('Update user error: $e');
      return null;
    }
  }
}


// Induwara
// import 'package:firebase_auth/firebase_auth.dart';
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   Future<User?> login(String email, String password) async {
//     try {
//       UserCredential result = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return result.user;
//     } catch (e) {
//       print("Login error: $e");
//       return null;
//     }
//   }
//
//   Future<User?> signUp(String email, String password, String username) async {
//     try {
//       UserCredential result = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       // Update display name if needed
//       if (result.user != null) {
//         await result.user!.updateDisplayName(username);
//       }
//
//       return result.user;
//     } catch (e) {
//       print("Signup error: $e");
//       return null;
//     }
//   }
//
//   // Add this logout method
//   Future<void> logout() async {
//     try {
//       await _auth.signOut();
//     } catch (e) {
//       print("Logout error: $e");
//     }
//   }
//
//   // Add this getter for current user
//   User? get currentUser => _auth.currentUser;
// }