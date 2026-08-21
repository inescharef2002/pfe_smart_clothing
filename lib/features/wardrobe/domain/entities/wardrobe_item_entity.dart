import 'package:equatable/equatable.dart';

class WardrobeItemEntity extends Equatable {
  final String id;
  final String nom;
  final String categorie;
  final String imageUrl;
  final String marque;
  final String taille;
  final String couleur;
  final String source;

  const WardrobeItemEntity({
    required this.id,
    required this.nom,
    required this.categorie,
    required this.imageUrl,
    required this.marque,
    required this.taille,
    required this.couleur,
    required this.source,
  });

  @override
  List<Object?> get props =>
      [id, nom, categorie, imageUrl, marque, taille, couleur, source];
}
