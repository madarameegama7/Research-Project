import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../features/certifications/screens/exporter_certifications_dashboard_screen.dart';
import '../features/certifications/screens/farmer_add_certifications_screen.dart';
import '../features/certifications/screens/exporter_certification_details_screen.dart';
import '../features/certifications/screens/farmer_certifications_dashboard_screen.dart';
import '../services/auth_service.dart';
import '../features/auth/login_page.dart';
import '../utils/responsive.dart';

// Helper to create a Color from an existing Color with a custom opacity (0.0-1.0)
Color colorWithOpacity(Color c, double opacity) {
  final alpha = (opacity * 255).round().clamp(0, 255);
  return c.withAlpha(alpha);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _uploading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color _primary = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _loadUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    final data = await _auth.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = data;
        _loading = false;
      });
      _animationController.forward(from: 0);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    setState(() => _uploading = true);

    try {
      final uid =
          await _auth.storage.read(key: 'uid') ?? _auth.currentUser?.uid;
      if (uid == null) throw Exception('No user id');

      final bytes = await file.readAsBytes();
      final ref = FirebaseStorage.instance.ref().child(
        'profile_images/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      final updated = await _auth.updateCurrentUser({'imageUrl': url});
      if (updated != null && mounted) {
        await _loadUser();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile image updated'),
            backgroundColor: _primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save image URL'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }

  void _showEditProfile() {
    final firstCtrl = TextEditingController(text: _user?['firstName'] ?? '');
    final lastCtrl = TextEditingController(text: _user?['lastName'] ?? '');
    final contactCtrl = TextEditingController(text: _user?['contact'] ?? '');
    final locationCtrl = TextEditingController(text: _user?['location'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorWithOpacity(_primary, 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_outlined, color: _primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(firstCtrl, 'First name', Icons.person_outline,
                    validator: (val) =>
                        val?.trim().isEmpty == true ? 'Required' : null),
                const SizedBox(height: 12),
                _buildTextField(lastCtrl, 'Last name', Icons.person_outline),
                const SizedBox(height: 12),
                _buildTextField(contactCtrl, 'Contact', Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildTextField(
                    locationCtrl, 'Location', Icons.location_on_outlined),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              final body = {
                'firstName': firstCtrl.text.trim(),
                'lastName': lastCtrl.text.trim(),
                'contact': contactCtrl.text.trim(),
                'location': locationCtrl.text.trim(),
              };
              Navigator.pop(ctx);
              final updated = await _auth.updateCurrentUser(body);
              if (updated != null && mounted) {
                await _loadUser();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Profile updated'),
                    backgroundColor: _primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        prefixIcon: Icon(icon, color: _primary, size: 20),
        labelStyle: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primary),
                ),
              )
            : _user == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off_outlined,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No user data found',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadUser,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadUser,
                  color: _primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header matching dashboard style
                        _buildHeader(responsive),

                        ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

                        // Info Cards
                        SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.value(
                                  mobile: 16, tablet: 24, desktop: 32),
                            ),
                            child: _buildInfoCards(responsive),
                          ),
                        ),

                        ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

                        // Section title
                        _buildSectionTitle(
                          responsive,
                          'Account Actions',
                          Icons.manage_accounts_rounded,
                        ),

                        ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),

                        // Action Buttons
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.value(
                                mobile: 16, tablet: 24, desktop: 32),
                          ),
                          child: _buildActionButtons(responsive),
                        ),

                        ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                        // Section title for settings
                        _buildSectionTitle(
                          responsive,
                          'Settings & Preferences',
                          Icons.settings_rounded,
                        ),

                        ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),

                        // Settings Section
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.value(
                                mobile: 16, tablet: 24, desktop: 32),
                          ),
                          child: _buildSettingsSection(responsive),
                        ),

                        ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(Responsive responsive) {
    final fullName =
        '${_user!['firstName'] ?? ''} ${_user!['lastName'] ?? ''}'.trim();
    final email = _user!['email'] ?? '';
    final role = _user!['role'] ?? 'User';

    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        tablet: const EdgeInsets.fromLTRB(32, 24, 32, 36),
        desktop: const EdgeInsets.fromLTRB(40, 28, 40, 42),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, colorWithOpacity(_primary, 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(
            responsive.value(mobile: 28, tablet: 36, desktop: 40),
          ),
          bottomRight: Radius.circular(
            responsive.value(mobile: 28, tablet: 36, desktop: 40),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(_primary, 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: responsive.fontSize(
                      mobile: 22, tablet: 26, desktop: 30),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorWithOpacity(Colors.white, 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorWithOpacity(Colors.white, 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: Colors.white,
                      size: responsive.value(mobile: 14, tablet: 16, desktop: 18),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _capitalizeFirst(role),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.fontSize(
                            mobile: 12, tablet: 13, desktop: 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

          // Avatar + info row
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorWithOpacity(Colors.white, 0.4),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorWithOpacity(Colors.black, 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: responsive.value(
                          mobile: 44, tablet: 52, desktop: 60),
                      backgroundColor: Colors.white,
                      child: _uploading
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(_primary),
                              strokeWidth: 2,
                            )
                          : _user!['imageUrl'] != null &&
                                _user!['imageUrl'].toString().isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                _user!['imageUrl'],
                                width: responsive.value(
                                    mobile: 88, tablet: 104, desktop: 120),
                                height: responsive.value(
                                    mobile: 88, tablet: 104, desktop: 120),
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(_primary),
                                    strokeWidth: 2,
                                  );
                                },
                              ),
                            )
                          : Text(
                              (_user!['firstName'] ?? 'U')
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: responsive.fontSize(
                                    mobile: 30, tablet: 36, desktop: 42),
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _uploading ? null : _pickAndUploadAvatar,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: colorWithOpacity(_primary, 0.2), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: colorWithOpacity(Colors.black, 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(
                          responsive.value(mobile: 6, tablet: 8, desktop: 10),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: responsive.value(
                              mobile: 14, tablet: 16, desktop: 18),
                          color: _primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              ResponsiveSpacing.horizontal(mobile: 16, tablet: 20, desktop: 24),

              // Name + email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : 'User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.fontSize(
                            mobile: 20, tablet: 24, desktop: 28),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: colorWithOpacity(Colors.white, 0.75),
                          size: responsive.value(
                              mobile: 13, tablet: 14, desktop: 15),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            email,
                            style: TextStyle(
                              color: colorWithOpacity(Colors.white, 0.85),
                              fontSize: responsive.fontSize(
                                  mobile: 12, tablet: 13, desktop: 14),
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (_user!['location'] != null &&
                        _user!['location'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: colorWithOpacity(Colors.white, 0.75),
                            size: responsive.value(
                                mobile: 13, tablet: 14, desktop: 15),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _user!['location'],
                              style: TextStyle(
                                color: colorWithOpacity(Colors.white, 0.85),
                                fontSize: responsive.fontSize(
                                    mobile: 12, tablet: 13, desktop: 14),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    Responsive responsive,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(mobile: 16, tablet: 24, desktop: 32),
      ),
      child: Row(
        children: [
          Container(
            width: responsive.value(mobile: 4, tablet: 5, desktop: 6),
            height: responsive.value(mobile: 20, tablet: 22, desktop: 24),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ResponsiveSpacing.horizontal(mobile: 10, tablet: 12, desktop: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize:
                    responsive.fontSize(mobile: 17, tablet: 20, desktop: 22),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          Icon(
            icon,
            color: _primary,
            size: responsive.value(mobile: 22, tablet: 24, desktop: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(Responsive responsive) {
    final contact = _user!['contact'] ?? 'Not set';
    final location = _user!['location'] ?? 'Not set';
    final role = _capitalizeFirst(_user!['role'] ?? 'User');

    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            responsive,
            Icons.badge_outlined,
            'Role',
            role,
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 10, tablet: 14, desktop: 18),
        Expanded(
          child: _buildInfoCard(
            responsive,
            Icons.phone_outlined,
            'Contact',
            contact,
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 10, tablet: 14, desktop: 18),
        Expanded(
          child: _buildInfoCard(
            responsive,
            Icons.location_on_outlined,
            'Location',
            location,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    Responsive responsive,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        tablet: const EdgeInsets.all(18),
        desktop: const EdgeInsets.all(20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 14, tablet: 18, desktop: 20),
        ),
        border: Border.all(
          color: colorWithOpacity(_primary, 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(Colors.black, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(
              responsive.value(mobile: 8, tablet: 10, desktop: 12),
            ),
            decoration: BoxDecoration(
              color: colorWithOpacity(_primary, 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: _primary,
              size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
            ),
          ),
          ResponsiveSpacing(mobile: 8, tablet: 10, desktop: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(mobile: 13, tablet: 14, desktop: 15),
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          ResponsiveSpacing(mobile: 2, tablet: 3, desktop: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(mobile: 11, tablet: 12, desktop: 13),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Responsive responsive) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showEditProfile,
              borderRadius: BorderRadius.circular(
                responsive.value(mobile: 14, tablet: 16, desktop: 18),
              ),
              child: Container(
                padding: responsive.padding(
                  mobile: const EdgeInsets.all(14),
                  tablet: const EdgeInsets.all(18),
                  desktop: const EdgeInsets.all(20),
                ),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(
                    responsive.value(mobile: 14, tablet: 16, desktop: 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorWithOpacity(_primary, 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
                    ),
                    ResponsiveSpacing.horizontal(
                        mobile: 8, tablet: 10, desktop: 12),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.fontSize(
                            mobile: 14, tablet: 15, desktop: 16),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 12, tablet: 16, desktop: 20),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(
                responsive.value(mobile: 14, tablet: 16, desktop: 18),
              ),
              child: Container(
                padding: responsive.padding(
                  mobile: const EdgeInsets.all(14),
                  tablet: const EdgeInsets.all(18),
                  desktop: const EdgeInsets.all(20),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    responsive.value(mobile: 14, tablet: 16, desktop: 18),
                  ),
                  border: Border.all(
                    color: Colors.redAccent.withAlpha(180),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorWithOpacity(Colors.black, 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
                    ),
                    ResponsiveSpacing.horizontal(
                        mobile: 8, tablet: 10, desktop: 12),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: responsive.fontSize(
                            mobile: 14, tablet: 15, desktop: 16),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(Responsive responsive) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 16, tablet: 20, desktop: 24),
        ),
        border: Border.all(
          color: colorWithOpacity(_primary, 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(Colors.black, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            responsive,
            Icons.verified_outlined,
            'Certifications',
            'Add or manage your certifications',
            _openCertifications,
            isFirst: true,
          ),
          Divider(height: 1, color: colorWithOpacity(_primary, 0.08)),
          _buildSettingsTile(
            responsive,
            Icons.notifications_outlined,
            'Notifications',
            'Manage your notification preferences',
            () {},
          ),
          Divider(height: 1, color: colorWithOpacity(_primary, 0.08)),
          _buildSettingsTile(
            responsive,
            Icons.lock_outline,
            'Privacy',
            'Control your privacy settings',
            () {},
          ),
          Divider(height: 1, color: colorWithOpacity(_primary, 0.08)),
          _buildSettingsTile(
            responsive,
            Icons.help_outline,
            'Help & Support',
            'Get help or contact support',
            () {},
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    Responsive responsive,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final radius = responsive.value(mobile: 16, tablet: 20, desktop: 24);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? Radius.circular(radius) : Radius.zero,
          bottom: isLast ? Radius.circular(radius) : Radius.zero,
        ),
        child: Padding(
          padding: responsive.padding(
            mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  responsive.value(mobile: 9, tablet: 10, desktop: 11),
                ),
                decoration: BoxDecoration(
                  color: colorWithOpacity(_primary, 0.08),
                  borderRadius: BorderRadius.circular(
                    responsive.value(mobile: 10, tablet: 12, desktop: 13),
                  ),
                ),
                child: Icon(
                  icon,
                  color: _primary,
                  size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
                ),
              ),
              ResponsiveSpacing.horizontal(mobile: 14, tablet: 16, desktop: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: responsive.fontSize(
                            mobile: 14, tablet: 15, desktop: 16),
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: responsive.fontSize(
                            mobile: 11, tablet: 12, desktop: 13),
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
  }

  void _openCertifications() {
    final role = (_user?['role'] ?? '').toString().toLowerCase();

    Widget screen;
    if (role == 'farmer') {
      screen = const FarmerCertificationsDashboardScreen();
    } else if (role == 'exporter') {
      screen = const ExporterCertificationsDashboardScreen();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unknown user role'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}