import 'package:image_picker/image_picker.dart';
import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../entities/clothing_analysis_entity.dart';
import '../entities/outfit_suggestion_entity.dart';
import '../entities/weather_entity.dart';

class WeatherOutfitResult {
  final List<OutfitSuggestionEntity> suggestions;
  final String conseilGeneral;
  const WeatherOutfitResult({required this.suggestions, this.conseilGeneral = ''});
}

abstract class OutfitAnalysisRepository {
  Future<Either<Failure, ClothingAnalysisEntity>> analyzeClothing(XFile imageFile);

  Future<Either<Failure, List<OutfitSuggestionEntity>>> suggestOutfits({
    required List<Map<String, dynamic>> wardrobeItems,
    String? occasion,
  });

  Future<Either<Failure, WeatherEntity>> getWeather({String city, double? lat, double? lon});

  Future<Either<Failure, WeatherOutfitResult>> suggestWeatherOutfit({
    required List<Map<String, dynamic>> wardrobeItems,
    required int temperature,
    required String weatherDescription,
    String? city,
  });
}
