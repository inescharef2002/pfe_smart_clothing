import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String nom;
  final String description;
  final double prix;
  final double? prixPromo;
  final String imageUrl;
  final String imageUrl2;
  final String imageUrl3;
  final String categorie;
  final String marque;
  final bool promo;
  final bool nouveaute;
  final bool disponible;
  final List<dynamic> tailles;
  final List<Map<String, dynamic>> couleurs;
  final int? stock;

  const ProductEntity({
    required this.id,
    required this.nom,
    this.description = '',
    required this.prix,
    this.prixPromo,
    this.imageUrl = '',
    this.imageUrl2 = '',
    this.imageUrl3 = '',
    this.categorie = '',
    this.marque = '',
    this.promo = false,
    this.nouveaute = false,
    this.disponible = true,
    this.tailles = const [],
    this.couleurs = const [],
    this.stock,
  });

  double get prixActuel =>
      (promo && prixPromo != null) ? prixPromo! : prix;

  @override
  List<Object?> get props => [
        id, nom, description, prix, prixPromo, imageUrl, imageUrl2, imageUrl3,
        categorie, marque, promo, nouveaute, disponible, stock,
      ];
}
