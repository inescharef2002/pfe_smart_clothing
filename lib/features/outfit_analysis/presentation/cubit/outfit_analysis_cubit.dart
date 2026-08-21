import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/analyze_clothing_usecase.dart';
import '../../domain/usecases/get_weather_usecase.dart';
import '../../domain/usecases/suggest_outfits_usecase.dart';
import '../../domain/usecases/suggest_weather_outfits_usecase.dart';
import 'outfit_analysis_state.dart';

class OutfitAnalysisCubit extends Cubit<OutfitAnalysisState> {
  final AnalyzeClothingUseCase _analyzeClothing;
  final GetWeatherUseCase _getWeather;
  final SuggestOutfitsUseCase _suggestOutfits;
  final SuggestWeatherOutfitsUseCase _suggestWeatherOutfits;

  OutfitAnalysisCubit({
    required AnalyzeClothingUseCase analyzeClothingUseCase,
    required GetWeatherUseCase getWeatherUseCase,
    required SuggestOutfitsUseCase suggestOutfitsUseCase,
    required SuggestWeatherOutfitsUseCase suggestWeatherOutfitsUseCase,
  })  : _analyzeClothing = analyzeClothingUseCase,
        _getWeather = getWeatherUseCase,
        _suggestOutfits = suggestOutfitsUseCase,
        _suggestWeatherOutfits = suggestWeatherOutfitsUseCase,
        super(const OutfitAnalysisState());

  Future<void> analyzeClothing(XFile imageFile) async {
    emit(state.copyWith(isAnalyzing: true, clearError: true, clearAnalysis: true));
    final result = await _analyzeClothing(imageFile);
    result.fold(
      (f) => emit(state.copyWith(isAnalyzing: false, errorMessage: f.message)),
      (entity) => emit(state.copyWith(isAnalyzing: false, analysisResult: entity)),
    );
  }

  Future<void> loadWeather({String city = 'Tunis', double? lat, double? lon}) async {
    emit(state.copyWith(isLoadingWeather: true, clearError: true));
    final result = await _getWeather(city: city, lat: lat, lon: lon);
    result.fold(
      (f) => emit(state.copyWith(isLoadingWeather: false, errorMessage: f.message)),
      (weather) => emit(state.copyWith(isLoadingWeather: false, weather: weather)),
    );
  }

  Future<void> suggestWeatherOutfits(List<Map<String, dynamic>> wardrobeItems) async {
    if (state.weather == null) return;
    emit(state.copyWith(isLoadingSuggestions: true, clearError: true, suggestions: []));
    final result = await _suggestWeatherOutfits(
      wardrobeItems: wardrobeItems,
      temperature: state.weather!.temperature,
      weatherDescription: state.weather!.description,
      city: state.weather!.city,
    );
    result.fold(
      (f) => emit(state.copyWith(isLoadingSuggestions: false, errorMessage: f.message)),
      (r) => emit(state.copyWith(
        isLoadingSuggestions: false,
        suggestions: r.suggestions,
        conseilGeneral: r.conseilGeneral,
      )),
    );
  }

  Future<void> suggestOccasionOutfits(
    List<Map<String, dynamic>> wardrobeItems,
    String occasion,
  ) async {
    emit(state.copyWith(isLoadingSuggestions: true, clearError: true, suggestions: []));
    final result = await _suggestOutfits(wardrobeItems: wardrobeItems, occasion: occasion);
    result.fold(
      (f) => emit(state.copyWith(isLoadingSuggestions: false, errorMessage: f.message)),
      (suggestions) => emit(state.copyWith(isLoadingSuggestions: false, suggestions: suggestions)),
    );
  }

  void resetSuggestions() => emit(state.copyWith(suggestions: [], conseilGeneral: ''));

  void resetAnalysis() => emit(state.copyWith(clearAnalysis: true));

  void clearMessages() => emit(state.copyWith(clearError: true, clearSuccess: true));
}
