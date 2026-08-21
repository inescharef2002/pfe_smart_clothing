import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/clothing_analysis_entity.dart';
import '../../domain/entities/outfit_suggestion_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/outfit_analysis_repository.dart';

abstract class OutfitAnalysisDataSource {
  Future<ClothingAnalysisEntity> analyzeClothing(XFile imageFile);
  Future<List<OutfitSuggestionEntity>> suggestOutfits({
    required List<Map<String, dynamic>> wardrobeItems,
    String? occasion,
  });
  Future<WeatherEntity> getWeather({String city, double? lat, double? lon});
  Future<WeatherOutfitResult> suggestWeatherOutfit({
    required List<Map<String, dynamic>> wardrobeItems,
    required int temperature,
    required String weatherDescription,
    String? city,
  });
}

// ── Compatibilité couleurs ─────────────────────────────────────────────────
const _compatibleColors = <String, List<String>>{
  'Noir': [
    'Blanc',
    'Gris',
    'Gris clair',
    'Rouge',
    'Bordeaux',
    'Beige',
    'Camel',
    'Jaune',
    'Rose',
    'Bleu',
    'Violet'
  ],
  'Blanc': [
    'Noir',
    'Bleu',
    'Bleu marine',
    'Gris',
    'Gris clair',
    'Beige',
    'Camel',
    'Rouge',
    'Vert',
    'Rose',
    'Kaki'
  ],
  'Gris': [
    'Noir',
    'Blanc',
    'Bleu',
    'Bleu marine',
    'Rose',
    'Bordeaux',
    'Violet'
  ],
  'Gris clair': ['Noir', 'Blanc', 'Bleu', 'Rose', 'Bordeaux', 'Violet'],
  'Bleu': ['Blanc', 'Gris', 'Gris clair', 'Beige', 'Camel', 'Marron', 'Orange'],
  'Bleu marine': ['Blanc', 'Beige', 'Camel', 'Gris', 'Gris clair', 'Rouge'],
  'Rouge': ['Noir', 'Blanc', 'Gris', 'Beige'],
  'Bordeaux': ['Noir', 'Blanc', 'Gris', 'Gris clair', 'Beige', 'Camel'],
  'Beige': [
    'Marron',
    'Marron foncé',
    'Noir',
    'Blanc',
    'Bleu',
    'Bleu marine',
    'Vert',
    'Kaki'
  ],
  'Camel': ['Noir', 'Blanc', 'Bleu', 'Bleu marine', 'Bordeaux', 'Beige'],
  'Marron': ['Beige', 'Camel', 'Blanc', 'Crème', 'Vert', 'Kaki', 'Bleu'],
  'Marron foncé': ['Beige', 'Camel', 'Blanc', 'Crème'],
  'Crème': ['Marron', 'Marron foncé', 'Camel', 'Bleu marine', 'Bordeaux'],
  'Vert': ['Blanc', 'Beige', 'Marron', 'Kaki', 'Gris'],
  'Kaki': ['Blanc', 'Beige', 'Marron', 'Vert', 'Noir', 'Camel'],
  'Rose': ['Blanc', 'Gris', 'Gris clair', 'Noir', 'Beige'],
  'Violet': ['Blanc', 'Gris', 'Gris clair', 'Noir', 'Beige'],
  'Jaune': ['Blanc', 'Gris', 'Noir', 'Bleu marine'],
  'Orange': ['Blanc', 'Bleu', 'Bleu marine', 'Noir', 'Marron'],
};

