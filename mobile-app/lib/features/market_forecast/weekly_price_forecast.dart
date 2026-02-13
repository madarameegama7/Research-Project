import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../utils/responsive.dart';
import 'weekly_prediction.dart';
import 'package:intl/intl.dart';

class WeeklyPriceForecast extends StatefulWidget {
  const WeeklyPriceForecast({Key? key}) : super(key: key);

  @override
  State<WeeklyPriceForecast> createState() => _WeeklyPriceForecastState();
}

class _WeeklyPriceForecastState extends State<WeeklyPriceForecast>
    with SingleTickerProviderStateMixin {
  final Color primary = const Color(0xFF2E7D32);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Dropdown values
  String? selectedDistrict;
  String? selectedPepperType;
  String? selectedGrade;

  // Visibility toggles
  bool showWeekDetails = false;
  bool showWeatherDetails = false;

  // Loading states
  bool isLoadingWeekDetails = false;
  bool isLoadingWeatherDetails = false;

  // Auto-calculated next week values
  late String nextWeekMonth;
  late int nextWeekNumber;
  late String nextWeekYear;
  late String weekDateRange;

  // Sample dropdown options
  final List<String> districts = [
    'Badulla',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kurunegala',
    'Matale',
    'Matara',
    'Monaragala',
    'Nuwara Eliya',
    'Ratnapura',
  ];
  final List<String> pepperTypes = ['Black', 'White'];
  final List<String> grades = ['Grade 1', 'Grade 2', 'Grade 3'];

  // Month names for mapping
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  bool showErrors = false; // To control error message visibility

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  // Calculate next week's date
  void _calculateNextWeek() {
    DateTime today = DateTime.now();
    DateTime nextWeek = today.add(const Duration(days: 7));

    // Get month name
    nextWeekMonth = months[nextWeek.month - 1];

    // Calculate week number
    nextWeekNumber = _getWeekNumber(nextWeek);

    // Get year
    nextWeekYear = nextWeek.year.toString();

    // Calculate date range
    weekDateRange = _getWeekDateRange(nextWeek);
  }

  // Calculate ISO week number
  int _getWeekNumber(DateTime date) {
    final dayOfWeek = date.weekday;
    final ordinalDayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((ordinalDayOfYear - dayOfWeek + 10) / 7).floor();
  }

  @override
  void initState() {
    super.initState();

    // Calculate next week's date automatically
    _calculateNextWeek();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    // Remove any open overlay to avoid leaking visual elements when disposed
    _overlayEntry?.remove();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Weekly Price Forecast'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                // ---------- DESCRIPTION CARD ----------
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.pagePadding,
                  ),
                  child: _buildDescriptionCard(responsive),
                ),

                ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                // ---------- DROPDOWNS ----------
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.pagePadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDropdownField(
                        "District",
                        selectedDistrict,
                        districts,
                        (val) => setState(() => selectedDistrict = val),
                        required: true,
                      ),
                      ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                      _buildDropdownField(
                        "Pepper Type",
                        selectedPepperType,
                        pepperTypes,
                        (val) => setState(() => selectedPepperType = val),
                        required: true,
                      ),
                      ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                      _buildDropdownField(
                        "Grade",
                        selectedGrade,
                        grades,
                        (val) => setState(() => selectedGrade = val),
                      ),
                      ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),

                      // ---------- WEEK DETAILS SECTION ----------
                      _buildWeekDetailsSection(responsive),

                      ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),
                    ],
                  ),
                ),

                _buildWeatherSection(responsive),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.pagePadding,
                  ),
                  child: Column(
                    children: [
                      ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                      Center(
                        child: SizedBox(
                          width:
                              MediaQuery.of(context).size.width *
                              0.6, // 60% width
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                showErrors = true; // enable error messages
                              });

                              // Check required fields
                              if (selectedDistrict == null ||
                                  selectedPepperType == null) {
                                return; // stop navigation
                              }

                              // All good → navigate with calculated week data
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WeeklyPrediction(
                                    year: nextWeekYear,
                                    month: nextWeekMonth,
                                    week: weekDateRange,
                                  ),
                                ),
                              );
                            },

                            child: const Text(
                              'Predict the Price',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      ResponsiveSpacing(mobile: 32, tablet: 36, desktop: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(Responsive responsive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFC8E6C9), const Color(0xFFA5D6A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.black87,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Price Forecast',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Predict price trends for the upcoming week. Select your district and pepper type to receive weekly price forecast.',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize - 1,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextWeekCard(Responsive responsive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.cyan.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Predicting Price For',
            style: TextStyle(
              fontSize: responsive.bodyFontSize - 0.5,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Center(
              child: Text(
                weekDateRange,
                style: TextStyle(
                  fontSize: responsive.bodyFontSize + 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue.shade600, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Get price predictions for this week period',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize - 1.5,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getWeekDateRange(DateTime date) {
    // Get the Monday of the week (start of week)
    DateTime monday = date.subtract(Duration(days: date.weekday - 1));
    // Get the Sunday of the week (end of week)
    DateTime sunday = monday.add(const Duration(days: 6));

    // Format the date range
    String startDate = DateFormat('MMM dd').format(monday);
    String endDate = DateFormat('MMM dd, yyyy').format(sunday);

    return '$startDate - $endDate';
  }

  Widget _buildFetchButton({
    required bool isLoading,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: isLoading ? 0 : 3,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CupertinoActivityIndicator(color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Loading',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : const Text(
                  key: ValueKey('fetch'),
                  'Fetch Details',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Widget _buildWeekDetailsSection(Responsive responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Week Details',
          style: TextStyle(
            fontSize: responsive.bodyFontSize - 0.5,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
        if (!showWeekDetails)
          Center(
            child: _buildFetchButton(
              isLoading: isLoadingWeekDetails,
              onPressed: () async {
                setState(() {
                  isLoadingWeekDetails = true;
                });
                // Simulate API call delay
                await Future.delayed(const Duration(milliseconds: 1500));
                setState(() {
                  isLoadingWeekDetails = false;
                  showWeekDetails = true;
                });
              },
              color: Colors.green.shade700,
            ),
          ),
        if (showWeekDetails) ...[_buildNextWeekCard(responsive)],
      ],
    );
  }

  Widget _buildWeatherSection(Responsive responsive) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather Conditions',
            style: TextStyle(
              fontSize: responsive.bodyFontSize - 0.5,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
          if (!showWeatherDetails)
            Center(
              child: _buildFetchButton(
                isLoading: isLoadingWeatherDetails,
                onPressed: () async {
                  setState(() {
                    isLoadingWeatherDetails = true;
                  });
                  // Simulate API call delay
                  await Future.delayed(const Duration(milliseconds: 1500));
                  setState(() {
                    isLoadingWeatherDetails = false;
                    showWeatherDetails = true;
                  });
                },
                color: Colors.green.shade700,
              ),
            ),
          if (showWeatherDetails) ...[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.cyan.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(
                  responsive.value(mobile: 16, tablet: 20, desktop: 24),
                ),
                border: Border.all(color: Colors.blue.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  responsive.value(mobile: 6, tablet: 8, desktop: 10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weather Grid - 2x2
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      // Increase aspect ratio (width/height) to reduce card height
                      childAspectRatio: responsive.value(
                        mobile: 1.4,
                        tablet: 1.6,
                        desktop: 1.8,
                      ),
                      children: [
                        _buildEnhancedWeatherCard(
                          icon: Icons.opacity,
                          iconColor: Colors.blue,
                          label: "Rainfall",
                          value: "120",
                          unit: "mm",
                          responsive: responsive,
                          description: "Moderate Rain",
                        ),
                        _buildEnhancedWeatherCard(
                          icon: Icons.thermostat,
                          iconColor: Colors.orange,
                          label: "Temperature",
                          value: "29",
                          unit: "°C",
                          responsive: responsive,
                          description: "Warm",
                        ),
                        _buildEnhancedWeatherCard(
                          icon: Icons.water_drop,
                          iconColor: Colors.cyan,
                          label: "Humidity",
                          value: "78",
                          unit: "%",
                          responsive: responsive,
                          description: "High Moisture",
                        ),
                        _buildEnhancedWeatherCard(
                          icon: Icons.air,
                          iconColor: Colors.teal,
                          label: "Wind Speed",
                          value: "12",
                          unit: "km/h",
                          responsive: responsive,
                          description: "Light Breeze",
                        ),
                      ],
                    ),
                    ResponsiveSpacing(mobile: 8, tablet: 10, desktop: 12),
                    // Weather Summary Card
                    Container(
                      padding: EdgeInsets.all(
                        responsive.value(mobile: 8, tablet: 10, desktop: 12),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade600,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Good conditions for crop growth. Expect moderate rainfall with warm temperatures.",
                              style: TextStyle(
                                fontSize: responsive.bodyFontSize - 1.5,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
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
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String title,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) {
    final key = GlobalKey();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),

        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: key,
            onTap: () => _toggleDropdown(key, items, value, onChanged),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (showErrors && required && value == null)
                      ? Colors.red
                      : Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value ?? 'Select $title',
                    style: TextStyle(
                      color: value == null
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded),
                ],
              ),
            ),
          ),
        ),

        if (showErrors && required && value == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              "$title is required",
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildEnhancedWeatherCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required Responsive responsive,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 16, tablet: 18, desktop: 20),
        ),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(
          responsive.value(mobile: 10, tablet: 12, desktop: 14),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, iconColor.withOpacity(0.03)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(
            responsive.value(mobile: 16, tablet: 18, desktop: 20),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: responsive.value(mobile: 20, tablet: 24, desktop: 28),
              ),
            ),
            const SizedBox(height: 6),
            // Value and Unit
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: responsive.fontSize(
                            mobile: 20,
                            tablet: 24,
                            desktop: 28,
                          ),
                          fontWeight: FontWeight.w700,
                          color: iconColor,
                        ),
                      ),
                      TextSpan(
                        text: unit,
                        style: TextStyle(
                          fontSize: responsive.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize - 2,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize - 3,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDropdown(
    GlobalKey key,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      return;
    }

    // Height of a single item
    const double itemHeight = 48.0;
    // Show max 3 items; scroll if more
    final double dropdownHeight = items.length > 3
        ? itemHeight * 3
        : itemHeight * items.length;

    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: size.width,
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: dropdownHeight),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: items
                  .map(
                    (item) => SizedBox(
                      height: itemHeight,
                      child: ListTile(
                        title: Text(item),
                        onTap: () {
                          onChanged(item);
                          _overlayEntry!.remove();
                          _overlayEntry = null;
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }
}
