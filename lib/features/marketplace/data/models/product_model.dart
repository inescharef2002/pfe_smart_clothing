import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.nom,
    super.description,
    required super.prix,
    super.prixPromo,
    super.imageUrl,
    super.imageUrl2,
    super.imageUrl3,
    super.categorie,
    super.marque,
    super.promo,
    super.nouveaute,
    super.disponible,
    super.tailles,
    super.couleurs,
    super.stock,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      description: data['description'] ?? '',
      prix: (data['prix'] as num?)?.toDouble() ?? 0.0,
      prixPromo: (data['prixPromo'] as num?)?.toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      imageUrl2: data['imageUrl2'] ?? '',
      imageUrl3: data['imageUrl3'] ?? '',
      categorie: data['categorie'] ?? '',
      marque: data['marque'] ?? '',
      promo: data['promo'] == true,
      nouveaute: data['nouveaute'] == true,
      disponible: data['disponible'] != false,
      tailles: List<dynamic>.from(data['tailles'] ?? []),
      couleurs: (data['couleurs'] as List<dynamic>?)
              ?.map((c) => Map<String, dynamic>.from(c as Map))
              .toList() ??
          [],
      stock: (data['stock'] as num?)?.toInt(),
    );
  }
}
