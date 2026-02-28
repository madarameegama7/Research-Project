import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import '../dashboard/admin_dashboard.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';
import '../../widgets/navigation_wrapper.dart';

class LoginPage extends StatefulWidget {
  final String? successMessage;
  const LoginPage({super.key, this.successMessage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();

    // Show success message if it exists
    if (widget.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.successMessage!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString("saved_email");
    final savedPassword = prefs.getString("saved_password");
    final remember = prefs.getBool("remember_me") ?? false;

    if (remember && savedEmail != null && savedPassword != null) {
      setState(() {
        _rememberMe = true;
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
      });
    }
  }

  void _login() async {
    // Basic validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter email and password"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        await prefs.setString("saved_email", _emailController.text.trim());
        await prefs.setString(
          "saved_password",
          _passwordController.text.trim(),
        );
        await prefs.setBool("remember_me", true);
      } else {
        await prefs.remove("saved_email");
        await prefs.remove("saved_password");
        await prefs.setBool("remember_me", false);
      }

      if (user != null) {
        final role = user["role"];

        if (role == "farmer") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NavigationWrapper()),
          );
        } else if (role == "exporter") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NavigationWrapper()),
          );
        } else if (role == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Login failed - invalid credentials"),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login error: $e"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final primary = const Color(0xFF2E7D32);
    final lightGreen = const Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },

        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.pagePadding,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ResponsiveSpacing(mobile: 40, tablet: 60, desktop: 60),

                        // Logo with background
                        Container(
                          padding: EdgeInsets.all(
                            responsive.spacing(mobile: 16, tablet: 20),
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: lightGreen,
                            border: Border.all(
                              color: primary.withOpacity(0.3),
                              width: responsive.value(mobile: 2, tablet: 2.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(0.25),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/images/logos/logo.png",
                              height: responsive.value(mobile: 80, tablet: 100),
                              width: responsive.value(mobile: 80, tablet: 100),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        ResponsiveSpacing(mobile: 32, tablet: 40),

                        // Welcome back text
                        ResponsiveText(
                          "Welcome Back",
                          mobileFontSize: 28,
                          tabletFontSize: 32,
                          desktopFontSize: 32,
                          fontWeight: FontWeight.w300,
                          color: Colors.black87,
                        ),

                        const SizedBox(height: 4),

                        // Login title with gradient
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [primary, primary.withOpacity(0.7)],
                          ).createShader(bounds),
                          child: ResponsiveText(
                            "Login",
                            mobileFontSize: 32,
                            tabletFontSize: 38,
                            desktopFontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),

                        ResponsiveSpacing(mobile: 40, tablet: 48),

                        // Email field with icon
                        _buildInputField(
                          responsive: responsive,
                          label: "Email Address",
                          hint: "youremail@gmail.com",
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          primary: primary,
                        ),

                        ResponsiveSpacing(mobile: 20, tablet: 24),

                        // Password field with icon
                        _buildInputField(
                          responsive: responsive,
                          label: "Password",
                          hint: "Enter your password",
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outline,
                          primary: primary,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey[600],
                              size: responsive.mediumIconSize,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Remember me and Forgot password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Transform.scale(
                                    scale: responsive.value(
                                      mobile: 0.9,
                                      tablet: 1.0,
                                    ),
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                        // TODO: save to SharedPreferences
                                      },
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      "Remember me",
                                      style: TextStyle(
                                        fontSize: responsive.bodyFontSize,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: Text(
                                "Forgot password?",
                                style: TextStyle(
                                  fontSize: responsive.bodyFontSize,
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        ResponsiveSpacing(mobile: 32, tablet: 40),

                        // Login Button with shadow
                        Container(
                          width: double.infinity,
                          height: responsive.buttonHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              disabledBackgroundColor: primary.withOpacity(0.6),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Login",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize:
                                              responsive.titleFontSize + 1,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: responsive.smallIconSize,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        ResponsiveSpacing(mobile: 20, tablet: 24),

                        // Divider with "OR"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: responsive.bodyFontSize,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ),

                        ResponsiveSpacing(mobile: 20, tablet: 24),

                        // Google login button
                        Container(
                          width: double.infinity,
                          height: responsive.buttonHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final user = await _authService
                                    .signInWithGoogle();

                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Google login failed"),
                                    ),
                                  );
                                  return;
                                }

                                final role = user["role"];

                                // if (role == "farmer") {
                                //   Navigator.pushReplacement(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (_) => const FarmerDashboard(),
                                //     ),
                                //   );
                                // } else if (role == "exporter") {
                                //   Navigator.pushReplacement(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (_) => const ExporterDashboard(),
                                //     ),
                                //   );
                                // } else if (role == "admin") {
                                //   Navigator.pushReplacement(
                                //     context,
                                //     MaterialPageRoute(
                                //       builder: (_) => const AdminDashboard(),
                                //     ),
                                //   );
                                // }

                                if (role == "admin") {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminDashboard(),
                                    ),
                                  );
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NavigationWrapper(),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(28),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    "assets/images/icons/google.png",
                                    height: responsive.mediumIconSize,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Continue with Google",
                                    style: TextStyle(
                                      fontSize: responsive.titleFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        ResponsiveSpacing(mobile: 32, tablet: 40),

                        // Signup link
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: responsive.bodyFontSize + 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _navigateToSignUp,
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: responsive.bodyFontSize + 1,
                                ),
                              ),
                            ),
                          ],
                        ),

                        ResponsiveSpacing(mobile: 40, tablet: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required Responsive responsive,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    required Color primary,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: responsive.bodyFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(fontSize: responsive.bodyFontSize + 1),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: responsive.bodyFontSize + 1,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: Icon(
              prefixIcon,
              color: Colors.grey[600],
              size: responsive.mediumIconSize,
            ),
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.symmetric(
              horizontal: responsive.mediumSpacing,
              vertical: responsive.value(mobile: 18, tablet: 20),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
