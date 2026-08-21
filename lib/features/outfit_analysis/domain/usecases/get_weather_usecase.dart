import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../entities/weather_entity.dart';
import '../repositories/outfit_analysis_repository.dart';

class GetWeatherUseCase {
  final OutfitAnalysisRepository repository;
  GetWeatherUseCase(this.repository);

  Future<Either<Failure, WeatherEntity>> call({String city = 'Tunis', double? lat, double? lon}) =>
      repository.getWeather(city: city, lat: lat, lon: lon);
}
