import 'package:shared_preferences/shared_preferences.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'dart:convert';

abstract class IncidentLocalDataSource {
  Future<void> cacheCategories(List<IncidentCategory> categories);
  Future<List<IncidentCategory>?> getCachedCategories();
}

class IncidentLocalDataSourceImpl implements IncidentLocalDataSource {
  static const String _categoriesKey = 'CACHED_INCIDENT_CATEGORIES';

  @override
  Future<void> cacheCategories(List<IncidentCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = categories.map((category) => category.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_categoriesKey, jsonString);
  }

  @override
  Future<List<IncidentCategory>?> getCachedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_categoriesKey);
    
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList
            .map((json) => IncidentCategory.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // En caso de que cambie la estructura y falle el parseo, ignoramos el caché inválido
        return null;
      }
    }
    return null;
  }
}
