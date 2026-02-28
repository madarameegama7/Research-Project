import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'bottom_navigation.dart';
import '../features/dashboard/farmer_dashboard.dart';
import '../features/dashboard/exporter_dashboard.dart';
import '../features/auth/login_page.dart';
import 'my_farm_screen.dart';
import 'market_screen.dart';
import 'profile_screen.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({Key? key}) : super(key: key);

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final storage = const FlutterSecureStorage();
  late Future<Map<String, dynamic>> _userAuthData;

  @override
  void initState() {
    super.initState();
    _userAuthData = _checkUserLoginAndRole();
  }

  Future<Map<String, dynamic>> _checkUserLoginAndRole() async {
    try {
      String? token = await storage.read(key: "token");
      String? role = await storage.read(key: "role");
      User? currentUser = _auth.currentUser;

      bool isLoggedIn = token != null && currentUser != null;

      return {
        'isLoggedIn': isLoggedIn,
        'role': role ?? 'farmer', // Default to farmer if no role found
      };
    } catch (e) {
      print("Auth check error: $e");
      return {'isLoggedIn': false, 'role': 'farmer'};
    }
  }

  List<Widget> _getPagesByRole(String role) {
    if (role == 'exporter') {
      // Exporter pages
      return const [ExporterDashboard(), MarketScreen(), ProfileScreen()];
    } else {
      // Farmer pages (default)
      return const [
        FarmerDashboard(),
        MarketScreen(),
        MyFarmScreen(),
        ProfileScreen(),
      ];
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userAuthData,
      builder: (context, snapshot) {
        // While checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If not logged in, show login page
        if (snapshot.data?['isLoggedIn'] == false) {
          return const LoginPage();
        }

        // Get user role
        String userRole = snapshot.data?['role'] ?? 'farmer';
        final pages = _getPagesByRole(userRole);

        // If logged in, show dashboard with navigation
        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: BottomNavigation(
            currentIndex: _currentIndex,
            onTabSelected: _onTabSelected,
            userRole: userRole,
          ),
        );
      },
    );
  }
}
