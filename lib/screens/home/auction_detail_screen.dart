// lib/screens/auction/auction_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/geocoding_service.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../utils/conversion.dart';
import '../../models/auction_model.dart';

class AuctionDetailScreen extends StatefulWidget {
  final AuctionModel auction;
  const AuctionDetailScreen({required this.auction, super.key});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final _authService = AuthService();
  final _userService = UserService();
  final _geocoding = GeocodingService();

  double? _lat;
  double? _lng;
  bool _isLoadingMap = true;
  String? _mapError;
  // _currentPosition intentionally removed (not used in this screen's preview)

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  // _fetchCurrentPosition removed: small preview no longer needs device location

  Future<void> _resolveLocation() async {
    setState(() {
      _isLoadingMap = true;
      _mapError = null;
    });

    try {
      if (widget.auction.latitude != null && widget.auction.longitude != null) {
        setState(() {
          _lat = widget.auction.latitude;
          _lng = widget.auction.longitude;
          _isLoadingMap = false;
        });
        return;
      }

      final result = await _geocoding.geocode(widget.auction.location);
      if (!mounted) return;

      setState(() {
        _lat = result?['lat'];
        _lng = result?['lng'];
        _isLoadingMap = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMap = false;
        _mapError = 'Gagal memuat peta';
      });
    }
  }

