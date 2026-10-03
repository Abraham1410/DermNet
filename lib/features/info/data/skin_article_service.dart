import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SkinArticle {
  final String title;
  final String description;
  final String fullContent;
  final String imageUrl;
  final String sourceUrl;
  final String category;

  SkinArticle({
    required this.title,
    required this.description,
    required this.fullContent,
    required this.imageUrl,
    required this.sourceUrl,
    required this.category,
  });

  factory SkinArticle.fromWikipedia(Map<String, dynamic> page) {
    final title = page['title'] ?? '';
    final extract = page['extract'] ?? '';
    final thumbnail = page['thumbnail']?['source'] ?? '';
    
    // Get first 2 sentences for description
    final sentences = extract.split('. ');
    final description = sentences.length > 1
        ? '${sentences[0]}. ${sentences[1]}.'
        : extract;

    return SkinArticle(
      title: title,
      description: description,
      fullContent: extract,
      imageUrl: thumbnail,
      sourceUrl:
          'https://en.wikipedia.org/wiki/${Uri.encodeComponent(title.replaceAll(' ', '_'))}',
      category: _categorize(title),
    );
  }

  static String _categorize(String title) {
    final t = title.toLowerCase();
    if (t.contains('fungal') ||
        t.contains('fungus') ||
        t.contains('tinea') ||
        t.contains('dermatophyt') ||
        t.contains('ringworm')) return 'Fungal';
    if (t.contains('virus') ||
        t.contains('viral') ||
        t.contains('herpes') ||
        t.contains('chickenpox') ||
        t.contains('shingles') ||
        t.contains('zoster')) return 'Viral';
    if (t.contains('bacteria') ||
        t.contains('cellulitis') ||
        t.contains('impetigo')) return 'Bacterial';
    if (t.contains('dermatitis') ||
        t.contains('eczema') ||
        t.contains('psoriasis')) return 'Inflammatory';
    if (t.contains('acne')) return 'Acne';
    if (t.contains('cancer') ||
        t.contains('melanoma') ||
        t.contains('carcinoma')) return 'Cancer';
    return 'General';
  }
}

class SkinArticleService {
  static const String _searchUrl = 'https://en.wikipedia.org/w/api.php';

  // Predefined list of important skin conditions to fetch
  static const List<String> _skinTopics = [
    'Atopic dermatitis',
    'Acne',
    'Psoriasis',
    'Contact dermatitis',
    'Dermatophytosis',
    'Impetigo',
    'Cellulitis',
    'Vitiligo',
    'Urticaria',
    'Seborrheic dermatitis',
    'Melanoma',
    'Rosacea',
    'Herpes zoster',
    'Chickenpox',
    'Scabies',
  ];

  /// Fetch all predefined skin articles
  Future<List<SkinArticle>> fetchSkinArticles() async {
    try {
      final uri = Uri.parse(_searchUrl).replace(queryParameters: {
        'action': 'query',
        'format': 'json',
        'prop': 'extracts|pageimages',
        'exintro': '1',
        'explaintext': '1',
        'pithumbsize': '400',
        'titles': _skinTopics.join('|'),
      });

      final response = await http.get(uri, headers: {
        'User-Agent': 'DermaCareApp/1.0 (educational project)',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pages = data['query']['pages'] as Map<String, dynamic>;

        final articles = <SkinArticle>[];
        for (final page in pages.values) {
          if (page['pageid'] != null && page['extract'] != null) {
            articles
                .add(SkinArticle.fromWikipedia(page as Map<String, dynamic>));
          }
        }

        return articles;
      }
      throw Exception('Failed to fetch articles: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error fetching skin articles: $e');
      return [];
    }
  }

  /// Search for a specific skin condition
  Future<List<SkinArticle>> searchArticles(String query) async {
    try {
      final uri = Uri.parse(_searchUrl).replace(queryParameters: {
        'action': 'query',
        'format': 'json',
        'prop': 'extracts|pageimages',
        'exintro': '1',
        'explaintext': '1',
        'pithumbsize': '400',
        'generator': 'search',
        'gsrsearch': 'skin disease $query',
        'gsrlimit': '10',
      });

      final response = await http.get(uri, headers: {
        'User-Agent': 'DermaCareApp/1.0 (educational project)',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pages =
            data['query']?['pages'] as Map<String, dynamic>? ?? {};

        final articles = <SkinArticle>[];
        for (final page in pages.values) {
          if (page['pageid'] != null && page['extract'] != null) {
            articles
                .add(SkinArticle.fromWikipedia(page as Map<String, dynamic>));
          }
        }

        return articles;
      }
      return [];
    } catch (e) {
      debugPrint('Error searching articles: $e');
      return [];
    }
  }

  /// Get full article content for a specific topic
  Future<String> getFullArticle(String title) async {
    try {
      final uri = Uri.parse(_searchUrl).replace(queryParameters: {
        'action': 'query',
        'format': 'json',
        'prop': 'extracts',
        'explaintext': '1',
        'titles': title,
      });

      final response = await http.get(uri, headers: {
        'User-Agent': 'DermaCareApp/1.0 (educational project)',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pages = data['query']['pages'] as Map<String, dynamic>;
        final page = pages.values.first;
        return page['extract'] ?? '';
      }
      return '';
    } catch (e) {
      debugPrint('Error fetching full article: $e');
      return '';
    }
  }
}
