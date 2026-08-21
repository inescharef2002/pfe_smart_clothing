import 'package:equatable/equatable.dart';
import '../../domain/entities/analysis_history_entity.dart';
import '../../domain/entities/outfit_entity.dart';
import '../../domain/entities/wardrobe_item_entity.dart';

class WardrobeState extends Equatable {
  final List<WardrobeItemEntity> items;
  final List<OutfitEntity> outfits;
  final List<AnalysisHistoryEntity> history;
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;
  final String? aiSuggestion;
  final bool isAiLoading;
  final String? aiError;

  const WardrobeState({
    this.items = const [],
    this.outfits = const [],
    this.history = const [],
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
    this.aiSuggestion,
    this.isAiLoading = false,
    this.aiError,
  });

  WardrobeState copyWith({
    List<WardrobeItemEntity>? items,
    List<OutfitEntity>? outfits,
    List<AnalysisHistoryEntity>? history,
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    String? aiSuggestion,
    bool? isAiLoading,
    String? aiError,
    bool clearError = false,
    bool clearAiSuggestion = false,
    bool clearAiError = false,
  }) {
    return WardrobeState(
      items: items ?? this.items,
      outfits: outfits ?? this.outfits,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      aiSuggestion: clearAiSuggestion ? null : aiSuggestion ?? this.aiSuggestion,
      isAiLoading: isAiLoading ?? this.isAiLoading,
      aiError: clearAiError ? null : aiError ?? this.aiError,
    );
  }

  @override
  List<Object?> get props => [
        items,
        outfits,
        history,
        isLoading,
        isActionLoading,
        errorMessage,
        aiSuggestion,
        isAiLoading,
        aiError,
      ];
}
