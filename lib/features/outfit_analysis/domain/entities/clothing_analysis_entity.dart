import 'package:equatable/equatable.dart';

class ClothingAnalysisEntity extends Equatable {
  final String nom;
  final String categorie;
  final String couleur;
  final String marque;
  final String taille;
  final String description;
  final double confidence;

  const ClothingAnalysisEntity({
    this.nom = '',
    this.categorie = 'Autres',
    this.couleur = '',
    this.marque = '',
    this.taille = '',
    this.description = '',
    this.confidence = 0,
  });

  @override
  List<Object?> get props =>
      [nom, categorie, couleur, marque, taille, description, confidence];
}
