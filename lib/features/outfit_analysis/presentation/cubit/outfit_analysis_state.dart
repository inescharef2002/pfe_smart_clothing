import 'package:equatable/equatable.dart';
import '../../domain/entities/clothing_analysis_entity.dart';
import '../../domain/entities/outfit_suggestion_entity.dart';
import '../../domain/entities/weather_entity.dart';

class OutfitAnalysisState extends Equatable {
  final ClothingAnalysisEntity? analysisResult;
  final bool isAnalyzing;

  final WeatherEntity? weather;
  final bool isLoadingWeather;

  final List<OutfitSuggestionEntity> suggestions;
  final String conseilGeneral;
  final bool isLoadingSuggestions;

  final String? errorMessage;
  final String? successMessage;

  const OutfitAnalysisState({
    this.analysisResult,
    this.isAnalyzing = false,
    this.weather,
    this.isLoadingWeather = false,
    this.suggestions = const [],
    this.conseilGeneral = '',
    this.isLoadingSuggestions = false,
    this.errorMessage,
    this.successMessage,
  });

  OutfitAnalysisState copyWith({
    ClothingAnalysisEntity? analysisResult,
    bool? isAnalyzing,
    WeatherEntity? weather,
    bool? isLoadingWeather,
    List<OutfitSuggestionEntity>? suggestions,
    String? conseilGeneral,
    bool? isLoadingSuggestions,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearAnalysis = false,
  }) {
    return OutfitAnalysisState(
      analysisResult: clearAnalysis ? null : analysisResult ?? this.analysisResult,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      weather: weather ?? this.weather,
      isLoadingWeather: isLoadingWeather ?? this.isLoadingWeather,
      suggestions: suggestions ?? this.suggestions,
      conseilGeneral: conseilGeneral ?? this.conseilGeneral,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        analysisResult, isAnalyzing,
        weather, isLoadingWeather,
        suggestions, conseilGeneral, isLoadingSuggestions,
        errorMessage, successMessage,
      ];
}
