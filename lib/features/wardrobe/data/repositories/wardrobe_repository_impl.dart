import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../../domain/entities/analysis_history_entity.dart';
import '../../domain/entities/outfit_entity.dart';
import '../../domain/entities/wardrobe_item_entity.dart';
import '../../domain/repositories/wardrobe_repository.dart';
import '../datasources/wardrobe_remote_datasource.dart';
import '../models/analysis_history_model.dart';
import '../models/outfit_model.dart';
import '../models/wardrobe_item_model.dart';

class WardrobeRepositoryImpl implements WardrobeRepository {
  final WardrobeDataSource _dataSource;

  WardrobeRepositoryImpl(this._dataSource);

  @override
  Stream<List<WardrobeItemEntity>> watchItems(String userId) =>
      _dataSource.watchItems(userId);

  @override
  Stream<List<OutfitEntity>> watchOutfits(String userId) =>
      _dataSource.watchOutfits(userId);

  @override
  Future<Either<Failure, Unit>> addItem({
    required String userId,
    required WardrobeItemEntity item,
    XFile? imageFile,
  }) async {
    try {
      await _dataSource.addItem(
          userId, WardrobeItemModel.fromEntity(item), imageFile);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateItem({
    required String userId,
    required WardrobeItemEntity item,
    XFile? imageFile,
  }) async {
    try {
      await _dataSource.updateItem(
          userId, WardrobeItemModel.fromEntity(item), imageFile);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteItem({
    required String userId,
    required String itemId,
  }) async {
    try {
      await _dataSource.deleteItem(userId, itemId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addOutfit({
    required String userId,
    required OutfitEntity outfit,
  }) async {
    try {
      await _dataSource.addOutfit(userId, OutfitModel.fromEntity(outfit));
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteOutfit({
    required String userId,
    required String outfitId,
  }) async {
    try {
      await _dataSource.deleteOutfit(userId, outfitId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getAiSuggestion({
    required List<WardrobeItemEntity> items,
  }) async {
    try {
      final models = items.map(WardrobeItemModel.fromEntity).toList();
      final suggestion = await _dataSource.getAiSuggestion(models);
      return Right(suggestion);
    } catch (e) {
      return const Left(ServerFailure('Une erreur est survenue'));
    }
  }

  @override
  Stream<List<AnalysisHistoryEntity>> watchHistory(String userId) =>
      _dataSource.watchHistory(userId);

  @override
  Future<Either<Failure, String>> logAnalysis({
    required String userId,
    required AnalysisHistoryEntity entry,
  }) async {
    try {
      final model = AnalysisHistoryModel(
        id: entry.id,
        categorie: entry.categorie,
        couleur: entry.couleur,
        description: entry.description,
        confidence: entry.confidence,
        analyzedAt: entry.analyzedAt,
        savedToWardrobe: entry.savedToWardrobe,
      );
      final id = await _dataSource.logAnalysis(userId, model);
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markHistoryAsSaved({
    required String userId,
    required String historyId,
  }) async {
    try {
      await _dataSource.markHistoryAsSaved(userId, historyId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
