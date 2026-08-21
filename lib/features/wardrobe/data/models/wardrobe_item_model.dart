import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/wardrobe_item_entity.dart';

class WardrobeItemModel extends WardrobeItemEntity {
  const WardrobeItemModel({
    required super.id,
    required super.nom,
    required super.categorie,
    required super.imageUrl,
    required super.marque,
    required super.taille,
    required super.couleur,
    required super.source,
  });

  factory WardrobeItemModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WardrobeItemModel(
      id: doc.id,
      nom: d['nom'] ?? '',
      categorie: d['categorie'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      marque: d['marque'] ?? '',
      taille: d['taille'] ?? '',
      couleur: d['couleur'] ?? '',
      source: d['source'] ?? 'manuel',
    );
  }

  factory WardrobeItemModel.fromEntity(WardrobeItemEntity e) =>
      WardrobeItemModel(
        id: e.id,
        nom: e.nom,
        categorie: e.categorie,
        imageUrl: e.imageUrl,
        marque: e.marque,
        taille: e.taille,
        couleur: e.couleur,
        source: e.source,
      );

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'categorie': categorie,
        'imageUrl': imageUrl,
        'marque': marque,
        'taille': taille,
        'couleur': couleur,
        'source': source,
      };
}
