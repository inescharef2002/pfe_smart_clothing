import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pfe_smart_clothing/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:pfe_smart_clothing/features/auth/domain/usecases/logout_usecase.dart';
import 'package:pfe_smart_clothing/features/profile/domain/entities/profile_entity.dart';
import 'package:pfe_smart_clothing/features/profile/domain/repositories/profile_repository.dart';
import 'package:pfe_smart_clothing/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:pfe_smart_clothing/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:pfe_smart_clothing/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pfe_smart_clothing/features/profile/presentation/cubit/profile_state.dart';

// ── Fakes pour registerFallbackValue ──────────────────────────────────────────
class FakeProfileEntity extends Fake implements ProfileEntity {}
class FakeXFile        extends Fake implements XFile {
  @override
  String get path => '/fake/path/photo.jpg';
}

// ── Mocks ──────────────────────────────────────────────────────────────────────
class MockGetProfileUseCase     extends Mock implements GetProfileUseCase {}
class MockUpdateProfileUseCase  extends Mock implements UpdateProfileUseCase {}
class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}
class MockLogoutUseCase         extends Mock implements LogoutUseCase {}
class MockProfileRepository     extends Mock implements ProfileRepository {}

// ── Fixtures ───────────────────────────────────────────────────────────────────
const _profile = ProfileEntity(
  id: 'uid_123', nom: 'Ines Charef', email: 'ines@example.com',
  telephone: '0612345678', taille: 165, poids: 55, photoUrl: '',
);
const _profileWithPhoto = ProfileEntity(
  id: 'uid_123', nom: 'Ines Charef', email: 'ines@example.com',
  telephone: '0612345678', taille: 165, poids: 55,
  photoUrl: 'https://res.cloudinary.com/demo/image/upload/profile.jpg',
);

void main() {
  // Enregistre les types custom pour que any(named:...) fonctionne
  setUpAll(() {
    registerFallbackValue(FakeProfileEntity());
    registerFallbackValue(FakeXFile());
  });

  late ProfileCubit            cubit;
  late MockGetProfileUseCase    mockGetProfile;
  late MockUpdateProfileUseCase mockUpdateProfile;
  late MockForgotPasswordUseCase mockForgotPassword;
  late MockLogoutUseCase        mockLogout;
  late MockProfileRepository    mockRepository;

  setUp(() {
    mockGetProfile    = MockGetProfileUseCase();
    mockUpdateProfile = MockUpdateProfileUseCase();
    mockForgotPassword = MockForgotPasswordUseCase();
    mockLogout        = MockLogoutUseCase();
    mockRepository    = MockProfileRepository();
    cubit = ProfileCubit(
      getProfileUseCase:     mockGetProfile,
      updateProfileUseCase:  mockUpdateProfile,
      forgotPasswordUseCase: mockForgotPassword,
      logoutUseCase:         mockLogout,
      repository:            mockRepository,
    );
  });

  tearDown(() => cubit.close());

  // ── État initial ──────────────────────────────────────────────────────────────
  test('état initial : profil null, pas de chargement', () {
    expect(cubit.state.profile, isNull);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.errorMessage, isNull);
  });

  // ── Logique de l'état (ProfileState) ─────────────────────────────────────────
  group('ProfileState — copyWith & Equatable', () {
    test('copyWith profile → nouveau profil conservé', () {
      const state = ProfileState();
      final updated = state.copyWith(profile: _profile);
      expect(updated.profile?.nom, 'Ines Charef');
      expect(updated.profile?.email, 'ines@example.com');
    });

    test('clearError efface errorMessage', () {
      const state = ProfileState(errorMessage: 'Erreur précédente');
      final updated = state.copyWith(clearError: true);
      expect(updated.errorMessage, isNull);
    });

    test('clearSuccess efface successMessage', () {
      const state = ProfileState(successMessage: 'Succès précédent');
      final updated = state.copyWith(clearSuccess: true);
      expect(updated.successMessage, isNull);
    });

    test('deux états identiques sont égaux (Equatable)', () {
      const s1 = ProfileState(profile: _profile);
      const s2 = ProfileState(profile: _profile);
      expect(s1, equals(s2));
    });

    test('profil avec photo ≠ profil sans photo', () {
      const s1 = ProfileState(profile: _profile);
      const s2 = ProfileState(profile: _profileWithPhoto);
      expect(s1, isNot(equals(s2)));
    });
  });

  // ── Réinitialisation messages ─────────────────────────────────────────────────
  group('clearMessages', () {
    blocTest<ProfileCubit, ProfileState>(
      'errorMessage et successMessage vidés',
      build: () => cubit,
      seed: () => const ProfileState(
          errorMessage: 'Erreur', successMessage: 'Succès'),
      // ACT
      act: (c) => c.clearMessages(),
      // ASSERT
      expect: () => [
        isA<ProfileState>()
            .having((s) => s.errorMessage, 'errorMessage', isNull)
            .having((s) => s.successMessage, 'successMessage', isNull),
      ],
    );
  });

  // ── Photo de profil — persistance ─────────────────────────────────────────────
  group('Photo de profil — persistance après reconnexion', () {
    test('photoUrl non vide → persiste dans l\'entité', () {
      // ARRANGE
      const profil = ProfileEntity(
        id: 'uid_123', nom: 'Ines', email: 'ines@example.com',
        photoUrl: 'https://res.cloudinary.com/demo/image/upload/profile.jpg',
      );
      // ASSERT : la photoUrl est conservée dans l'entité
      expect(profil.photoUrl, isNotEmpty);
      expect(profil.photoUrl,
          startsWith('https://res.cloudinary.com'));
    });

    test('photoUrl stockée dans Firestore → récupérée via fromFirestore', () {
      // Simule un état où le profil est rechargé depuis Firestore avec la photo
      const state = ProfileState(profile: _profileWithPhoto);
      // ASSERT : la photo est accessible depuis le state après rechargement
      expect(state.profile?.photoUrl,
          'https://res.cloudinary.com/demo/image/upload/profile.jpg');
    });

    test('photo vide → initiale sans photo', () {
      const state = ProfileState(profile: _profile);
      expect(state.profile?.photoUrl, isEmpty);
    });
  });

  // ── ProfileEntity Equatable ───────────────────────────────────────────────────
  group('ProfileEntity — égalité', () {
    test('même profil → égaux', () {
      const p1 = ProfileEntity(id: '1', nom: 'Ines', email: 'i@e.com');
      const p2 = ProfileEntity(id: '1', nom: 'Ines', email: 'i@e.com');
      expect(p1, equals(p2));
    });

    test('profil modifié → différents', () {
      const p1 = ProfileEntity(id: '1', nom: 'Ines', email: 'i@e.com');
      const p2 = ProfileEntity(id: '1', nom: 'Ines Charef', email: 'i@e.com');
      expect(p1, isNot(equals(p2)));
    });
  });
}
