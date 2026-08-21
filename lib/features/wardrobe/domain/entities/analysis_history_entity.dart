import 'package:equatable/equatable.dart';

class AnalysisHistoryEntity extends Equatable {
  final String id;
  final String categorie;
  final String couleur;
  final String description;
  final double confidence;
  final DateTime analyzedAt;
  final bool savedToWardrobe;

  const AnalysisHistoryEntity({
    required this.id,
    required this.categorie,
    required this.couleur,
    required this.description,
    required this.confidence,
    required this.analyzedAt,
    required this.savedToWardrobe,
  });

  @override
  List<Object?> get props =>
      [id, categorie, couleur, description, confidence, analyzedAt, savedToWardrobe];
}
