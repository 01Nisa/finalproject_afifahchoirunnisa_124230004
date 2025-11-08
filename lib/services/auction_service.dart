import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/auction_model.dart';
import '../utils/constants.dart';
import '../utils/conversion.dart';

// Public helper: extract the first 4-digit year from API objectDate strings.
String? extractYearFromObjectDate(String? raw) {
  if (raw == null) return null;
  final m = RegExp(r"\b(\d{4})\b").firstMatch(raw);
  if (m != null) {
    final y = int.tryParse(m.group(1)!);
    if (y != null && y >= 1000 && y <= 2100) return y.toString();
  }
  return null;
}

class AuctionService {
  static final AuctionService _instance = AuctionService._internal();
  factory AuctionService() => _instance;
  AuctionService._internal();

  final List<AuctionModel> _cache = [];
  Box<AuctionModel>? _box;
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(hours: 24); 

  Future<void> _ensureBox() async {
    _box ??= await Hive.openBox<AuctionModel>('auctions_box');
  }

  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  Future<List<AuctionModel>> fetchAuctions({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache.isNotEmpty && _isCacheValid) {
      // Ensure any in-memory cached auctions are migrated if they look like
      // old USD-based small values. This covers the case where the app
      // loaded older small values into memory earlier in the session.
      await _ensureBox();
      bool changed = false;
      for (int i = 0; i < _cache.length; i++) {
        final a = _cache[i];
        if (a.minimumBid < 10000) {
          final newMin = ConversionHelper.convertCurrency(a.minimumBid, 'IDR', fromCurrency: 'USD');
          final newCurrent = ConversionHelper.convertCurrency(a.currentBid, 'IDR', fromCurrency: 'USD');
          final migratedA = AuctionModel(
            id: a.id,
            metObjectId: a.metObjectId,
            title: a.title,
            artist: a.artist,
            primaryImageUrl: a.primaryImageUrl,
            minimumBid: newMin,
            currentBid: newCurrent,
            location: a.location,
            year: a.year,
            medium: a.medium,
            dimensions: a.dimensions,
            latitude: a.latitude,
            longitude: a.longitude,
            auctionDate: a.auctionDate,
            status: a.status,
            totalBids: a.totalBids,
            isExclusive: a.isExclusive,
            category: a.category,
          );
          _cache[i] = migratedA;
          try {
            await _box!.put(migratedA.id, migratedA);
          } catch (_) {}
          changed = true;
        }
      }
      if (changed) print('Migrated ${_cache.length} cached auctions to IDR');
      print('Using memory cached auctions: ${_cache.length} items');
      return _cache;
    }

    await _ensureBox();

    if (!forceRefresh && _box!.isNotEmpty) {
      final cachedAuctions = _box!.values.toList();
      final migrated = <AuctionModel>[];
      // If cached auctions were created with old small numeric values (e.g. USD-like
      // amounts), migrate them to IDR by converting from USD->IDR when the
      // stored minimumBid looks unreasonably small.
      for (final a in cachedAuctions) {
        if (a.minimumBid < 10000) {
          final newMin = ConversionHelper.convertCurrency(a.minimumBid, 'IDR', fromCurrency: 'USD');
          final newCurrent = ConversionHelper.convertCurrency(a.currentBid, 'IDR', fromCurrency: 'USD');
          final migratedA = AuctionModel(
            id: a.id,
            metObjectId: a.metObjectId,
            title: a.title,
            artist: a.artist,
            primaryImageUrl: a.primaryImageUrl,
            minimumBid: newMin,
            currentBid: newCurrent,
            location: a.location,
            year: a.year,
            medium: a.medium,
            dimensions: a.dimensions,
            latitude: a.latitude,
            longitude: a.longitude,
            auctionDate: a.auctionDate,
            status: a.status,
            totalBids: a.totalBids,
            isExclusive: a.isExclusive,
            category: a.category,
          );
          await _box!.put(migratedA.id, migratedA);
          migrated.add(migratedA);
        } else {
          migrated.add(a);
        }
      }

      _cache
        ..clear()
        ..addAll(migrated);
      print('Loaded ${_cache.length} auctions from local storage (Hive)');

      return _cache;
    }

    print(
        'Fetching ${ApiConstants.artworkObjectIds.length} auctions from API...');

    final futures =
        ApiConstants.artworkObjectIds.map((id) => _fetchMetObject(id));
    final results = await Future.wait(futures);
    var auctions = results.whereType<AuctionModel>().toList();

    print('Successfully fetched ${auctions.length} auctions');

    if (auctions.isNotEmpty) {
      await _box!.clear();
      for (final a in auctions) {
        await _box!.put(a.id, a);
      }
      _cache
        ..clear()
        ..addAll(auctions);
      _lastFetchTime = DateTime.now();
      return auctions;
    }

    if (_box!.isNotEmpty) {
      final cachedAuctions = _box!.values.toList();
      _cache
        ..clear()
        ..addAll(cachedAuctions);
      print(
          'API returned no data; using existing local auctions: ${_cache.length}');
      return _cache;
    }

    print('No auctions available (API failed and no local cache).');
    _cache.clear();
    _lastFetchTime = null;
    return [];
  }

  Future<void> clearCache() async {
    _cache.clear();
    _lastFetchTime = null;
    await _ensureBox();
    await _box!.clear();
    print('🗑️ Cache cleared');
  }

  AuctionModel? getAuctionById(String id) {
    try {
      return _cache.firstWhere((a) => a.id == id);
    } catch (_) {
      return _box?.get(id);
    }
  }

