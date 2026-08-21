import 'package:equatable/equatable.dart';

class CartItemEntity extends Equatable {
  final String id;
  final String articleId;
  final String nom;
  final double prix;
  final String imageUrl;
  final int quantity;
  final String taille;
  final String couleur;
  final String marque;
  final String categorie;

  const CartItemEntity({
    required this.id,
    required this.articleId,
    required this.nom,
    required this.prix,
    this.imageUrl = '',
    this.quantity = 1,
    this.taille = '',
    this.couleur = '',
    this.marque = '',
    this.categorie = '',
  });

  double get total => prix * quantity;

  @override
  List<Object?> get props => [
        id, articleId, nom, prix, imageUrl,
        quantity, taille, couleur, marque, categorie,
      ];
}
