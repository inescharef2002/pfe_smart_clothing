import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import 'package:pfe_smart_clothing/features/wardrobe/domain/entities/analysis_history_entity.dart';
import 'package:pfe_smart_clothing/features/wardrobe/domain/entities/outfit_entity.dart';
import 'package:pfe_smart_clothing/features/wardrobe/domain/entities/wardrobe_item_entity.dart';
import 'package:pfe_smart_clothing/features/wardrobe/domain/repositories/wardrobe_repository.dart';
import 'package:pfe_smart_clothing/features/wardrobe/presentation/cubit/wardrobe_cubit.dart';
import 'package:pfe_smart_clothing/features/wardrobe/presentation/cubit/wardrobe_state.dart';

// ── Fakes pour registerFallbackValue ──────────────────────────────────────────
class FakeWardrobeItem extends Fake implements WardrobeItemEntity {}

// ── Mock ───────────────────────────────────────────────────────────────────────
class MockWardrobeRepository extends Mock implements WardrobeRepository {}

// ── Fixtures ───────────────────────────────────────────────────────────────────
const _item1 = WardrobeItemEntity(
  id: 'item_001', nom: 'Chemise bleue', categorie: 'Chemises',
  couleur: 'Bleu', taille: 'M', marque: 'Zara', imageUrl: '', source: 'manual',
);
const _item2 = WardrobeItemEntity(
  id: 'item_002', nom: 'Pantalon noir', categorie: 'Pantalons',
  couleur: 'Noir', taille: '42', marque: 'H&M', imageUrl: '', source: 'manual',
);

void main() {
  // Enregistre les types custom pour que any(named:...) fonctionne
  setUpAll(() {
    registerFallbackValue(FakeWardrobeItem());
  });

  late WardrobeCubit cubit;
  late MockWardrobeRepository mockRepository;

  setUp(() {
    mockRepository = MockWardrobeRepository();
    when(() => mockRepository.watchItems(any()))
        .thenAnswer((_) => const Stream<List<WardrobeItemEntity>>.empty());
    when(() => mockRepository.watchOutfits(any()))
        .thenAnswer((_) => const Stream<List<OutfitEntity>>.empty());
    when(() => mockRepository.watchHistory(any()))
        .thenAnswer((_) => const Stream<List<AnalysisHistoryEntity>>.empty());
    cubit = WardrobeCubit(mockRepository);
  });

  tearDown(() => cubit.close());

  // ── État initial ──────────────────────────────────────────────────────────────
  test('état initial : liste vide, pas de chargement', () {
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.isActionLoading, isFalse);
    expect(cubit.state.errorMessage, isNull);
  });

  // ── Suggestion IA ─────────────────────────────────────────────────────────────
  group('getAiSuggestion — suggestion IA', () {
    blocTest<WardrobeCubit, WardrobeState>(
      'ÉCHEC : garde-robe vide → aiError "Ajoutez des vêtements"',
      build: () => cubit,
      seed: () => const WardrobeState(items: []),
      // ACT
      act: (c) => c.getAiSuggestion(),
      // ASSERT
      expect: () => [
        isA<WardrobeState>().having(
          (s) => s.aiError, 'aiError',
          'Ajoutez des vêtements pour obtenir des suggestions',
        ),
      ],
    );

    blocTest<WardrobeCubit, WardrobeState>(
      'SUCCÈS : garde-robe avec vêtements → suggestion retournée',
      build: () {
        // ARRANGE
        when(() => mockRepository.getAiSuggestion(items: any(named: 'items')))
            .thenAnswer((_) async =>
                const Right('Associez la chemise bleue avec le pantalon noir.'));
        return cubit;
      },
      seed: () => const WardrobeState(items: [_item1, _item2]),
      // ACT
      act: (c) => c.getAiSuggestion(),
      // ASSERT
      expect: () => [
        const WardrobeState(items: [_item1, _item2], isAiLoading: true),
        const WardrobeState(
          items: [_item1, _item2],
          isAiLoading: false,
          aiSuggestion: 'Associez la chemise bleue avec le pantalon noir.',
        ),
      ],
    );

    blocTest<WardrobeCubit, WardrobeState>(
      'ÉCHEC : erreur API → aiError renseigné',
      build: () {
        // ARRANGE
        when(() => mockRepository.getAiSuggestion(items: any(named: 'items')))
            .thenAnswer((_) async =>
                const Left(ServerFailure('Service IA indisponible')));
        return cubit;
      },
      seed: () => const WardrobeState(items: [_item1]),
      // ACT
      act: (c) => c.getAiSuggestion(),
      // ASSERT
      expect: () => [
        const WardrobeState(items: [_item1], isAiLoading: true),
        const WardrobeState(
            items: [_item1],
            isAiLoading: false,
            aiError: 'Service IA indisponible'),
      ],
    );
  });

  // ── Réinitialisation suggestion ───────────────────────────────────────────────
  group('resetAiSuggestion — réinitialisation', () {
    blocTest<WardrobeCubit, WardrobeState>(
      'suggestion réinitialisée → aiSuggestion et aiError vidés',
      build: () => cubit,
      seed: () => const WardrobeState(
          aiSuggestion: 'Ancienne suggestion', aiError: 'Ancienne erreur'),
      // ACT
      act: (c) => c.resetAiSuggestion(),
      // ASSERT
      expect: () => [
        isA<WardrobeState>()
            .having((s) => s.aiSuggestion, 'aiSuggestion', isNull)
            .having((s) => s.aiError, 'aiError', isNull),
      ],
    );
  });

  // ── Logique de l'état (copyWith) ──────────────────────────────────────────────
  group('WardrobeState — copyWith', () {
    test('copyWith items → nouvelle liste conservée', () {
      const state = WardrobeState();
      final updated = state.copyWith(items: [_item1, _item2]);
      expect(updated.items.length, 2);
      expect(updated.items.first.nom, 'Chemise bleue');
    });

    test('clearError efface errorMessage', () {
      const state = WardrobeState(errorMessage: 'Erreur précédente');
      final updated = state.copyWith(clearError: true);
      expect(updated.errorMessage, isNull);
    });

    test('deux états identiques sont égaux (Equatable)', () {
      const s1 = WardrobeState(items: [_item1]);
      const s2 = WardrobeState(items: [_item1]);
      expect(s1, equals(s2));
    });

    test('deux états différents ne sont pas égaux', () {
      const s1 = WardrobeState(items: [_item1]);
      const s2 = WardrobeState(items: [_item1, _item2]);
      expect(s1, isNot(equals(s2)));
    });
  });
}
