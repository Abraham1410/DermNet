import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skindisease/features/scan/presentation/scan_screen.dart';
import 'package:skindisease/features/dashboard/data/weather_service.dart';
import 'package:skindisease/features/info/presentation/pages/list_disease_page.dart';
import 'package:skindisease/features/info/presentation/pages/list_virus_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:skindisease/features/info/data/datasources/disease_local_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  IconData _getWeatherIcon(String weatherMain) {
    final w = weatherMain.toLowerCase();
    if (w.contains('clear')) return Icons.wb_sunny_rounded;
    if (w.contains('cloud')) return Icons.cloud_rounded;
    if (w.contains('rain')) return Icons.umbrella_rounded;
    if (w.contains('drizzle')) return Icons.grain_rounded;
    if (w.contains('thunder')) return Icons.thunderstorm_rounded;
    if (w.contains('snow')) return Icons.ac_unit_rounded;
    if (w.contains('mist') ||
        w.contains('fog') ||
        w.contains('haze') ||
        w.contains('smoke') ||
        w.contains('dust')) return Icons.blur_on_rounded;
    if (w.contains('tornado') || w.contains('squall')) return Icons.air_rounded;
    return Icons.cloud_rounded;
  }

  final WeatherService _weatherService = WeatherService();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String _cityName = 'Surabaya, Indonesia';
  double? _temperature;
  String _weatherDesc = '';
  bool _isLoadingWeather = true;

  // Daily skin tips
  final List<Map<String, String>> _skinTips = [
    {
      'tip':
          'Apply sunscreen with SPF 30+ every 2 hours when outdoors, even on cloudy days.',
      'icon': '☀️',
    },
    {
      'tip':
          'Drink at least 8 glasses of water daily to keep your skin hydrated and glowing.',
      'icon': '💧',
    },
    {
      'tip':
          'Clean your phone screen daily — it harbors bacteria that can cause acne.',
      'icon': '📱',
    },
    {
      'tip':
          'Change your pillowcase at least twice a week to prevent breakouts.',
      'icon': '🛏️',
    },
    {
      'tip':
          'Always remove makeup before sleeping to let your skin breathe and regenerate.',
      'icon': '🧴',
    },
  ];

  Map<String, String> get _todayTip {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year))
        .inDays;
    return _skinTips[dayOfYear % _skinTips.length];
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _loadWeather();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    setState(() => _isLoadingWeather = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location service is disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied forever');
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      String city = 'Unknown location';
      try {
        final placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          city = [
            if ((p.locality ?? '').isNotEmpty) p.locality,
            if ((p.country ?? '').isNotEmpty) p.country,
          ].join(', ');
        }
      } catch (_) {}

      final data = await _weatherService.getCurrentWeather(
        lat: pos.latitude,
        lon: pos.longitude,
      );

      setState(() {
        _temperature = (data['main']['temp'] as num).toDouble();
        _weatherDesc = (data['weather'][0]['main'] as String?) ?? '';
        _cityName = city.isNotEmpty
            ? city
            : ((data['name'] as String?) ?? _cityName);
        _isLoadingWeather = false;
      });
    } catch (e) {
      debugPrint('Error load weather: $e');
      setState(() => _isLoadingWeather = false);
    }
  }

  void _goToScan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F4E20);
    const softGreen = Color(0xFFE9F5EE);

    return Scaffold(
      backgroundColor: softGreen,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(primaryGreen),
                const SizedBox(height: 16),
                _buildWeatherCard(primaryGreen),
                const SizedBox(height: 16),
                _buildSkinTipCard(primaryGreen),
                const SizedBox(height: 16),
                _buildCategoryChips(),
                const SizedBox(height: 16),
                _buildCheckSkinCard(primaryGreen),
                const SizedBox(height: 24),
                _buildAllFeaturesTitle(),
                const SizedBox(height: 12),
                _buildAllFeaturesGrid(primaryGreen),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryGreen) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/header_bg.png',
                      fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.35),
                          primaryGreen.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your location',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.redAccent, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _cityName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              Colors.white.withOpacity(0.9),
                          child: Icon(Icons.person,
                              color: primaryGreen, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            color: Colors.grey.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search skin conditions...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                              ),
                              isCollapsed: true,
                            ),
                            style: GoogleFonts.poppins(fontSize: 13),
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
    );
  }

  Widget _buildWeatherCard(Color primaryGreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white,
              const Color(0xFFE8F5E9).withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _isLoadingWeather
                            ? '--°C'
                            : '${_temperature?.toStringAsFixed(0) ?? '--'}°C',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E3A2B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!_isLoadingWeather)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _weatherDesc,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        _cityName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryGreen.withOpacity(0.15),
                    const Color(0xFF81C784).withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                _isLoadingWeather
                    ? Icons.cloud_rounded
                    : _getWeatherIcon(_weatherDesc),
                size: 36,
                color: primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinTipCard(Color primaryGreen) {
    final tip = _todayTip;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryGreen,
              const Color(0xFF2E7D32),
              const Color(0xFF388E3C),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(tip['icon']!, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Skin Tip',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip['tip']!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final diseases = DiseaseLocalData.diseases;
    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: diseases.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final disease = diseases[index];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      disease.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.medical_services_rounded,
                        size: 22,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 60,
                  child: Text(
                    disease.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF344B41),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckSkinCard(Color primaryGreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/skin.png',
                width: 100,
                height: 130,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check your Skin',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A2B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Take photos, start diagnose diseases & get skin care tips.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _goToScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      shadowColor: primaryGreen.withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Diagnose',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllFeaturesTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF1F4E20),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'All Features',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E3A2B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllFeaturesGrid(Color primaryGreen) {
    final items = [
      _FeatureItem(
        title: 'Diagnose',
        subtitle: 'Check your Disease',
        icon: Icons.analytics_rounded,
        color: const Color(0xFF2E7D32),
        onTap: _goToScan,
      ),
      _FeatureItem(
        title: 'Identify',
        subtitle: 'Recognize your Skin',
        icon: Icons.search_rounded,
        color: const Color(0xFF1565C0),
        onTap: _goToScan,
      ),
      _FeatureItem(
        title: 'Pathogen Types',
        subtitle: 'Learn infection sources',
        icon: Icons.bug_report_rounded,
        color: const Color(0xFFE65100),
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ListVirusPage()));
        },
      ),
      _FeatureItem(
        title: 'Diseases',
        subtitle: 'Explore skin conditions',
        icon: Icons.healing_rounded,
        color: const Color(0xFF7B1FA2),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ListDiseasePage()));
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: item.onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        Icon(item.icon, size: 22, color: item.color),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A2B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
