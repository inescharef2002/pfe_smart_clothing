import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/outfit_entity.dart';

class OutfitModel extends OutfitEntity {
  const OutfitModel({
    required super.id,
    required super.nom,
    required super.itemIds,
    super.note,
  });

  factory OutfitModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OutfitModel(
      id: doc.id,
      nom: d['nom'] ?? 'Tenue',
      itemIds: List<String>.from(d['itemIds'] ?? []),
      note: d['note'],
    );
  }

  factory OutfitModel.fromEntity(OutfitEntity e) => OutfitModel(
        id: e.id,
        nom: e.nom,
        itemIds: e.itemIds,
        note: e.note,
      );

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'note': note ?? '',
        'itemIds': itemIds,
      };
}
