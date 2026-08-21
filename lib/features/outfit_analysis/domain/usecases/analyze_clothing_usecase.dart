import 'package:image_picker/image_picker.dart';
import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../entities/clothing_analysis_entity.dart';
import '../repositories/outfit_analysis_repository.dart';

class AnalyzeClothingUseCase {
  final OutfitAnalysisRepository repository;
  AnalyzeClothingUseCase(this.repository);

  Future<Either<Failure, ClothingAnalysisEntity>> call(XFile imageFile) =>
      repository.analyzeClothing(imageFile);
}
