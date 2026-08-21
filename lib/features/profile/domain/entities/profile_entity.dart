import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String nom;
  final String email;
  final String telephone;
  final int taille;
  final int poids;
  final String photoUrl;

  const ProfileEntity({
    required this.id,
    required this.nom,
    required this.email,
    this.telephone = '',
    this.taille = 0,
    this.poids = 0,
    this.photoUrl = '',
  });

  @override
  List<Object?> get props => [id, nom, email, telephone, taille, poids, photoUrl];
}
