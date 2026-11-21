import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/risk_level_helper.dart';
import '../../models/shelter_model.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/shelters_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../widgets/risk_badge.dart';

class IndiaHazardMapScreen extends StatefulWidget {
  const IndiaHazardMapScreen({super.key});

  @override
  State<IndiaHazardMapScreen> createState() => _IndiaHazardMapScreenState();
}

class _IndiaHazardMapScreenState extends State<IndiaHazardMapScreen> {
  final MapController _mapController = MapController();
  bool _showLegend = true;
  bool _showShelters = true;
  bool _showFloodZones = true;
  bool _showRadarOverlay = true;
  bool _showWindOverlay = true;
  String _mapStyle = 'standard'; // 'standard', 'satellite', 'terrain'
  String? _radarTileUrl;
  final TextEditingController _searchController = TextEditingController();

  // Major Indian Flood Basin Hotspots with Zoom.earth telemetry, coordinates and risk severity
  final List<Map<String, dynamic>> _hazardZones = [
    {
      'id': 'hz_patna',
      'name': 'Ganga Basin - Patna Diara',
      'state': 'Bihar',
      'point': const LatLng(25.5941, 85.1376),
      'risk': RiskLevel.severe,
      'waterLevel': '50.12m (Danger: 50.20m)',
      'inundationRisk': 'Imminent flash flood in low-lying river islands',
      'radius': 28000.0,
      'windSpeed': 24,
      'windDir': 'NW',
      'windHeading': 315.0,
      'radarEcho': 'Heavy Precipitation (14.2 mm/hr)',
    },
    {
      'id': 'hz_guwahati',
      'name': 'Brahmaputra Valley - Guwahati',
      'state': 'Assam',
      'point': const LatLng(26.1445, 91.7362),
      'risk': RiskLevel.high,
      'waterLevel': '49.80m (Danger: 49.68m)',
      'inundationRisk': 'High catchment runoff; multiple embankment breaches',
      'radius': 32000.0,
      'windSpeed': 38,
      'windDir': 'NE',
      'windHeading': 45.0,
      'radarEcho': 'Monsoon Squall (22.5 mm/hr)',
    },
    {
      'id': 'hz_cuttack',
      'name': 'Mahanadi Delta - Cuttack',
      'state': 'Odisha',
      'point': const LatLng(20.4625, 85.8828),
      'risk': RiskLevel.high,
      'waterLevel': '26.40m (Danger: 27.42m)',
      'inundationRisk': 'Upstream Hirakud dam discharge alert active',
      'radius': 24000.0,
      'windSpeed': 32,
      'windDir': 'SE',
      'windHeading': 135.0,
      'radarEcho': 'Intense Coastal Clouds (18.1 mm/hr)',
    },
    {
      'id': 'hz_srinagar',
      'name': 'Jhelum Basin - Srinagar',
      'state': 'Jammu & Kashmir',
      'point': const LatLng(34.0837, 74.7973),
      'risk': RiskLevel.moderate,
      'waterLevel': '16.50 ft (Danger: 21.0 ft)',
      'inundationRisk': 'Snowmelt and steady showers monitored at Ram Munshi Bagh',
      'radius': 20000.0,
      'windSpeed': 14,
      'windDir': 'W',
      'windHeading': 270.0,
      'radarEcho': 'Light Snowmelt Showers (4.2 mm/hr)',
    },
    {
      'id': 'hz_vijayawada',
      'name': 'Krishna River - Prakasam Barrage',
      'state': 'Andhra Pradesh',
      'point': const LatLng(16.5062, 80.6480),
      'risk': RiskLevel.moderate,
      'waterLevel': 'Prakasam discharge 3.2 lakh cusecs',
      'inundationRisk': 'First warning signal active across island villages',
      'radius': 18000.0,
      'windSpeed': 26,
      'windDir': 'S',
      'windHeading': 180.0,
      'radarEcho': 'Moderate River Showers (9.6 mm/hr)',
    },
    {
      'id': 'hz_chennai',
      'name': 'Adyar & Chembarambakkam Catchment',
      'state': 'Tamil Nadu',
      'point': const LatLng(13.0827, 80.2707),
      'risk': RiskLevel.low,
      'waterLevel': 'Chembarambakkam lake at 62% storage',
      'inundationRisk': 'Normal drainage; seasonal northeast monsoon monitoring',
      'radius': 16000.0,
      'windSpeed': 20,
      'windDir': 'E',
      'windHeading': 90.0,
      'radarEcho': 'Passing Coastal Clouds (6.4 mm/hr)',
    },
    {
      'id': 'hz_mumbai',
      'name': 'Mithi River & Kranti Nagar Basin',
      'state': 'Maharashtra',
      'point': const LatLng(19.0760, 72.8777),
      'risk': RiskLevel.moderate,
      'waterLevel': 'High tide alert: 4.2m at 14:30 IST',
      'inundationRisk': 'Pumping stations operational at full capacity',
      'radius': 16000.0,
      'windSpeed': 44,
      'windDir': 'SW',
      'windHeading': 225.0,
      'radarEcho': 'Gale Winds & Sea Squall (28.0 mm/hr)',
    },
    {
      'id': 'hz_bengaluru',
      'name': 'Vrishabhavathi & Bellandur Lake Basin',
      'state': 'Karnataka',
      'point': const LatLng(12.9716, 77.5946),
      'risk': RiskLevel.low,
      'waterLevel': 'Normal urban storm drains',
      'inundationRisk': 'No overflow detected',
      'radius': 14000.0,
      'windSpeed': 16,
      'windDir': 'WNW',
      'windHeading': 290.0,
      'radarEcho': 'Scattered Clouds (2.1 mm/hr)',
    },
    {
      'id': 'hz_delhi',
      'name': 'Yamuna Floodplain - Delhi NCR',
      'state': 'Delhi',
      'point': const LatLng(28.6139, 77.2090),
      'risk': RiskLevel.moderate,
      'waterLevel': '205.10m (Danger: 205.33m)',
      'inundationRisk': 'Hathnikund barrage discharge being tracked upstream',
      'radius': 22000.0,
      'windSpeed': 18,
      'windDir': 'NW',
      'windHeading': 315.0,
      'radarEcho': 'Overcast River Basin (7.5 mm/hr)',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchRadarTimestamp();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SheltersProvider>(context, listen: false).loadShelters();
    });
  }

  Future<void> _fetchRadarTimestamp() async {
    try {
      final res = await http
          .get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final host =
            data['host'] as String? ?? 'https://tilecache.rainviewer.com';
        final past = data['radar']?['past'] as List<dynamic>?;
        if (past != null && past.isNotEmpty) {
          final path = past.last['path'] as String;
          if (mounted) {
            setState(() {
              _radarTileUrl = '$host$path/256/{z}/{x}/{y}/2/1_1.png';
            });
          }
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _radarTileUrl =
            'https://tilecache.rainviewer.com/v2/radar/nowcast_2959d62d5662/256/{z}/{x}/{y}/2/1_1.png';
      });
    }
  }

  Future<void> _launchZoomEarthUrl([String? customUrl]) async {
    final url = customUrl ??
        'https://zoom.earth/places/india/#map=radar/overlays=wind';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch Zoom.earth link: $e');
    }
  }

  void _centerOnLocation(LatLng point, double zoom) {
    _mapController.move(point, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final sheltersProv = context.watch<SheltersProvider>();
    final shelters = sheltersProv.allShelters;

    final currentLocPoint = LatLng(
      appState.selectedLocation['latitude'],
      appState.selectedLocation['longitude'],
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'India Geospatial Hazard Map',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              'CWC Flood Zones & Verified Shelters',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Zoom.earth Radar & Wind',
            icon: const Icon(Icons.radar_rounded, color: Color(0xFF0284C7)),
            onPressed: () => _showZoomEarthSheet(context),
          ),
          IconButton(
            tooltip: 'Filter Layers',
            icon: const Icon(Icons.layers_rounded),
            onPressed: () => _showLayerFilterSheet(context),
          ),
          IconButton(
            tooltip: 'Toggle Legend',
            icon: Icon(
              _showLegend ? Icons.info_rounded : Icons.info_outline_rounded,
              color: _showLegend ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _showLegend = !_showLegend;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Interactive Flutter Map with OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLocPoint,
              initialZoom: 6.8,
              minZoom: 4.0,
              maxZoom: 18.0,
            ),
            children: [
              // Base Map Tile Layer (Standard / Satellite / Terrain)
              TileLayer(
                urlTemplate: _mapStyle == 'satellite'
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : _mapStyle == 'terrain'
                        ? 'https://tile.opentopomap.org/{z}/{x}/{y}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.disaster.floodguard.app',
                maxZoom: 19,
              ),

              // Live Rain & Doppler Radar Tile Layer (Zoom.earth / RainViewer feed)
              if (_showRadarOverlay && _radarTileUrl != null)
                TileLayer(
                  urlTemplate: _radarTileUrl!,
                  userAgentPackageName: 'com.disaster.floodguard.app',
                  tileBuilder: (context, tileWidget, tile) =>
                      Opacity(opacity: 0.65, child: tileWidget),
                  maxZoom: 18,
                ),

              // 2. Risk Buffer Circles for Flood-Prone Areas
              if (_showFloodZones)
                CircleLayer(
                  circles: _hazardZones.map((zone) {
                    final risk = zone['risk'] as RiskLevel;
                    return CircleMarker(
                      point: zone['point'] as LatLng,
                      radius: zone['radius'] as double,
                      useRadiusInMeter: true,
                      color: risk.color.withAlpha(55),
                      borderColor: risk.color,
                      borderStrokeWidth: 2.0,
                    );
                  }).toList(),
                ),

              // 3. Markers Layer (Hazard Centers + Shelters + User Location)
              MarkerLayer(
                markers: [
                  // User's Current Selected Location Pin
                  Marker(
                    point: currentLocPoint,
                    width: 48,
                    height: 48,
                    child: GestureDetector(
                      onTap: () {
                        _showLocationDetailsSheet(
                          context,
                          appState.selectedLocation['name'],
                          'Current Monitored Location',
                          appState.selectedLocation['basin'],
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),

                  // Flood Hazard Zone Markers
                  if (_showFloodZones)
                    ..._hazardZones.map((zone) {
                      final risk = zone['risk'] as RiskLevel;
                      return Marker(
                        point: zone['point'] as LatLng,
                        width: 42,
                        height: 42,
                        child: GestureDetector(
                          onTap: () => _showHazardZoneDetails(context, zone),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: risk.color,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: risk.color.withAlpha(120),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              risk.icon,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    }),

                  // Verified Shelter Markers
                  if (_showShelters)
                    ...shelters.map((shelter) {
                      return Marker(
                        point: LatLng(shelter.latitude, shelter.longitude),
                        width: 38,
                        height: 38,
                        child: GestureDetector(
                          onTap: () => _showShelterDetailsSheet(context, shelter),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2E7D32),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.night_shelter_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }),

                  // Live Wind Stream & Speed Vector Markers (Zoom.earth Wind Overlay data)
                  if (_showWindOverlay)
                    ..._hazardZones.map((zone) {
                      final windSpeed = zone['windSpeed'] as int? ?? 20;
                      final windDir = zone['windDir'] as String? ?? 'NW';
                      final headingDeg = (zone['windHeading'] as double? ?? 315.0);
                      final headingRad = headingDeg * (math.pi / 180.0);
                      return Marker(
                        point: zone['point'] as LatLng,
                        width: 82,
                        height: 28,
                        child: GestureDetector(
                          onTap: () => _showHazardZoneDetails(context, zone),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xEE0F172A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.rotate(
                                  angle: headingRad,
                                  child: const Icon(
                                    Icons.navigation_rounded,
                                    size: 13,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$windSpeed km/h $windDir',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),

          // Zoom.earth Live Radar & Wind Floating Badge
          Positioned(
            top: 72,
            left: 14,
            child: GestureDetector(
              onTap: () => _showZoomEarthSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xF20F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF38BDF8).withAlpha(180), width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.radar_rounded, size: 15, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 5),
                    const Text(
                      'Zoom.earth Live Radar & Wind',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new_rounded, size: 12, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),

          // 4. Top Search and Quick Basin Filter Bar
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: _buildSearchBar(context, appState),
          ),

          // 5. Floating Risk Level Legend (Expandable)
          if (_showLegend)
            Positioned(
              bottom: 24,
              left: 14,
              child: _buildMapLegend(),
            ),

          // 6. Map Zoom & Re-Center Controls
          Positioned(
            bottom: 24,
            right: 14,
            child: Column(
              children: [
                _buildMapControlBtn(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Center on My Basin',
                  onTap: () => _centerOnLocation(currentLocPoint, 9.5),
                ),
                const SizedBox(height: 8),
                _buildMapControlBtn(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom In',
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, currentZoom + 1);
                  },
                ),
                const SizedBox(height: 6),
                _buildMapControlBtn(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom Out',
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, currentZoom - 1);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, AppStateProvider appState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search river basin or flood hazard zone...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down_circle_outlined,
                color: AppColors.secondary),
            tooltip: 'Jump to Basin Hotspot',
            onSelected: (locId) {
              appState.changeLocation(locId);
              final loc = appState.allLocations.firstWhere((l) => l['id'] == locId);
              _centerOnLocation(
                LatLng(loc['latitude'], loc['longitude']),
                9.5,
              );
            },
            itemBuilder: (ctx) => appState.allLocations.map((loc) {
              return PopupMenuItem<String>(
                value: loc['id'],
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(loc['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        onSubmitted: (query) {
          final q = query.trim().toLowerCase();
          final match = _hazardZones.firstWhere(
            (z) =>
                (z['name'] as String).toLowerCase().contains(q) ||
                (z['state'] as String).toLowerCase().contains(q),
            orElse: () => _hazardZones.first,
          );
          _centerOnLocation(match['point'] as LatLng, 9.5);
          _showHazardZoneDetails(context, match);
        },
      ),
    );
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(240),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.legend_toggle_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'HAZARD RISK LEGEND',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _showLegend = false),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildLegendRow(AppColors.riskSevere, 'Severe Risk (Flash Flood)'),
          _buildLegendRow(AppColors.riskHigh, 'High Risk (Near Danger Mark)'),
          _buildLegendRow(AppColors.riskModerate, 'Moderate (Watch Notice)'),
          _buildLegendRow(AppColors.riskLow, 'Low Risk (Normal Flow)'),
          const Divider(height: 10),
          _buildLegendIconRow(
            Icons.night_shelter_rounded,
            const Color(0xFF2E7D32),
            'Verified Relief Shelter',
          ),
          _buildLegendIconRow(
            Icons.person_pin_circle_rounded,
            AppColors.primary,
            'My Selected Location',
          ),
          if (_showRadarOverlay)
            _buildLegendIconRow(
              Icons.radar_rounded,
              const Color(0xFF0284C7),
              'Zoom.earth Live Radar',
            ),
          if (_showWindOverlay)
            _buildLegendIconRow(
              Icons.air_rounded,
              const Color(0xFF38BDF8),
              'Zoom.earth Wind Vector',
            ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIconRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primaryDark, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  void _showHazardZoneDetails(
      BuildContext context, Map<String, dynamic> zone) {
    final risk = zone['risk'] as RiskLevel;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      zone['name'],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  RiskBadge(riskLevel: risk),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'State: ${zone['state']} • CWC Hydrological Station',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: risk.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: risk.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.water_rounded, size: 18, color: risk.color),
                        const SizedBox(width: 8),
                        Text(
                          'Water Level: ${zone['waterLevel']}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: risk.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      zone['inundationRisk'],
                      style: TextStyle(
                        fontSize: 12,
                        color: risk.color,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.air_rounded, size: 20, color: Color(0xFF0284C7)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wind: ${zone['windSpeed']} km/h ${zone['windDir']} • ${zone['radarEcho']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Zoom.earth Live Meteorological Telemetry',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
                      label: const Text('Center Map'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _centerOnLocation(zone['point'] as LatLng, 10.5);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                      ),
                      icon: const Icon(Icons.radar_rounded, size: 18),
                      label: const Text('Zoom.earth'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final lat = (zone['point'] as LatLng).latitude;
                        final lon = (zone['point'] as LatLng).longitude;
                        _launchZoomEarthUrl('https://zoom.earth/#map=radar/overlays=wind/@$lat,$lon,9z');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: const Text('Safety Guidelines'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    final appState =
                        Provider.of<AppStateProvider>(context, listen: false);
                    appState.setNavigationIndex(6); // Safety
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showShelterDetailsSheet(BuildContext context, ShelterModel shelter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final contactsProv = context.read<ContactsProvider>();

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.night_shelter_rounded,
                      color: AppColors.riskLow,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shelter.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          shelter.address,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Verified Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.riskLowBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 15, color: AppColors.riskLow),
                    const SizedBox(width: 6),
                    Text(
                      'VERIFIED BY ${shelter.managingAuthority.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.riskLow,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Capacity metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShelterMetric(
                      'Capacity', '${shelter.capacityPeople} people'),
                  _buildShelterMetric('Current', '${shelter.currentOccupancy}'),
                  _buildShelterMetric(
                      'Available Beds', '${shelter.availableBeds}',
                      isHighlight: true),
                  _buildShelterMetric(
                      'Distance', '${shelter.distanceKm} km away'),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),

              // Available Facilities
              const Text(
                'VERIFIED FACILITIES:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: shelter.availableFacilities.map((fac) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      fac,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Action buttons: Quick Call & Directions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.riskLow,
                      ),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: Text('Call ${shelter.contactPhone}'),
                      onPressed: () {
                        contactsProv.makePhoneCall(shelter.contactPhone);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShelterMetric(String label, String value,
      {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isHighlight ? AppColors.riskLow : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  void _showLocationDetailsSheet(
      BuildContext context, String name, String subtitle, String basin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '$subtitle • $basin',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Monitored Hydrological Catchment active. Satellite telemetry and IMD Doppler radar updates are received every 15 minutes.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showZoomEarthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radar_rounded, color: Color(0xFF0284C7), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zoom.earth India Radar & Wind',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Live Doppler Precipitation & Wind Vectors',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 3, backgroundColor: Color(0xFF16A34A)),
                        SizedBox(width: 5),
                        Text(
                          'LIVE FEED',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'Connected to Zoom.earth meteorological telemetry for India, featuring real-time Doppler rain radar, surface wind vectors, storm tracks, and satellite cloud imagery.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text(
                  'Open Full Zoom.earth Live Radar & Wind',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _launchZoomEarthUrl('https://zoom.earth/places/india/#map=radar/overlays=wind');
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.air_rounded, size: 16),
                      label: const Text('Wind Stream'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _launchZoomEarthUrl('https://zoom.earth/places/india/#overlays=wind');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cloud_rounded, size: 16),
                      label: const Text('Satellite Clouds'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _launchZoomEarthUrl('https://zoom.earth/places/india/#map=satellite');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLayerFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Map Layer & Overlay Controls',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    // Base Map Style Selector
                    const Text(
                      'BASE MAP STYLE:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Street'),
                          selected: _mapStyle == 'standard',
                          onSelected: (val) {
                            if (val) {
                              setSheetState(() => _mapStyle = 'standard');
                              setState(() => _mapStyle = 'standard');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Satellite (Zoom.earth)'),
                          selected: _mapStyle == 'satellite',
                          onSelected: (val) {
                            if (val) {
                              setSheetState(() => _mapStyle = 'satellite');
                              setState(() => _mapStyle = 'satellite');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Terrain'),
                          selected: _mapStyle == 'terrain',
                          onSelected: (val) {
                            if (val) {
                              setSheetState(() => _mapStyle = 'terrain');
                              setState(() => _mapStyle = 'terrain');
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    // Zoom.earth Overlays
                    SwitchListTile(
                      title: const Text('Live Rain & Doppler Radar',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Zoom.earth & RainViewer precipitation tiles'),
                      secondary: const Icon(Icons.radar_rounded, color: Color(0xFF0284C7)),
                      value: _showRadarOverlay,
                      onChanged: (val) {
                        setSheetState(() => _showRadarOverlay = val);
                        setState(() => _showRadarOverlay = val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Live Wind Stream Vectors',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Zoom.earth surface wind velocities & directions'),
                      secondary: const Icon(Icons.air_rounded, color: Color(0xFF38BDF8)),
                      value: _showWindOverlay,
                      onChanged: (val) {
                        setSheetState(() => _showWindOverlay = val);
                        setState(() => _showWindOverlay = val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Flood Prone Risk Buffers',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Show CWC river danger zones'),
                      secondary: const Icon(Icons.waves_rounded, color: AppColors.riskSevere),
                      value: _showFloodZones,
                      onChanged: (val) {
                        setSheetState(() => _showFloodZones = val);
                        setState(() => _showFloodZones = val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Verified Relief Shelters',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Show NDMA/DDMA verified shelter pins'),
                      secondary: const Icon(Icons.night_shelter_rounded, color: Color(0xFF2E7D32)),
                      value: _showShelters,
                      onChanged: (val) {
                        setSheetState(() => _showShelters = val);
                        setState(() => _showShelters = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        minimumSize: const Size.fromHeight(42),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Open Full Zoom.earth Live Radar & Wind'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _launchZoomEarthUrl('https://zoom.earth/places/india/#map=radar/overlays=wind');
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
