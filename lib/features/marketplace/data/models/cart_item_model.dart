import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/product_entity.dart';

class CartItemModel extends CartItemEntity {
  const CartItemModel({
    required super.id,
    required super.articleId,
    required super.nom,
    required super.prix,
    super.imageUrl,
    super.quantity,
    super.taille,
    super.couleur,
    super.marque,
    super.categorie,
  });

  factory CartItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CartItemModel(
      id: doc.id,
      articleId: data['articleId'] ?? '',
      nom: data['nom'] ?? '',
      prix: (data['prix'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      quantity: data['quantity'] as int? ?? 1,
      taille: data['taille'] ?? '',
      couleur: data['couleur'] ?? '',
      marque: data['marque'] ?? '',
      categorie: data['categorie'] ?? '',
    );
  }

  factory CartItemModel.fromProduct({
    required ProductEntity product,
    required String taille,
    required String couleur,
    int quantity = 1,
  }) =>
      CartItemModel(
        id: '',
        articleId: product.id,
        nom: product.nom,
        prix: product.prixActuel,
        imageUrl: product.imageUrl,
        quantity: quantity,
        taille: taille,
        couleur: couleur,
        marque: product.marque,
        categorie: product.categorie,
      );

  Map<String, dynamic> toMap() => {
        'articleId': articleId,
        'nom': nom,
        'prix': prix,
        'imageUrl': imageUrl,
        'quantity': quantity,
        'taille': taille,
        'couleur': couleur,
        'marque': marque,
        'categorie': categorie,
      };
}