  List<AuctionModel> filterAuctions({
    String? status,
    bool? isExclusive,
    String? searchQuery,
    String? category,
  }) {
    Iterable<AuctionModel> list = _cache;
    if (status != null) {
      list = list.where((a) => a.status == status);
    }
    if (isExclusive != null) {
      list = list.where((a) => a.isExclusive == isExclusive);
    }
    // Normalize category matching to be case-insensitive and support
    // older/English category names stored in cache. Also treat 'Semua'
    // as no-op.
    if (category != null && category != 'Semua') {
      // Stronger canonicalization map to handle English/Indonesian variants
      String canonical(String? s) {
        if (s == null) return '';
        final x = s.trim().toLowerCase();
        const map = {
          'renaissance': 'renaisans',
          'renaissances': 'renaisans',
          'renaisans': 'renaisans',
          'impressionist': 'impresionis',
          'impressionists': 'impresionis',
          'impressionism': 'impresionis',
          'impresionis': 'impresionis',
          'modern': 'modern',
          'kontemporer': 'kontemporer',
          'contemporary': 'kontemporer',
          'classical': 'klasik',
          'klasik': 'klasik',
        };
        return map[x] ?? x;
      }

      final wanted = canonical(category);
      list = list.where((a) {
        final ak = canonical(a.category);
        return ak == wanted || ak.contains(wanted) || wanted.contains(ak);
      });
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((a) =>
          a.title.toLowerCase().contains(q) ||
          a.artist.toLowerCase().contains(q) ||
          a.category.toLowerCase().contains(q));
    }
    return list.toList();
  }

  Future<AuctionModel?> _fetchMetObject(int objectId) async {
    try {
      final url =
          Uri.parse('${ApiConstants.metMuseumBaseUrl}/objects/$objectId');

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'application/json',
        'Accept-Language': 'en-US,en;q=0.9',
      };

      final resp = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Timeout fetching object $objectId, skipping...');
          throw TimeoutException('Request timeout');
        },
      );

      if (resp.statusCode != 200) {
        print(
            'Failed to fetch object $objectId: ${resp.statusCode}, skipping...');
        return null; 
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;

  final title = (data['title'] as String?)?.trim();
  final artist = (data['artistDisplayName'] as String?)?.trim();
  final objectDate = (data['objectDate'] as String?)?.trim();
  final medium = (data['medium'] as String?)?.trim();
  final dimensions = (data['dimensions'] as String?)?.trim();

  // Only keep a clean 4-digit year; if none found, leave null so UI hides the field.
  final yearOnly = extractYearFromObjectDate(objectDate);

      if (title == null || title.isEmpty) {
        print('Object $objectId has no title, skipping...');
        return null;
      }

      String? image = data['primaryImageSmall'] as String?;
      if (image == null || image.isEmpty) {
        image = data['primaryImage'] as String?;
      }

      if (image == null || image.isEmpty) {
        print('No image found for object $objectId ($title), skipping...');
        return null;
      }

      print('Successfully fetched: $title by ${artist ?? "Unknown Artist"}');

  // Generate minimum bid in IDR (app default). The user requested
  // 'juta' (millions), not 'miliar'. Use a base in millions with
  // some variance and jitter for variety.
  // Base: 1,000,000 IDR (1 juta) + variance depending on id.
  final base = 1000000.0; // 1 juta IDR
  final variance = (objectId % 20) * 250000.0; // up to +4.75 juta
  final jitter = (objectId % 7) * 50000.0; // small per-item jitter
  final minBid = base + variance + jitter;
      final exclusive = objectId % 2 == 0;
      final daysAhead = 3 + (objectId % 7);

      DateTime auctionDate;
      final index = ApiConstants.artworkObjectIds.indexOf(objectId);
      if (index == 0) {
        // Sisa 6 menit (lelang 60 menit - 6 menit = dimulai 54 menit yang lalu)
        auctionDate = DateTime.now().subtract(const Duration(minutes: 54));
      } else if (index == 1) {
        // Sisa 20 menit (lelang 60 menit - 20 menit = dimulai 40 menit yang lalu)
        auctionDate = DateTime.now().subtract(const Duration(minutes: 40));
      } else if (index == 2) {
        // Sisa 30 menit (lelang 60 menit - 30 menit = dimulai 30 menit yang lalu)
        auctionDate = DateTime.now().subtract(const Duration(minutes: 30));
      } else if (index == 3) {
        // Sisa 1 jam (lelang baru dimulai)
        auctionDate = DateTime.now();
      } else {
        auctionDate = DateTime.now().add(Duration(days: daysAhead, hours: 20));
      }

      final location = _randomLocation(objectId);
      final category = _getCategory(objectId);

      return AuctionModel(
        metObjectId: objectId,
        title: title,
        artist: artist ?? 'Unknown Artist',
        primaryImageUrl: image,
        minimumBid: minBid,
  year: yearOnly,
        medium: medium,
        dimensions: dimensions,
        location: location,
        auctionDate: auctionDate,
        isExclusive: exclusive,
        category: category,
      );
    } catch (e) {
      print('Exception fetching object $objectId: $e');
      return null;
    }
  }

  String _randomLocation(int seed) {
    const locations = [
      'New York, USA',
      'London, UK',
      'Tokyo, Japan',
      'Paris, France',
      'Jakarta, Indonesia',
      'Sydney, Australia',
      'Singapore',
      'Berlin, Germany',
    ];
    return locations[seed % locations.length];
  }

  String _getCategory(int seed) {
    // Return category names in Indonesian to match UI filter chips.
    const categories = [
      'Renaisans',
      'Impresionis',
      'Modern',
      'Kontemporer',
      'Klasik',
    ];
    return categories[seed % categories.length];
  }
}
