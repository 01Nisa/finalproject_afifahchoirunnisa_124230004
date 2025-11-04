import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/auction_model.dart';
import '../utils/constants.dart';

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
      print('Using memory cached auctions: ${_cache.length} items');
      return _cache;
    }

    await _ensureBox();

    if (!forceRefresh && _box!.isNotEmpty) {
      final cachedAuctions = _box!.values.toList();
      _cache
        ..clear()
        ..addAll(cachedAuctions);
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
    if (category != null && category != 'Semua') {
      list = list.where((a) => a.category == category);
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

      final minBid = 1000.0 + (objectId % 10) * 500;
      final exclusive = objectId % 2 == 0;
      final daysAhead = 3 + (objectId % 7);

      DateTime auctionDate;
      final index = ApiConstants.artworkObjectIds.indexOf(objectId);
      if (index == 0) {
        auctionDate = DateTime.now().subtract(const Duration(minutes: 12));
      } else if (index == 1) {
        auctionDate = DateTime.now().subtract(const Duration(minutes: 10));
      } else if (index == 2) {
        auctionDate = DateTime.now().subtract(const Duration(minutes: 5));
      } else if (index == 3) {
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
    const categories = [
      'Renaissance',
      'Impressionist',
      'Modern',
      'Contemporary',
      'Classical',
    ];
    return categories[seed % categories.length];
  }
}
