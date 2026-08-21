import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../entities/analysis_history_entity.dart';
import '../entities/outfit_entity.dart';
import '../entities/wardrobe_item_entity.dart';

abstract class WardrobeRepository {
  Stream<List<WardrobeItemEntity>> watchItems(String userId);

  Stream<List<OutfitEntity>> watchOutfits(String userId);

  Stream<List<AnalysisHistoryEntity>> watchHistory(String userId);

  Future<Either<Failure, Unit>> addItem({
    required String userId,
    required WardrobeItemEntity item,
    XFile? imageFile,
  });

  Future<Either<Failure, Unit>> updateItem({
    required String userId,
    required WardrobeItemEntity item,
    XFile? imageFile,
  });

  Future<Either<Failure, Unit>> deleteItem({
    required String userId,
    required String itemId,
  });

  Future<Either<Failure, Unit>> addOutfit({
    required String userId,
    required OutfitEntity outfit,
  });

  Future<Either<Failure, Unit>> deleteOutfit({
    required String userId,
    required String outfitId,
  });

  Future<Either<Failure, String>> getAiSuggestion({
    required List<WardrobeItemEntity> items,
  });

  Future<Either<Failure, String>> logAnalysis({
    required String userId,
    required AnalysisHistoryEntity entry,
  });

  Future<Either<Failure, Unit>> markHistoryAsSaved({
    required String userId,
    required String historyId,
  });
}