// ── Combinaisons valides PAR OCCASION ─────────────────────────────────────
const _outfitCombosByOccasion = <String, List<List<String?>>>{
  'Sport': [
    ['T-shirts', 'Pantalons'],
    ['T-shirts', 'Jupes'],
    ['Pulls', 'Pantalons'],
  ],
  'Travail': [
    ['Chemises', 'Pantalons'],
    ['Vestes', 'Pantalons'],
    ['Vestes', 'Jupes'],
    ['Robes', null],
    ['Chemises', 'Jupes'],
  ],
  'Soirée': [
    ['Robes', null],
    ['Vestes', 'Jupes'],
    ['Chemises', 'Pantalons'],
    ['Vestes', 'Pantalons'],
  ],
  'Rendez-vous': [
    ['Robes', null],
    ['Chemises', 'Jupes'],
    ['Vestes', 'Jupes'],
    ['Chemises', 'Pantalons'],
  ],
  'Mariage': [
    ['Robes', null],
    ['Vestes', 'Jupes'],
    ['Vestes', 'Pantalons'],
  ],
  'Weekend': [
    ['T-shirts', 'Pantalons'],
    ['Chemises', 'Pantalons'],
    ['Pulls', 'Pantalons'],
    ['T-shirts', 'Jupes'],
    ['Robes', null],
  ],
  'Quotidienne': [
    ['Chemises', 'Pantalons'],
    ['T-shirts', 'Pantalons'],
    ['Pulls', 'Pantalons'],
    ['Chemises', 'Jupes'],
    ['T-shirts', 'Jupes'],
    ['Robes', null],
    ['Vestes', 'Pantalons'],
  ],
  'météo': [
    ['Chemises', 'Pantalons'],
    ['T-shirts', 'Pantalons'],
    ['Pulls', 'Pantalons'],
    ['Vestes', 'Pantalons'],
    ['Robes', null],
    ['T-shirts', 'Jupes'],
    ['Chemises', 'Jupes'],
  ],
  'casual': [
    ['T-shirts', 'Pantalons'],
    ['Chemises', 'Pantalons'],
    ['Pulls', 'Pantalons'],
    ['T-shirts', 'Jupes'],
    ['Robes', null],
  ],
};

const _occasionEmoji = <String, String>{
  'Quotidienne': '👗',
  'Travail': '💼',
  'Soirée': '✨',
  'Sport': '🏃',
  'Rendez-vous': '💕',
  'Weekend': '🌿',
  'Mariage': '💍',
  'météo': '🌤️',
  'casual': '👗',
};

const _occasionAdvice = <String, String>{
  'Travail':
      'Tenue professionnelle : restez sobre et élégant(e). Choisissez des accessoires discrets.',
  'Soirée': 'Pour briller en soirée, ajoutez bijoux et chaussures habillées.',
  'Sport': 'Privilégiez des matières respirantes et des baskets confortables.',
  'Rendez-vous':
      'Tenue romantique : misez sur les détails soignés et un parfum léger.',
  'Mariage':
      'Tenue de mariage : choisissez des couleurs sobres pour ne pas éclipser les mariés.',
  'Weekend':
      'Look décontracté et confortable, parfait pour les sorties du week-end.',
  'Quotidienne': 'Style casual-chic facile à porter au quotidien.',
};

bool _colorsCompatible(String c1, String c2) {
  if (c1.isEmpty || c2.isEmpty) return true;
  if (c1 == c2) return true;
  if (!_compatibleColors.containsKey(c1) || !_compatibleColors.containsKey(c2))
    return true;
  final list1 = _compatibleColors[c1]!;
  return list1.contains(c2) || (_compatibleColors[c2] ?? []).contains(c1);
}

double _scoreOutfit(List<Map<String, dynamic>> items) {
  if (items.length < 2) return 0.5;
  int total = 0, ok = 0;
  for (int i = 0; i < items.length; i++) {
    for (int j = i + 1; j < items.length; j++) {
      total++;
      final c1 = (items[i]['couleur'] as String?) ?? '';
      final c2 = (items[j]['couleur'] as String?) ?? '';
      if (_colorsCompatible(c1, c2)) ok++;
    }
  }
  return total > 0 ? ok / total : 0.5;
}

List<String> _getTempCategories(int temperature) {
  if (temperature < 10) {
    return [
      'Vestes',
      'Pulls',
      'Manteaux',
      'Pantalons',
      'Accessoires',
      'Chaussures'
    ];
  } else if (temperature < 18) {
    return [
      'Vestes',
      'Pulls',
      'Chemises',
      'Pantalons',
      'Jupes',
      'Accessoires',
      'Chaussures'
    ];
  } else if (temperature < 25) {
    return [
      'Chemises',
      'T-shirts',
      'Pantalons',
      'Jupes',
      'Robes',
      'Vestes',
      'Chaussures',
      'Accessoires'
    ];
  } else {
    return [
      'T-shirts',
      'Robes',
      'Chemises',
      'Jupes',
      'Pantalons',
      'Chaussures',
      'Accessoires'
    ];
  }
}

