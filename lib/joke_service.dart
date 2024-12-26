import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class JokeService {
  final Dio _dio = Dio();
  final String _cacheKey = 'cached_jokes';

  // Fetch jokes either from API or cache if offline
  Future<List<Map<String, String>>> fetchJokesRaw() async {
    try {
      // Try fetching jokes from the API
      final response = await _dio.get("https://v2.jokeapi.dev/joke/Any?amount=5");

      // If the API request is successful
      if (response.statusCode == 200) {
        final jokes = <Map<String, String>>[];

        // Iterate over the jokes fetched from the API
        for (final joke in response.data['jokes']) {
          if (joke['type'] == 'single') {
            jokes.add({'joke': joke['joke']});
          } else if (joke['type'] == 'twopart') {
            jokes.add({'setup': joke['setup'], 'delivery': joke['delivery']});
          }
        }

        // Cache jokes for offline access
        await _cacheJokes(jokes);
        return jokes;
      } else {
        throw Exception('Failed to load jokes');
      }
    } catch (e) {
      // If the API request fails (e.g., offline), return cached jokes
      print('Error fetching jokes from API: $e');
      final cachedJokes = await _getCachedJokes();
      if (cachedJokes != null && cachedJokes.isNotEmpty) {
        return cachedJokes;
      } else {
        throw Exception('No cached jokes available: $e');
      }
    }
  }

  // Cache jokes to shared preferences
  Future<void> _cacheJokes(List<Map<String, String>> jokes) async {
    final prefs = await SharedPreferences.getInstance();
    final jokesJson = jsonEncode(jokes);
    await prefs.setString(_cacheKey, jokesJson);
  }

  // Retrieve cached jokes from shared preferences
  Future<List<Map<String, String>>?> _getCachedJokes() async {
    final prefs = await SharedPreferences.getInstance();
    final jokesJson = prefs.getString(_cacheKey);

    if (jokesJson != null) {
      final List<dynamic> decodedJokes = jsonDecode(jokesJson);
      return decodedJokes.map((joke) => Map<String, String>.from(joke)).toList();
    }

    return null;
  }
}
