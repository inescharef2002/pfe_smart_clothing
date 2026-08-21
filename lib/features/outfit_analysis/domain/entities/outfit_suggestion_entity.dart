import 'package:equatable/equatable.dart';

class OutfitSuggestionEntity extends Equatable {
  final String nom;
  final List<String> pieces;
  final List<String> images;   // imageUrl de chaque pièce (même ordre que pieces)
  final String conseil;
  final String occasion;
  final String emoji;
  final double score;

  const OutfitSuggestionEntity({
    this.nom = '',
    this.pieces = const [],
    this.images = const [],
    this.conseil = '',
    this.occasion = '',
    this.emoji = '👗',
    this.score = 0,
  });

  @override
  List<Object?> get props => [nom, pieces, images, conseil, occasion, emoji, score];
}
