import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../repositories/outfit_analysis_repository.dart';

class SuggestWeatherOutfitsUseCase {
  final OutfitAnalysisRepository repository;
  SuggestWeatherOutfitsUseCase(this.repository);

  Future<Either<Failure, WeatherOutfitResult>> call({
    required List<Map<String, dynamic>> wardrobeItems,
    required int temperature,
    required String weatherDescription,
    String? city,
  }) =>
      repository.suggestWeatherOutfit(
        wardrobeItems: wardrobeItems,
        temperature: temperature,
        weatherDescription: weatherDescription,
        city: city,
      );
}
