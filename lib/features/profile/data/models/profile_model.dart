import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.nom,
    required super.email,
    super.telephone,
    super.taille,
    super.poids,
    super.photoUrl,
  });

  factory ProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProfileModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      email: data['email'] ?? '',
      telephone: data['telephone'] ?? '',
      taille: (data['taille'] as num?)?.toInt() ?? 0,
      poids: (data['poids'] as num?)?.toInt() ?? 0,
      photoUrl: data['photoUrl'] ?? '',
    );
  }

  factory ProfileModel.fromEntity(ProfileEntity e) => ProfileModel(
        id: e.id,
        nom: e.nom,
        email: e.email,
        telephone: e.telephone,
        taille: e.taille,
        poids: e.poids,
        photoUrl: e.photoUrl,
      );

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'email': email,
        'telephone': telephone,
        'taille': taille,
        'poids': poids,
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
