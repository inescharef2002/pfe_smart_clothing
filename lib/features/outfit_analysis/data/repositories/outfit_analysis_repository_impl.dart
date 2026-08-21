import 'package:image_picker/image_picker.dart';
import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../../domain/entities/clothing_analysis_entity.dart';
import '../../domain/entities/outfit_suggestion_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/outfit_analysis_repository.dart';
import '../datasources/outfit_analysis_datasource.dart';

class OutfitAnalysisRepositoryImpl implements OutfitAnalysisRepository {
  final OutfitAnalysisDataSource _dataSource;
  OutfitAnalysisRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, ClothingAnalysisEntity>> analyzeClothing(XFile imageFile) async {
    try {
      return Right(await _dataSource.analyzeClothing(imageFile));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OutfitSuggestionEntity>>> suggestOutfits({
    required List<Map<String, dynamic>> wardrobeItems,
    String? occasion,
  }) async {
    try {
      return Right(await _dataSource.suggestOutfits(wardrobeItems: wardrobeItems, occasion: occasion));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WeatherEntity>> getWeather({String city = 'Tunis', double? lat, double? lon}) async {
    try {
      return Right(await _dataSource.getWeather(city: city, lat: lat, lon: lon));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WeatherOutfitResult>> suggestWeatherOutfit({
    required List<Map<String, dynamic>> wardrobeItems,
    required int temperature,
    required String weatherDescription,
    String? city,
  }) async {
    try {
      return Right(await _dataSource.suggestWeatherOutfit(
        wardrobeItems: wardrobeItems,
        temperature: temperature,
        weatherDescription: weatherDescription,
        city: city,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
