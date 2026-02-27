import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../../services/market_service.dart';
import '../../models/market_product.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketService _marketService = MarketService();
  List<MarketProduct> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedQuality = 'All';
  String _selectedDistrict = 'All';
  String _sortBy = 'Latest';

  final List<String> _qualityFilters = ['All', 'Premium', 'Standard', 'Good'];
  final List<String> _sortOptions = [
    'Latest',
    'Price: Low to High',
    'Price: High to Low',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _marketService.fetchProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load products: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Convert products to map format for compatibility with existing UI
  List<Map<String, dynamic>> get _pepperListings {
    return _products.map((product) {
      return {
        'id': product.id,
        'image':
            product.imageUrl ??
            'https://images.unsplash.com/photo-1599940824399-b87987ceb72a?w=400',
        'district': 'Available',
        'price': product.price,
        'quality': 'Standard',
        'weight': 1.0, // Default weight for display
        'unit': product.unit,
        'seller': 'Vendor',
        'rating': 4.5,
        'description': product.name,
        'name': product.name,
      };
    }).toList();
  }

  // Mock marketplace data - backup data
  final List<Map<String, dynamic>> _mockPepperListings = [
    {
      'id': '1',
      'image':
          'https://images.unsplash.com/photo-1599940824399-b87987ceb72a?w=400',
      'district': 'Matale',
      'price': 1850.00,
      'quality': 'Premium',
      'weight': 50.0,
      'unit': 'kg',
      'seller': 'Farmer Nimal',
      'rating': 4.8,
      'description': 'High quality Ceylon black pepper',
    },
    {
      'id': '2',
      'image':
          'https://images.unsplash.com/photo-1606787364406-a3cdb98d2946?w=400',
      'district': 'Kandy',
      'price': 1650.00,
      'quality': 'Standard',
      'weight': 25.0,
      'unit': 'kg',
      'seller': 'Organic Farm Co.',
      'rating': 4.5,
      'description': 'Fresh harvest standard grade',
    },
    {
      'id': '3',
      'image':
          'https://images.unsplash.com/photo-1599940824399-b87987ceb72a?w=400',
      'district': 'Kurunegala',
      'price': 1950.00,
      'quality': 'Premium',
      'weight': 100.0,
      'unit': 'kg',
      'seller': 'Green Valley Farms',
      'rating': 4.9,
      'description': 'Export quality premium pepper',
    },
    {
      'id': '4',
      'image':
          'https://images.unsplash.com/photo-1606787364406-a3cdb98d2946?w=400',
      'district': 'Gampaha',
      'price': 1400.00,
      'quality': 'Good',
      'weight': 20.0,
      'unit': 'kg',
      'seller': 'Rural Farmers',
      'rating': 4.3,
      'description': 'Good quality locally sourced',
    },
    {
      'id': '5',
      'image':
          'https://images.unsplash.com/photo-1599940824399-b87987ceb72a?w=400',
      'district': 'Matale',
      'price': 1750.00,
      'quality': 'Standard',
      'weight': 75.0,
      'unit': 'kg',
      'seller': 'Highland Pepper',
      'rating': 4.6,
      'description': 'Mountain grown standard grade',
    },
    {
      'id': '6',
      'image':
          'https://images.unsplash.com/photo-1606787364406-a3cdb98d2946?w=400',
      'district': 'Kandy',
      'price': 2100.00,
      'quality': 'Premium',
      'weight': 50.0,
      'unit': 'kg',
      'seller': 'Premium Spices Ltd',
      'rating': 4.9,
      'description': 'Certified organic premium',
    },
  ];

  List<Map<String, dynamic>> get _filteredListings {
    List<Map<String, dynamic>> filtered = List.from(_pepperListings);

    // Filter by quality
    if (_selectedQuality != 'All') {
      filtered = filtered
          .where((item) => item['quality'] == _selectedQuality)
          .toList();
    }

    // Filter by district
    if (_selectedDistrict != 'All') {
      filtered = filtered
          .where((item) => item['district'] == _selectedDistrict)
          .toList();
    }

    // Sort
    if (_sortBy == 'Price: Low to High') {
      filtered.sort((a, b) => a['price'].compareTo(b['price']));
    } else if (_sortBy == 'Price: High to Low') {
      filtered.sort((a, b) => b['price'].compareTo(a['price']));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final primary = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        title: Text(
          'Pepper Marketplace',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: responsive.titleFontSize,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProducts,
            tooltip: 'Refresh products',
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () =>
                _showFilterBottomSheet(context, responsive, primary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(responsive, primary),

          // Listings count
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.pagePadding,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredListings.length} Listings Available',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                PopupMenuButton<String>(
                  child: Row(
                    children: [
                      Text(
                        _sortBy,
                        style: TextStyle(
                          fontSize: responsive.fontSize(
                            mobile: 13,
                            tablet: 14,
                            desktop: 15,
                          ),
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: primary, size: 20),
                    ],
                  ),
                  onSelected: (value) {
                    setState(() {
                      _sortBy = value;
                    });
                  },
                  itemBuilder: (context) => _sortOptions
                      .map(
                        (option) =>
                            PopupMenuItem(value: option, child: Text(option)),
                      )
                      .toList(),
                ),
              ],
            ),
          ),

          // Listings grid
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: primary),
                        const SizedBox(height: 16),
                        Text(
                          'Loading marketplace...',
                          style: TextStyle(
                            fontSize: responsive.bodyFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: responsive.bodyFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadProducts,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredListings.isEmpty
                ? _buildEmptyState(responsive, primary)
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: GridView.builder(
                      padding: EdgeInsets.all(responsive.pagePadding),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: responsive
                            .value(mobile: 1, tablet: 2, desktop: 3)
                            .toInt(),
                        childAspectRatio: responsive
                            .value(mobile: 0.85, tablet: 0.9, desktop: 0.85)
                            .toDouble(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _filteredListings.length,
                      itemBuilder: (context, index) {
                        return _buildPepperCard(
                          responsive,
                          primary,
                          _filteredListings[index],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create listing
        },
        backgroundColor: primary,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Sell Pepper',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: responsive.bodyFontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(Responsive responsive, Color primary) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.pagePadding,
        vertical: 12,
      ),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ..._qualityFilters.map((quality) {
              final isSelected = _selectedQuality == quality;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(quality),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedQuality = quality;
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: isSelected ? primary : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: responsive.fontSize(
                      mobile: 13,
                      tablet: 14,
                      desktop: 15,
                    ),
                  ),
                  checkmarkColor: primary,
                  side: BorderSide(
                    color: isSelected ? primary : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPepperCard(
    Responsive responsive,
    Color primary,
    Map<String, dynamic> listing,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to detail page
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Image.network(
                      listing['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            size: 50,
                            color: Colors.grey[500],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getQualityColor(listing['quality']),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      listing['quality'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          listing['district'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and weight
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rs ${listing['price'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: responsive.titleFontSize,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                          Text(
                            'per kg',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.scale_rounded,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${listing['weight']} ${listing['unit']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    listing['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // Seller info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: primary.withOpacity(0.1),
                        child: Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          listing['seller'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        listing['rating'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Responsive responsive, Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No listings found',
            style: TextStyle(
              fontSize: responsive.titleFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'Premium':
        return const Color(0xFF1B5E20);
      case 'Standard':
        return const Color(0xFF2E7D32);
      case 'Good':
        return const Color(0xFF43A047);
      default:
        return Colors.grey;
    }
  }

  void _showFilterBottomSheet(
    BuildContext context,
    Responsive responsive,
    Color primary,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: responsive.headingFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedQuality = 'All';
                            _selectedDistrict = 'All';
                          });
                          setState(() {});
                        },
                        child: Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'District',
                    style: TextStyle(
                      fontSize: responsive.bodyFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        ['All', 'Matale', 'Kandy', 'Kurunegala', 'Gampaha'].map(
                          (district) {
                            final isSelected = _selectedDistrict == district;
                            return ChoiceChip(
                              label: Text(district),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedDistrict = district;
                                });
                                setState(() {});
                              },
                              selectedColor: primary.withOpacity(0.15),
                              labelStyle: TextStyle(
                                color: isSelected ? primary : Colors.grey[700],
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                              side: BorderSide(
                                color: isSelected ? primary : Colors.grey[300]!,
                              ),
                            );
                          },
                        ).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: responsive.bodyFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
