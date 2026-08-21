import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/analysis_history_entity.dart';
import '../../domain/entities/outfit_entity.dart';
import '../../domain/entities/wardrobe_item_entity.dart';
import '../../domain/repositories/wardrobe_repository.dart';
import 'wardrobe_state.dart';

class WardrobeCubit extends Cubit<WardrobeState> {
  final WardrobeRepository _repository;
  StreamSubscription<List<WardrobeItemEntity>>? _itemsSub;
  StreamSubscription<List<OutfitEntity>>? _outfitsSub;
  StreamSubscription<List<AnalysisHistoryEntity>>? _historySub;

  WardrobeCubit(this._repository) : super(const WardrobeState());

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // ✅ Annuler tous les streams avant déconnexion
  void cancelStreams() {
    _itemsSub?.cancel();
    _outfitsSub?.cancel();
    _historySub?.cancel();
    _itemsSub = null;
    _outfitsSub = null;
    _historySub = null;
  }

  void loadWardrobe() {
    final uid = _userId;
    if (uid == null) return;

    emit(state.copyWith(isLoading: true));
    _itemsSub?.cancel();
    _outfitsSub?.cancel();
    _historySub?.cancel();

    _itemsSub = _repository.watchItems(uid).listen(
          (items) => emit(state.copyWith(items: items, isLoading: false)),
          onError: (e) => emit(
              state.copyWith(errorMessage: e.toString(), isLoading: false)),
        );

    _outfitsSub = _repository.watchOutfits(uid).listen(
          (outfits) => emit(state.copyWith(outfits: outfits)),
          onError: (e) => emit(state.copyWith(errorMessage: e.toString())),
        );

    _historySub = _repository.watchHistory(uid).listen(
          (history) => emit(state.copyWith(history: history)),
          onError: (_) {},
        );
  }

  Future<void> addItem(WardrobeItemEntity item, {XFile? imageFile}) async {
    final uid = _userId;
    if (uid == null) {
      emit(state.copyWith(
          errorMessage: 'Vous devez être connecté pour ajouter un vêtement'));
      return;
    }
    emit(state.copyWith(isActionLoading: true, clearError: true));
    final result = await _repository.addItem(
        userId: uid, item: item, imageFile: imageFile);
    result.fold(
      (f) =>
          emit(state.copyWith(isActionLoading: false, errorMessage: f.message)),
      (_) => emit(state.copyWith(isActionLoading: false)),
    );
  }

  Future<void> updateItem(WardrobeItemEntity item, {XFile? imageFile}) async {
    final uid = _userId;
    if (uid == null) return;
    emit(state.copyWith(isActionLoading: true, clearError: true));
    final result = await _repository.updateItem(
        userId: uid, item: item, imageFile: imageFile);
    result.fold(
      (f) =>
          emit(state.copyWith(isActionLoading: false, errorMessage: f.message)),
      (_) => emit(state.copyWith(isActionLoading: false)),
    );
  }

  Future<void> deleteItem(String itemId) async {
    final uid = _userId;
    if (uid == null) return;
    final result = await _repository.deleteItem(userId: uid, itemId: itemId);
    result.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (_) {},
    );
  }

  Future<void> addOutfit(OutfitEntity outfit) async {
    final uid = _userId;
    if (uid == null) return;
    emit(state.copyWith(isActionLoading: true, clearError: true));
    final result = await _repository.addOutfit(userId: uid, outfit: outfit);
    result.fold(
      (f) =>
          emit(state.copyWith(isActionLoading: false, errorMessage: f.message)),
      (_) => emit(state.copyWith(isActionLoading: false)),
    );
  }

  Future<void> deleteOutfit(String outfitId) async {
    final uid = _userId;
    if (uid == null) return;
    final result =
        await _repository.deleteOutfit(userId: uid, outfitId: outfitId);
    result.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (_) {},
    );
  }

  Future<void> getAiSuggestion() async {
    if (state.items.isEmpty) {
      emit(state.copyWith(
          aiError: 'Ajoutez des vêtements pour obtenir des suggestions'));
      return;
    }
    emit(state.copyWith(
        isAiLoading: true, clearAiSuggestion: true, clearAiError: true));
    final result = await _repository.getAiSuggestion(items: state.items);
    result.fold(
      (f) => emit(state.copyWith(isAiLoading: false, aiError: f.message)),
      (s) => emit(state.copyWith(isAiLoading: false, aiSuggestion: s)),
    );
  }

  void resetAiSuggestion() =>
      emit(state.copyWith(clearAiSuggestion: true, clearAiError: true));

  Future<String?> logAnalysis({
    required String categorie,
    required String couleur,
    required String description,
    required double confidence,
  }) async {
    final uid = _userId;
    if (uid == null) return null;
    final entry = AnalysisHistoryEntity(
      id: '',
      categorie: categorie,
      couleur: couleur,
      description: description,
      confidence: confidence,
      analyzedAt: DateTime.now(),
      savedToWardrobe: false,
    );
    final result = await _repository.logAnalysis(userId: uid, entry: entry);
    return result.fold((_) => null, (id) => id);
  }

  Future<void> markHistoryAsSaved(String historyId) async {
    final uid = _userId;
    if (uid == null) return;
    await _repository.markHistoryAsSaved(userId: uid, historyId: historyId);
  }

  @override
  Future<void> close() {
    cancelStreams();
    return super.close();
  }
}