List<OutfitSuggestionEntity> _generateSuggestions(
  List<Map<String, dynamic>> wardrobe,
  String occasion, {
  int? seed,
}) {
  final rng = Random(seed);
  final occ = occasion;

  // Grouper par catégorie
  final byCategory = <String, List<Map<String, dynamic>>>{};
  for (final item in wardrobe) {
    final cat = (item['categorie'] as String?) ?? 'Autres';
    byCategory.putIfAbsent(cat, () => []).add(item);
  }
  for (final list in byCategory.values) {
    list.shuffle(rng);
  }

  final emoji = _occasionEmoji[occ] ?? '👗';
  final advice = _occasionAdvice[occ] ?? '';
  final suggestions = <OutfitSuggestionEntity>[];

  // ✅ Combinaisons spécifiques à l'occasion
  final combos =
      _outfitCombosByOccasion[occ] ?? _outfitCombosByOccasion['casual']!;

  for (final combo in combos) {
    final cat1 = combo[0]!;
    final cat2 = combo[1];
    final items1 = byCategory[cat1] ?? [];

    if (cat2 == null) {
      // Robe seule
      for (final i1 in items1.take(4)) {
        final outfit = [i1];
        final acc = byCategory['Accessoires'] ?? [];
        if (acc.isNotEmpty) outfit.add(acc[rng.nextInt(acc.length)]);
        final shoes = byCategory['Chaussures'] ?? [];
        if (shoes.isNotEmpty) outfit.add(shoes[rng.nextInt(shoes.length)]);
        final score = _scoreOutfit(outfit);
        if (score >= 0.3) {
          suggestions.add(_buildEntity(outfit, occ, emoji, score, advice));
        }
      }
    } else {
      final items2 = byCategory[cat2] ?? [];
      for (final i1 in items1.take(4)) {
        for (final i2 in items2.take(4)) {
          final outfit = [i1, i2];
          final shoes = byCategory['Chaussures'] ?? [];
          if (shoes.isNotEmpty) outfit.add(shoes[rng.nextInt(shoes.length)]);
          // Pas d'accessoires pour le Sport
          if (occ != 'Sport') {
            final acc = byCategory['Accessoires'] ?? [];
            if (acc.isNotEmpty) outfit.add(acc[rng.nextInt(acc.length)]);
          }
          final score = _scoreOutfit(outfit);
          if (score >= 0.3) {
            suggestions.add(_buildEntity(outfit, occ, emoji, score, advice));
          }
        }
      }
    }
  }

  suggestions.sort((a, b) => b.score.compareTo(a.score));
  final top = suggestions.take(10).toList()..shuffle(rng);
  return top.take(5).toList();
}

OutfitSuggestionEntity _buildEntity(
  List<Map<String, dynamic>> outfit,
  String occasion,
  String emoji,
  double score,
  String advice,
) {
  final pieces = outfit
      .map((i) => '${i['nom'] ?? ''} ${i['couleur'] ?? ''}'.trim())
      .toList();
  final images = outfit.map((i) => (i['imageUrl'] as String?) ?? '').toList();

  final colors = outfit.map((i) => (i['couleur'] as String?) ?? '').join(' & ');
  final nom = 'Tenue $occasion — $colors';

  String description = '';
  if (outfit.length >= 2) {
    final n1 = outfit[0]['nom'] ?? '';
    final c1 = (outfit[0]['couleur'] as String?)?.toLowerCase() ?? '';
    final n2 = outfit[1]['nom'] ?? '';
    final c2 = (outfit[1]['couleur'] as String?)?.toLowerCase() ?? '';
    description = 'Associez votre $n1 $c1 avec votre $n2 $c2. '
        'Compatibilité couleurs : ${(score * 100).round()}%.';
  } else {
    final n1 = outfit[0]['nom'] ?? '';
    final c1 = (outfit[0]['couleur'] as String?)?.toLowerCase() ?? '';
    description =
        'Portez votre $n1 $c1. Compatibilité : ${(score * 100).round()}%.';
  }

  if (advice.isNotEmpty) description += ' $advice';

  return OutfitSuggestionEntity(
    nom: nom,
    pieces: pieces,
    images: images,
    conseil: description.trim(),
    occasion: occasion,
    emoji: emoji,
    score: double.parse(score.toStringAsFixed(2)),
  );
}

// ── DataSource ─────────────────────────────────────────────────────────────
class OutfitAnalysisRemoteDataSource implements OutfitAnalysisDataSource {
  static String get _backendUrl {
    if (kIsWeb) return 'http://localhost:8000';
    return dotenv.env['FASTAPI_URL'] ?? 'http://10.0.2.2:8000';
  }

