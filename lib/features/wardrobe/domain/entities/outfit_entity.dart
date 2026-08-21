import 'package:equatable/equatable.dart';

class OutfitEntity extends Equatable {
  final String id;
  final String nom;
  final List<String> itemIds;
  final String? note;

  const OutfitEntity({
    required this.id,
    required this.nom,
    required this.itemIds,
    this.note,
  });

  @override
  List<Object?> get props => [id, nom, itemIds, note];
}
