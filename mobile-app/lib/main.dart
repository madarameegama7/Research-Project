import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/auth/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/yield_prediction_provider.dart';
import 'providers/prediction_history_provider.dart';
import 'providers/app_providers.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AppProviders.initialize();
    print("✅ Firebase initialized successfully");
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => YieldPredictionProvider()),
          ChangeNotifierProvider(create: (_) => PredictionHistoryProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
    runApp(MyApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  final String? error;
  const MyApp({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CeylonPepper',
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Poppins'),
      // home: error != null ? ErrorScreen(error: error!) : const MainScreen(),
      // home: const NavigationWrapper(),
      home: error != null ? ErrorScreen(error: error!) : const SplashScreen(),
      navigatorObservers: [FirebaseErrorObserver()],
    );
  }
}

class FirebaseErrorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // This helps prevent Firebase context errors
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      // MaterialPageRoute(builder: (context) => const LoginScreen()),
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _navigateToSignUp(BuildContext context) {
    Navigator.push(
      context,
      // MaterialPageRoute(builder: (context) => const SignupScreen()),
      MaterialPageRoute(builder: (context) => const SignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white, Colors.green[50]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Big Leaf Icon
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.eco,
                          size: 80,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // App Title
                      const Text(
                        'CeylonPepper',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Subtitle
                      Text(
                        'Grow Together, Thrive Together',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Section with Buttons
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => _navigateToLogin(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            shadowColor: Colors.green.withOpacity(0.3),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => _navigateToSignUp(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: const BorderSide(
                                color: Colors.green,
                                width: 2,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Additional Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.agriculture,
                            color: Colors.green[400],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Connecting Pepper Farmers Worldwide',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Initialization Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