  static String get _weatherApiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  @override
  Future<ClothingAnalysisEntity> analyzeClothing(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http
        .post(
          Uri.parse('$_backendUrl/api/analyze-clothing'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'image_base64': base64Image}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur analyse (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ClothingAnalysisEntity(
      nom: '${data['categorie']} ${data['couleur']}',
      categorie: data['categorie'] ?? 'Autres',
      couleur: data['couleur'] ?? '',
      marque: '',
      taille: '',
      description: data['description'] ?? '',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Future<List<OutfitSuggestionEntity>> suggestOutfits({
    required List<Map<String, dynamic>> wardrobeItems,
    String? occasion,
  }) async {
    if (wardrobeItems.isEmpty) throw Exception('Garde-robe vide');
    final occ = occasion ?? 'casual';
    final results = _generateSuggestions(wardrobeItems, occ);
    if (results.isEmpty) {
      throw Exception('Aucune combinaison possible pour "$occ". '
          'Ajoutez des vêtements dans des catégories complémentaires.');
    }
    return results;
  }

  @override
  Future<WeatherEntity> getWeather({
    String city = 'Tunis',
    double? lat,
    double? lon,
  }) async {
    final Uri uri;
    if (lat != null && lon != null) {
      uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=$lat&lon=$lon&appid=$_weatherApiKey&units=metric&lang=fr',
      );
    } else {
      uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?q=$city&appid=$_weatherApiKey&units=metric&lang=fr',
      );
    }

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Météo indisponible (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    return WeatherEntity(
      temperature: (data['main']['temp'] as num).round(),
      description: data['weather'][0]['description'] as String,
      icon: data['weather'][0]['main'] as String,
      humidity: (data['main']['humidity'] as num).toInt(),
      city: data['name'] as String,
    );
  }

  @override
  Future<WeatherOutfitResult> suggestWeatherOutfit({
    required List<Map<String, dynamic>> wardrobeItems,
    required int temperature,
    required String weatherDescription,
    String? city,
  }) async {
    if (wardrobeItems.isEmpty) throw Exception('Garde-robe vide');

    final okCategories = _getTempCategories(temperature);
    var filtered = wardrobeItems
        .where((i) => okCategories.contains(i['categorie']))
        .toList();
    if (filtered.isEmpty) filtered = wardrobeItems;

    final suggestions = _generateSuggestions(filtered, 'météo');

    if (suggestions.isEmpty) {
      throw Exception('Pas assez de vêtements adaptés à $temperature°C. '
          'Ajoutez plus de vêtements à votre garde-robe.');
    }

    final weatherAdvice = _weatherAdvice(temperature, weatherDescription);
    final enriched = suggestions.map((s) {
      return OutfitSuggestionEntity(
        nom: s.nom,
        pieces: s.pieces,
        images: s.images,
        occasion: s.occasion,
        emoji: s.emoji,
        score: s.score,
        conseil: weatherAdvice.isNotEmpty
            ? '$weatherAdvice\n${s.conseil}'.trim()
            : s.conseil,
      );
    }).toList();

    return WeatherOutfitResult(
      suggestions: enriched,
      conseilGeneral: 'Tenues adaptées à $temperature°C — $weatherDescription',
    );
  }

  String _weatherAdvice(int temperature, String description) {
    final desc = description.toLowerCase();
    if (temperature < 5)
      return 'Il fait très froid, portez un manteau chaud et des accessoires.';
    if (temperature < 15) {
      if (desc.contains('pluie') || desc.contains('pluvieux')) {
        return 'Temps froid et pluvieux : imperméable conseillé.';
      }
      return 'Temps frais, pensez à une veste ou un pull.';
    }
    if (temperature < 25) {
      if (desc.contains('nuage') || desc.contains('couvert')) {
        return 'Temps nuageux, prévoyez un léger gilet.';
      }
      return 'Température agréable, une tenue légère avec une veste suffira.';
    }
    if (desc.contains('soleil') ||
        desc.contains('ensoleillé') ||
        desc.contains('dégagé')) {
      return 'Beau temps chaud, optez pour des matières légères et respirantes.';
    }
    return 'Temps chaud, privilégiez les vêtements légers et clairs.';
  }
}