  Future<void> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      await _ensureLocationPermission();
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      final settings = const LocationSettings(accuracy: LocationAccuracy.best);
      return await Geolocator.getCurrentPosition(locationSettings: settings);
    } catch (e) {
      return null;
    }
  }

  Future<void> _openLocationSheet() async {
    if (_lat == null || _lng == null) return;
    if (!mounted) return;

    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => FullScreenMapPage(
        auctionLat: _lat!,
        auctionLng: _lng!,
        auctionTitle: widget.auction.title,
        getCurrentPosition: _getCurrentPosition,
      ),
    ));
  }

  void _registerAuction() async {
    final user = await _authService.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.vintageGold),
      ),
    );

    final res = await _userService.registerAuction(
        userId: user.id, auction: widget.auction);

    navigator.pop();

    await NotificationService().addNotification(
      userId: user.id,
      title: res['success'] == true ? 'Pendaftaran Berhasil' : 'Pendaftaran Gagal',
      message: res['message'] ?? 'Berhasil',
      type: 'registration',
      auctionId: widget.auction.id,
      context: context,
      showPopup: false,
      showLocal: true,
    );

    if (res['success'] == true) {
      await userProvider.refreshInterests(user.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _cancelAuction() async {
    final user = await _authService.getCurrentUser();
    if (user == null) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Batalkan Pendaftaran'),
            content: const Text('Apakah Anda yakin ingin membatalkan pendaftaran lelang ini?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white),
                child: const Text('Ya'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.vintageGold),
      ),
    );

    try {
      final interests = _userService.getRegisteredAuctions(user.id);
      final interest = interests.firstWhere(
        (i) => i.auctionId == widget.auction.id,
        orElse: () => throw Exception('Pendaftaran tidak ditemukan'),
      );

      await _userService.unregisterAuction(interest.id);
      navigator.pop();

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.refreshInterests(user.id);

      await NotificationService().addNotification(
        userId: user.id,
        title: 'Pembatalan Berhasil',
        message: 'Pendaftaran lelang dibatalkan',
        type: 'cancellation',
        auctionId: widget.auction.id,
        context: context,
        showPopup: false,
        showLocal: true,
      );

      setState(() {});
    } catch (e) {
      navigator.pop();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final currency = user?.defaultCurrency ?? AppConstants.defaultCurrency;
    final timezone = user?.defaultTimezone ?? AppConstants.defaultTimezone;

    return Scaffold(
      backgroundColor: AppColors.vintageBg,
      appBar: AppBar(
        backgroundColor: AppColors.vintageCream,
        elevation: 0,
        title: Text(
          widget.auction.title,
          style: const TextStyle(
            color: AppColors.vintageBrown,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GAMBAR UTAMA
                if (widget.auction.primaryImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    child: Image.network(
                      widget.auction.primaryImageUrl,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (c, child, p) => p == null
                          ? child
                          : Container(
                              height: 300,
                              color: AppColors.surfaceVariant,
                              child: const Center(
                                  child: CircularProgressIndicator(color: AppColors.vintageGold)),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        height: 300,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 300,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image, size: 80, color: Colors.grey),
                  ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // JUDUL KARYA
                      Text(
                        widget.auction.title,
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.vintageBrown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // SENIMAN
                      if (widget.auction.artist.isNotEmpty)
                        Text(
                          'Oleh: ${widget.auction.artist}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.vintageBrown,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                      const SizedBox(height: 16),

                      // DETAIL KARYA: TAHUN, MEDIUM, DIMENSI — SATU KALI SAJA
                      if (widget.auction.year?.isNotEmpty == true ||
                          widget.auction.medium?.isNotEmpty == true ||
                          widget.auction.dimensions?.isNotEmpty == true)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.vintageCream.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.vintageGold.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.palette, color: AppColors.vintageGold, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Detail Karya',
                                    style: AppTextStyles.h4.copyWith(
                                      color: AppColors.vintageBrown,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (widget.auction.year?.isNotEmpty == true)
                                _buildDetailRow('Tahun', widget.auction.year!),
                              if (widget.auction.medium?.isNotEmpty == true)
                                _buildDetailRow('Medium', widget.auction.medium!),
                              if (widget.auction.dimensions?.isNotEmpty == true)
                                _buildDetailRow('Dimensi', widget.auction.dimensions!),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // HARGA DASAR
                      _buildInfoCard(
                        icon: Icons.local_offer,
                        title: 'Harga Dasar',
                        value: ConversionHelper.formatConvertedCurrency(widget.auction.minimumBid, currency),
                        valueColor: AppColors.vintageGold,
                      ),

                      const SizedBox(height: 16),

                      // WAKTU LELANG
                      _buildInfoCard(
                        icon: Icons.access_time,
                        title: 'Waktu Lelang',
                        value: ConversionHelper.formatDateTime(widget.auction.auctionDate, timezone),
                        valueColor: AppColors.vintageBrown,
                      ),

                      const SizedBox(height: 16),

                      // LOKASI
                      _buildInfoCard(
                        icon: Icons.location_on,
                        title: 'Lokasi',
                        value: widget.auction.location,
                        valueColor: AppColors.vintageBrown,
                      ),

                      const SizedBox(height: 24),

                      // MINI MAP
                      Text(
                        'Lokasi di Peta',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.vintageBrown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border.withOpacity(0.6)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildMapWidget(),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM BUTTON
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.vintageBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -6),
                  )
                ],
              ),
              child: Consumer2<AuthProvider, UserProvider>(
                builder: (context, authProvider, userProvider, child) {
                  final user = authProvider.currentUser;
                  final isRegistered = user != null &&
                      _userService.isAuctionRegistered(user.id, widget.auction.id);

                  final now = DateTime.now();
                  final hasStarted = now.isAfter(widget.auction.auctionDate);
                  final endTime = widget.auction.auctionDate.add(AppAnimations.auctionDuration);
                  final isFinished = now.isAfter(endTime);

                  if (isRegistered && !hasStarted) {
                    return _buildCancelButton();
                  }

                  if (isRegistered && hasStarted && !isFinished) {
                    return _buildRegisteredBadge();
                  }

                  if (isFinished) {
                    return _buildFinishedButton();
                  }

                  return _buildRegisterButton();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.vintageBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.vintageCream.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: valueColor ?? AppColors.vintageBrown, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.bodyMedium.copyWith(
                  color: valueColor ?? AppColors.vintageBrown,
                  fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton.icon(
      onPressed: _registerAuction,
      icon: const Icon(Icons.gavel, size: 22),
      label: const Text('Daftar Lelang', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.vintageGold,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }

  Widget _buildCancelButton() {
    return OutlinedButton.icon(
      onPressed: _cancelAuction,
      icon: const Icon(Icons.cancel_outlined, size: 20),
      label: const Text('Batal Daftar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildRegisteredBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 24),
          SizedBox(width: 10),
          Text('Sudah Terdaftar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.success)),
        ],
      ),
    );
  }

  Widget _buildFinishedButton() {
    return ElevatedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.gavel, size: 20),
      label: const Text('Lelang Telah Selesai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: AppColors.textTertiary.withOpacity(0.7),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildMapWidget() {
    if (_isLoadingMap) {
      return const Center(child: CircularProgressIndicator(color: AppColors.vintageGold));
    }

    if (_mapError != null || _lat == null || _lng == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('Lokasi tidak tersedia', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _resolveLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final auctionPoint = ll.LatLng(_lat!, _lng!);
    final shortLabel = widget.auction.location.split(',').first.trim();

    return InkWell(
      onTap: _openLocationSheet,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: auctionPoint, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                tileProvider: NetworkTileProvider(headers: {'User-Agent': 'ArtBid/1.0'}),
              ),
              MarkerLayer(markers: [
                Marker(
                  point: auctionPoint,
                  width: 120,
                  height: 80,
                  child: Column(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 40),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          shortLabel,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ],
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Lihat Lokasi', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

// FULL SCREEN MAP — ANIMASI PESAWAT + JARAK AKURAT
class FullScreenMapPage extends StatefulWidget {
  final double auctionLat;
  final double auctionLng;
  final String auctionTitle;
  final Future<Position?> Function() getCurrentPosition;

  const FullScreenMapPage({
    required this.auctionLat,
    required this.auctionLng,
    required this.auctionTitle,
    required this.getCurrentPosition,
    super.key,
  });

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> with SingleTickerProviderStateMixin {
  Position? _current;
  double? _distanceMeters;
  bool _loading = true;
  bool _permissionDeniedForever = false;
  String? _userLabel;
  String? _auctionLabel;
  AnimationController? _planeController;
  ll.LatLng? _planePosition;
  double _planeRotation = 0.0;
  final MapController _mapController = MapController();

  List<Polyline> _createDashedPolylines(ll.LatLng a, ll.LatLng b, {int segments = 24}) {
    final List<Polyline> parts = [];
    for (int i = 0; i < segments; i += 2) {
      final t1 = i / segments;
      final t2 = (i + 1) / segments;
      final lat1 = a.latitude + (b.latitude - a.latitude) * t1;
      final lng1 = a.longitude + (b.longitude - a.longitude) * t1;
      final lat2 = a.latitude + (b.latitude - a.latitude) * t2;
      final lng2 = a.longitude + (b.longitude - a.longitude) * t2;
      parts.add(Polyline(
        points: [ll.LatLng(lat1, lng1), ll.LatLng(lat2, lng2)],
        strokeWidth: 3.0,
        color: Colors.black,
      ));
    }
    return parts;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _permissionDeniedForever = true;
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    final pos = await widget.getCurrentPosition();
    double? dist;
    if (pos != null) {
      dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, widget.auctionLat, widget.auctionLng);
    }

    if (!mounted) return;

    String? userPlace;
    if (pos != null) {
      try {
        userPlace = await _reverseGeocode(pos.latitude, pos.longitude);
      } catch (_) {}
    }

    String? auctionPlace;
    try {
      auctionPlace = await _reverseGeocode(widget.auctionLat, widget.auctionLng);
    } catch (_) {}

    setState(() {
      _current = pos;
      _distanceMeters = dist;
      _userLabel = userPlace ?? (pos != null ? '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}' : null);
      _auctionLabel = auctionPlace ?? widget.auctionTitle;
      _loading = false;
    });

    if (_current != null) {
      _startPlaneAnimation();
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (_current == null) return;
    final auctionPoint = ll.LatLng(widget.auctionLat, widget.auctionLng);
    final userPoint = ll.LatLng(_current!.latitude, _current!.longitude);
    final dist = _distanceMeters ?? Geolocator.distanceBetween(userPoint.latitude, userPoint.longitude, auctionPoint.latitude, auctionPoint.longitude);

    double fitZoomFromDistance(double? d) {
      if (d == null) return 13;
      if (d < 200) return 16;
      if (d < 1000) return 15;
      if (d < 5000) return 13;
      if (d < 20000) return 11;
      if (d < 100000) return 9;
      return 6;
    }

    final center = ll.LatLng((auctionPoint.latitude + userPoint.latitude) / 2, (auctionPoint.longitude + userPoint.longitude) / 2);
    final baseFit = fitZoomFromDistance(dist);
    final computedZoom = math.max(3.0, math.min(18.0, baseFit) - 1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(center, computedZoom);
      } catch (_) {}
    });
  }

  void _startPlaneAnimation() {
    _stopPlaneAnimation();
    final userPoint = ll.LatLng(_current!.latitude, _current!.longitude);
    final auctionPoint = ll.LatLng(widget.auctionLat, widget.auctionLng);
    final start = auctionPoint;
    final end = userPoint;

    final dist = Geolocator.distanceBetween(start.latitude, start.longitude, end.latitude, end.longitude);
    final durationMs = math.max(4000, math.min(20000, (dist / 1000 * 2000).toInt()));

    _planeController = AnimationController(vsync: this, duration: Duration(milliseconds: durationMs));
    _planeController!.addListener(() {
      final t = _planeController!.value;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      setState(() {
        _planePosition = ll.LatLng(lat, lng);
        final dLat = end.latitude - start.latitude;
        final dLng = end.longitude - start.longitude;
        _planeRotation = math.atan2(dLng, dLat);
      });
    });
    _planeController!.repeat();
  }

  void _stopPlaneAnimation() {
    _planeController?.stop();
    _planeController?.dispose();
    _planeController = null;
    _planePosition = null;
  }

  Future<String?> _reverseGeocode(double lat, double lon) async {
    final url = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'json',
      'lat': lat.toString(),
      'lon': lon.toString(),
      'zoom': '10',
      'addressdetails': '1',
    });

    final resp = await http.get(url, headers: {'User-Agent': 'ArtBid/1.0'});
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as Map<String, dynamic>?;
    if (data == null) return null;
    final address = data['address'] as Map<String, dynamic>?;
    String? place;
    if (address != null) {
      place = address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? address['state'];
    }
    if (place == null) {
      final display = data['display_name'] as String?;
      if (display != null && display.isNotEmpty) {
        place = display.split(',').first;
      }
    }
    return place;
  }

  Future<void> _retry() async {
    setState(() => _loading = true);
    await _load();
  }

  @override
  void dispose() {
    _stopPlaneAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auctionPoint = ll.LatLng(widget.auctionLat, widget.auctionLng);
    final userPoint = _current != null ? ll.LatLng(_current!.latitude, _current!.longitude) : null;
    final initialCenter = userPoint != null
        ? ll.LatLng((userPoint.latitude + auctionPoint.latitude) / 2, (userPoint.longitude + auctionPoint.longitude) / 2)
        : auctionPoint;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.auctionTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _retry),
          if (_permissionDeniedForever)
            IconButton(icon: const Icon(Icons.settings), onPressed: () => Geolocator.openAppSettings()),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(builder: (ctx) {
              try {
                final List<Polyline> dashLines = [];
                if (userPoint != null) {
                  dashLines.addAll(_createDashedPolylines(userPoint, auctionPoint));
                }

                final dist = _distanceMeters ?? (userPoint != null
                    ? Geolocator.distanceBetween(userPoint.latitude, userPoint.longitude, auctionPoint.latitude, auctionPoint.longitude)
                    : null);

                double fitZoomFromDistance(double? d) {
                  if (d == null) return 13;
                  if (d < 200) return 16;
                  if (d < 1000) return 15;
                  if (d < 5000) return 13;
                  if (d < 20000) return 11;
                  if (d < 100000) return 9;
                  return 6;
                }

                final double maxZoomForBoth = math.min(18.0, fitZoomFromDistance(dist));
                final baseFit = fitZoomFromDistance(dist);
                double computedZoom = math.max(2.0, math.min(maxZoomForBoth, baseFit) - 1.0);

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: computedZoom,
                    minZoom: 2.0,
                    maxZoom: maxZoomForBoth,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      tileProvider: NetworkTileProvider(headers: {'User-Agent': 'ArtBid/1.0'}),
                    ),
                    if (dashLines.isNotEmpty) PolylineLayer(polylines: dashLines),
                    MarkerLayer(markers: [
                      Marker(
                        point: auctionPoint,
                        width: 120,
                        height: 80,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: Colors.red, size: 36),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                _auctionLabel ?? widget.auctionTitle,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (userPoint != null)
                        Marker(
                          point: userPoint,
                          width: 100,
                          height: 80,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if ((_userLabel ?? '').isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                    _userLabel ?? '',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                                ),
                                child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ),
                      if (userPoint != null)
                        Marker(
                          point: _planePosition ?? ll.LatLng((userPoint.latitude + auctionPoint.latitude) / 2, (userPoint.longitude + auctionPoint.longitude) / 2),
                          width: 36,
                          height: 36,
                          child: Transform.rotate(
                            angle: _planeRotation,
                            child: const Icon(Icons.airplanemode_active, color: Colors.black, size: 28),
                          ),
                        ),
                    ]),
                  ],
                );
              } catch (err) {
                return Center(child: Text('Gagal memuat peta: ${err.toString()}'));
              }
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (_permissionDeniedForever)
                  Column(
                    children: [
                      const Text('Izin lokasi diblokir. Aktifkan dari pengaturan.'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text('Buka Pengaturan'),
                        onPressed: () => Geolocator.openAppSettings(),
                      ),
                    ],
                  )
                else if (_loading)
                  const CircularProgressIndicator()
                else
                  Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.my_location, size: 28, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userLabel?.split(' - ').last ?? (_userLabel ?? 'Lokasi Anda'),
                                      style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _current != null ? '${_current!.latitude.toStringAsFixed(6)}, ${_current!.longitude.toStringAsFixed(6)}' : '—',
                                      style: AppTextStyles.bodyMedium.copyWith(fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 28, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _auctionLabel?.split(' - ').last ?? widget.auctionTitle,
                                      style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${widget.auctionLat.toStringAsFixed(6)}, ${widget.auctionLng.toStringAsFixed(6)}',
                                      style: AppTextStyles.bodyMedium.copyWith(fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.swap_calls),
                          title: Text(_distanceMeters != null ? '${(_distanceMeters! / 1000).toStringAsFixed(2)} km' : '—'),
                          subtitle: const Text('Jarak'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}