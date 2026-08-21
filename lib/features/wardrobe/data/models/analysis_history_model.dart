import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/analysis_history_entity.dart';

class AnalysisHistoryModel extends AnalysisHistoryEntity {
  const AnalysisHistoryModel({
    required super.id,
    required super.categorie,
    required super.couleur,
    required super.description,
    required super.confidence,
    required super.analyzedAt,
    required super.savedToWardrobe,
  });

  factory AnalysisHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AnalysisHistoryModel(
      id: doc.id,
      categorie: d['categorie'] ?? 'Autres',
      couleur: d['couleur'] ?? '',
      description: d['description'] ?? '',
      confidence: (d['confidence'] as num?)?.toDouble() ?? 0.0,
      analyzedAt: (d['analyzedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      savedToWardrobe: d['savedToWardrobe'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'categorie': categorie,
        'couleur': couleur,
        'description': description,
        'confidence': confidence,
        'analyzedAt': FieldValue.serverTimestamp(),
        'savedToWardrobe': savedToWardrobe,
      };
}
