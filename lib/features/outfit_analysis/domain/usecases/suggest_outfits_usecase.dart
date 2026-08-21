import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../entities/outfit_suggestion_entity.dart';
import '../repositories/outfit_analysis_repository.dart';

class SuggestOutfitsUseCase {
  final OutfitAnalysisRepository repository;
  SuggestOutfitsUseCase(this.repository);

  Future<Either<Failure, List<OutfitSuggestionEntity>>> call({
    required List<Map<String, dynamic>> wardrobeItems,
    String? occasion,
  }) =>
      repository.suggestOutfits(wardrobeItems: wardrobeItems, occasion: occasion);
}
