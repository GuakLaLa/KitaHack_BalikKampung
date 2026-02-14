import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Shelter types
enum ShelterType { school, mosque, church, stadium, communityHall }

extension ShelterTypeX on ShelterType {
  String get label {
    switch (this) {
      case ShelterType.school:        return 'School';
      case ShelterType.mosque:        return 'Mosque';
      case ShelterType.church:        return 'Church / Temple';
      case ShelterType.stadium:       return 'Stadium / Hall';
      case ShelterType.communityHall: return 'Community Center';
    }
  }

  String get filterKey {
    switch (this) {
      case ShelterType.school:        return 'school';
      case ShelterType.mosque:        return 'mosque';
      case ShelterType.church:        return 'church';
      case ShelterType.stadium:       return 'stadium';
      case ShelterType.communityHall: return 'hall';
    }
  }

  IconData get icon {
    switch (this) {
      case ShelterType.school:        return Icons.school;
      case ShelterType.mosque:        return Icons.mosque;
      case ShelterType.church:        return Icons.church;
      case ShelterType.stadium:       return Icons.stadium;
      case ShelterType.communityHall: return Icons.home_work;
    }
  }

  Color get color {
    switch (this) {
      case ShelterType.school:        return const Color(0xFF4285F4);
      case ShelterType.mosque:        return const Color(0xFF34A853);
      case ShelterType.church:        return const Color(0xFFEA4335);
      case ShelterType.stadium:       return const Color(0xFFFBBC05);
      case ShelterType.communityHall: return const Color(0xFF9C27B0);
    }
  }

  // Realistic PPS capacity by building type (Malaysian context)
  int get estimatedCapacity {
    switch (this) {
      case ShelterType.stadium:       return 2000;  // large hall / stadium
      case ShelterType.school:        return 800;   // school classrooms + hall
      case ShelterType.mosque:        return 600;   // prayer hall + surau
      case ShelterType.communityHall: return 400;   // dewan komuniti
      case ShelterType.church:        return 300;   // church hall
    }
  }
}

// Model
class NearbyShelter {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? rating;
  final ShelterType shelterType;
  final bool isOpen;

  const NearbyShelter({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.rating,
    required this.shelterType,
    required this.isOpen,
  });

  double distanceTo(double lat, double lon) {
    const R = 6371.0;
    final dLat = (latitude - lat) * pi / 180;
    final dLon = (longitude - lon) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat * pi / 180) * cos(latitude * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  int get estimatedCapacity => shelterType.estimatedCapacity;
}

// Service

class PlacesShelterService {
  static String get _apiKey =>
      dotenv.env['googleApiKey'] ?? '';

  // (googlePlacesType, ShelterType)
  static const _searchTypes = [
    ('school',           ShelterType.school),
    ('mosque',           ShelterType.mosque),
    ('church',           ShelterType.church),
    ('stadium',          ShelterType.stadium),
    ('community_center', ShelterType.communityHall),
  ];

  Future<List<NearbyShelter>> fetchNearby(
    double lat, double lon, {
    int radiusMeters = 10000,
  }) async {
    final all = <NearbyShelter>[];

    for (final (googleType, shelterType) in _searchTypes) {
      try {
        final places = await _searchByType(lat, lon, googleType, shelterType, radiusMeters);
        all.addAll(places);
      } catch (e) {
        print('Places ($googleType): $e');
      }
    }

    // Deduplicate
    final seen = <String>{};
    final unique = all.where((p) => seen.add(p.placeId)).toList();

    // Sort by distance
    unique.sort((a, b) => a.distanceTo(lat, lon).compareTo(b.distanceTo(lat, lon)));

    print('${unique.length} nearby shelters found');
    return unique;
  }

  Future<List<NearbyShelter>> _searchByType(
    double lat, double lon,
    String googleType, ShelterType shelterType,
    int radius,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$lat,$lon&radius=$radius&type=$googleType&key=$_apiKey',
    );

    final res = await http.get(url).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final results = (data['results'] as List?) ?? [];

    return results.map((p) {
      final geo = p['geometry']['location'];
      return NearbyShelter(
        placeId:     p['place_id'] ?? '',
        name:        p['name'] ?? 'Unknown',
        address:     p['vicinity'] ?? '',
        latitude:    (geo['lat'] as num).toDouble(),
        longitude:   (geo['lng'] as num).toDouble(),
        rating:      p['rating']?.toDouble(),
        shelterType: shelterType,
        isOpen:      p['opening_hours']?['open_now'] ?? true,
      );
    }).toList();
  }

  // URL builders used by url_launcher
  String directionsUrl(double lat, double lon, String name) =>
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$lat,$lon'
      '&destination_place_name=${Uri.encodeComponent(name)}';

  String placeUrl(String placeId) =>
      'https://www.google.com/maps/place/?q=place_id:$placeId';

  String searchUrl(String query) =>
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
}