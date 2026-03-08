import 'package:flutter/material.dart';
import '../../services/market_service.dart';
import '../../services/auth_service.dart';
import '../../models/market_product.dart';
import '../../utils/responsive.dart';

// Same helper used in FarmerDashboard & ProfileScreen
Color colorWithOpacity(Color c, double opacity) {
  final alpha = (opacity * 255).round().clamp(0, 255);
  return c.withAlpha(alpha);
}

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF2E7D32);

  final MarketService _service = MarketService();
  final AuthService _auth = AuthService();
  bool _loading = true;
  String? _error;
  List<MarketProduct> _products = [];
  String _searchQuery = '';
  String? _userRole;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _loadProducts();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await _auth.storage.read(key: 'role');
      if (mounted)
        setState(() => _userRole = role?.toString().toLowerCase() ?? 'farmer');
    } catch (e) {
      if (mounted) setState(() => _userRole = 'farmer');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchProducts();
      if (mounted) {
        setState(() => _products = data);
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadProducts,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MarketProduct> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // ── Dialogs ────────────────────────────────────────────────────────────

  Future<void> _showProductForm([MarketProduct? product]) async {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(
      text: product != null ? product.price.toString() : '',
    );
    final unitCtrl = TextEditingController(text: product?.unit ?? 'kg');
    final formKey = GlobalKey<FormState>();

    final Map<String, dynamic>?
    result = await showDialog<Map<String, dynamic>?>(
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
              child: Icon(
                product == null
                    ? Icons.add_shopping_cart_outlined
                    : Icons.edit_outlined,
                color: _primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              product == null ? 'Add New Product' : 'Edit Product',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(
                  nameCtrl,
                  'Product Name',
                  Icons.shopping_basket_outlined,
                  hint: 'e.g., Rice, Wheat',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Product name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                _dialogField(
                  priceCtrl,
                  'Price',
                  Icons.attach_money_outlined,
                  hint: '0.00',
                  prefixText: 'Rs ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Price is required';
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Enter a valid price';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _dialogField(
                  unitCtrl,
                  'Unit',
                  Icons.scale_outlined,
                  hint: 'kg, lbs, pcs',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Unit is required'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx, {
                'name': nameCtrl.text.trim(),
                'price': double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                'unit': unitCtrl.text.trim(),
                'imageUrl': product?.imageUrl,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(product == null ? 'Add Product' : 'Save'),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    priceCtrl.dispose();
    unitCtrl.dispose();

    if (result != null) {
      try {
        if (product == null) {
          await _service.createProduct(result);
        } else {
          await _service.updateProduct(product.id, result);
        }
        if (mounted) {
          await _loadProducts();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                product == null
                    ? 'Product added successfully'
                    : 'Product updated successfully',
              ),
              backgroundColor: _primary,
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
              content: Text('Failed to save product: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    String? prefixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: Icon(icon, color: _primary, size: 20),
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
        labelStyle: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  Future<void> _confirmDelete(MarketProduct product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Product',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text('Are you sure you want to delete "${product.name}"?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        // await _service.deleteProduct(product.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Product deleted'),
              backgroundColor: _primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          await _loadProducts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  // ── Grid helpers ───────────────────────────────────────────────────────

  int _crossAxisCount(Responsive r) {
    if (r.isDesktop) return 4;
    if (r.isTablet) return 3;
    if (r.isSmallPhone) return 1;
    return 2;
  }

  double _cardHeight(Responsive r) {
    if (r.isDesktop) return 290;
    if (r.isTablet) return 265;
    if (r.isSmallPhone) return 230;
    return 240;
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _loadProducts,
            color: _primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────
                  _buildHeader(r),

                  ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

                  // ── Search ──────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.value(mobile: 16, tablet: 24, desktop: 32),
                    ),
                    child: _buildSearchBar(r),
                  ),

                  ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                  // ── Section title ────────────────────────────────────
                  _buildSectionTitle(
                    r,
                    'Available Products',
                    Icons.store_rounded,
                  ),

                  ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),

                  // ── Products / states ────────────────────────────────
                  _buildContent(r),

                  // Bottom padding for FAB clearance
                  ResponsiveSpacing(mobile: 80, tablet: 88, desktop: 96),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _products.isEmpty || _userRole == 'exporter'
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showProductForm(),
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text(
                'Add Product',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 4,
            ),
    );
  }

  // ── Header — mirrors Dashboard/Profile gradient header ─────────────────

  Widget _buildHeader(Responsive r) {
    return Container(
      padding: r.padding(
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
            r.value(mobile: 28, tablet: 36, desktop: 40),
          ),
          bottomRight: Radius.circular(
            r.value(mobile: 28, tablet: 36, desktop: 40),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market Place',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: r.fontSize(mobile: 26, tablet: 30, desktop: 34),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Buy and sell fresh farm produce',
                  style: TextStyle(
                    color: colorWithOpacity(Colors.white, 0.80),
                    fontSize: r.fontSize(mobile: 13, tablet: 14, desktop: 15),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.storefront_rounded,
            size: r.value(mobile: 64, tablet: 80, desktop: 96),
            color: colorWithOpacity(Colors.white, 0.15),
          ),
        ],
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────

  Widget _buildSearchBar(Responsive r) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          r.value(mobile: 14, tablet: 16, desktop: 18),
        ),
        border: Border.all(color: colorWithOpacity(_primary, 0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(Colors.black, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(fontSize: r.bodyFontSize),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(
            fontSize: r.bodyFontSize,
            color: Colors.grey[400],
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _primary,
            size: r.mediumIconSize,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: r.smallIconSize,
                    color: Colors.grey[500],
                  ),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: r.mediumSpacing,
            vertical: r.smallSpacing + 4,
          ),
        ),
      ),
    );
  }

  // ── Section title — exact same pattern as Dashboard & Profile ──────────

  Widget _buildSectionTitle(Responsive r, String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: r.value(mobile: 16, tablet: 24, desktop: 32),
      ),
      child: Row(
        children: [
          Container(
            width: r.value(mobile: 4, tablet: 5, desktop: 6),
            height: r.value(mobile: 20, tablet: 22, desktop: 24),
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
                fontSize: r.fontSize(mobile: 17, tablet: 20, desktop: 22),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          Icon(
            icon,
            color: _primary,
            size: r.value(mobile: 22, tablet: 24, desktop: 26),
          ),
        ],
      ),
    );
  }

  // ── Content states ─────────────────────────────────────────────────────

  Widget _buildContent(Responsive r) {
    if (_loading) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
        ),
      );
    }
    if (_error != null) return _buildErrorState(r);
    if (_filteredProducts.isEmpty) return _buildEmptyState(r);

    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: r.value(mobile: 16, tablet: 24, desktop: 32),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _crossAxisCount(r),
            mainAxisExtent: _cardHeight(r),
            crossAxisSpacing: r.mediumSpacing,
            mainAxisSpacing: r.mediumSpacing,
          ),
          itemCount: _filteredProducts.length,
          itemBuilder: (context, index) {
            final product = _filteredProducts[index];
            return _ProductCard(
              product: product,
              onEdit: () => _showProductForm(product),
              onDelete: () => _confirmDelete(product),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(Responsive r) {
    return Padding(
      padding: EdgeInsets.all(r.largeSpacing),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(
                r.value(mobile: 20, tablet: 24, desktop: 28),
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: r.value(mobile: 48, tablet: 56, desktop: 64),
                color: Colors.red.shade300,
              ),
            ),
            SizedBox(height: r.mediumSpacing),
            Text(
              'Failed to load products',
              style: TextStyle(
                fontSize: r.titleFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: r.smallSpacing),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r.bodyFontSize,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: r.largeSpacing),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: r.largeSpacing,
                  vertical: r.mediumSpacing,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Responsive r) {
    return Padding(
      padding: EdgeInsets.all(r.largeSpacing),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(
                r.value(mobile: 24, tablet: 28, desktop: 32),
              ),
              decoration: BoxDecoration(
                color: colorWithOpacity(_primary, 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isEmpty
                    ? Icons.shopping_bag_outlined
                    : Icons.search_off_rounded,
                size: r.value(mobile: 56, tablet: 68, desktop: 80),
                color: colorWithOpacity(_primary, 0.4),
              ),
            ),
            SizedBox(height: r.largeSpacing),
            Text(
              _searchQuery.isEmpty ? 'No products yet' : 'No products found',
              style: TextStyle(
                fontSize: r.headingFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: r.smallSpacing),
            Text(
              _searchQuery.isEmpty
                  ? 'Start by adding your first product'
                  : 'Try a different search term',
              style: TextStyle(
                fontSize: r.bodyFontSize,
                color: Colors.grey[600],
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              SizedBox(height: r.largeSpacing),
              ElevatedButton.icon(
                onPressed: () => _showProductForm(),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Add Product',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: r.largeSpacing,
                    vertical: r.mediumSpacing,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  final MarketProduct product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  static const Color _primary = Color(0xFF2E7D32);
  int _qty = 1;
  bool _fav = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final theme = Theme.of(context);
    final r = context.responsive;

    final imageContainerHeight = r.value(
      mobile: 105.0,
      tablet: 125.0,
      desktop: 140.0,
    );
    final imageSize = r.value(mobile: 75.0, tablet: 88.0, desktop: 100.0);
    final nameSize = r.value(mobile: 13.0, tablet: 14.0, desktop: 16.0);
    final unitSize = r.value(mobile: 11.0, tablet: 12.0, desktop: 13.0);
    final priceSize = r.value(mobile: 12.0, tablet: 14.0, desktop: 16.0);
    final qtyIcon = r.value(mobile: 13.0, tablet: 15.0, desktop: 17.0);
    final pad = r.value(mobile: 8.0, tablet: 10.0, desktop: 12.0);
    final favBtn = r.value(mobile: 28.0, tablet: 32.0, desktop: 36.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          r.value(mobile: 16, tablet: 18, desktop: 20),
        ),
        border: Border.all(color: colorWithOpacity(_primary, 0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(Colors.black, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            r.value(mobile: 16, tablet: 18, desktop: 20),
          ),
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image ──────────────────────────────────────────────
              Stack(
                children: [
                  Container(
                    height: imageContainerHeight,
                    decoration: BoxDecoration(
                      color: colorWithOpacity(_primary, 0.06),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                          r.value(mobile: 16, tablet: 18, desktop: 20),
                        ),
                        topRight: Radius.circular(
                          r.value(mobile: 16, tablet: 18, desktop: 20),
                        ),
                      ),
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                            ? Image.network(
                                p.imageUrl!,
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    _placeholder(p, theme, imageSize),
                              )
                            : Image.asset(
                                'images/market_place/${p.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), "_")}.png',
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    _placeholder(p, theme, imageSize),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: favBtn,
                      height: favBtn,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorWithOpacity(Colors.black, 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          _fav ? Icons.favorite_rounded : Icons.favorite_border,
                          color: _fav ? Colors.redAccent : Colors.grey[400],
                          size: favBtn * 0.55,
                        ),
                        onPressed: () => setState(() => _fav = !_fav),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Info ───────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, pad, pad, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: nameSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Per ${p.unit}',
                        style: TextStyle(
                          fontSize: unitSize,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Rs ${p.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: priceSize,
                                color: _primary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _QtyRow(
                            qty: _qty,
                            iconSize: qtyIcon,
                            onDecrement: () => setState(() {
                              if (_qty > 1) _qty--;
                            }),
                            onIncrement: () => setState(() => _qty++),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 28,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: EdgeInsets.zero,
                            elevation: 4,
                            onSelected: (v) {
                              if (v == 'edit')
                                widget.onEdit();
                              else if (v == 'delete')
                                widget.onDelete();
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: _primary,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _placeholder(MarketProduct p, ThemeData theme, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorWithOpacity(_primary, 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          p.name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Qty stepper
// ─────────────────────────────────────────────────────────────────────────────

class _QtyRow extends StatelessWidget {
  final int qty;
  final double iconSize;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QtyRow({
    required this.qty,
    required this.iconSize,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final btnSize = iconSize + 12;
    return Container(
      decoration: BoxDecoration(
        color: colorWithOpacity(const Color(0xFF2E7D32), 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(
            icon: Icons.remove_rounded,
            size: iconSize,
            btnSize: btnSize,
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 20,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: iconSize,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ),
          _Btn(
            icon: Icons.add_rounded,
            size: iconSize,
            btnSize: btnSize,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final double size;
  final double btnSize;
  final VoidCallback onPressed;

  const _Btn({
    required this.icon,
    required this.size,
    required this.btnSize,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: btnSize,
      height: btnSize,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: size),
        color: const Color(0xFF2E7D32),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
