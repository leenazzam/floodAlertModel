import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/street_model.dart';
import '../models/school_model.dart';

class RefidiaRepository {
  RefidiaRepository._();
  static final RefidiaRepository instance = RefidiaRepository._();

  Future<List<Street>> fetchStreets() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/streets");
    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception("Failed to load streets: ${res.statusCode} ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['streets'] as List).cast<Map<String, dynamic>>();
    return list.map((j) => Street.fromJson(j)).toList();
  }

  Future<List<SchoolPoint>> fetchSchools() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/schools");
    final res = await http.get(url);

    final decoded = jsonDecode(res.body);

    final list = (decoded is Map<String, dynamic>)
        ? (decoded["schools"] as List<dynamic>? ?? [])
        : (decoded as List<dynamic>);

    return list
        .map((j) => SchoolPoint.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
