import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pfe_smart_clothing/features/auth/domain/entities/user_entity.dart';
import 'package:pfe_smart_clothing/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:pfe_smart_clothing/features/auth/domain/usecases/google_signin_usecase.dart';
import 'package:pfe_smart_clothing/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:pfe_smart_clothing/features/auth/domain/usecases/logout_usecase.dart';
import 'package:pfe_smart_clothing/features/auth/domain/usecases/register_usecase.dart';
import 'package:pfe_smart_clothing/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:pfe_smart_clothing/features/auth/presentation/cubit/auth_state.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────────
class MockLoginUseCase          extends Mock implements LoginWithEmailUseCase {}
class MockRegisterUseCase       extends Mock implements RegisterUseCase {}
class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}
class MockLogoutUseCase         extends Mock implements LogoutUseCase {}
class MockGoogleSignInUseCase   extends Mock implements GoogleSignInUseCase {}

void main() {
  late AuthCubit cubit;
  late MockRegisterUseCase mockRegisterUseCase;

  setUp(() {
    mockRegisterUseCase = MockRegisterUseCase();
    cubit = AuthCubit(
      loginUseCase:          MockLoginUseCase(),
      registerUseCase:       mockRegisterUseCase,
      forgotPasswordUseCase: MockForgotPasswordUseCase(),
      logoutUseCase:         MockLogoutUseCase(),
      googleSignInUseCase:   MockGoogleSignInUseCase(),
    );
  });

  tearDown(() => cubit.close());

  // ── Test : inscription valide ──────────────────────────────────────────────────
  blocTest<AuthCubit, AuthState>(
    'user can register and receives welcome email',
    build: () {
      // ARRANGE : préparer un nouvel utilisateur
      when(() => mockRegisterUseCase.call(
            email: 'nouveau@example.com',
            password: 'password123',
            name: 'Nouvel Utilisateur',
          )).thenAnswer((_) async => const Right(
            UserEntity(
              id: 'uid_456',
              email: 'nouveau@example.com',
              name: 'Nouvel Utilisateur',
            ),
          ));
      return cubit;
    },
    // ACT : envoyer une demande d'inscription
    act: (c) => c.signUp('nouveau@example.com', 'password123', 'Nouvel Utilisateur'),
    // ASSERT : vérifier que l'inscription est réussie et l'utilisateur authentifié
    expect: () => [
      const AuthState(isLoading: true),
      const AuthState(isLoading: false, isAuthenticated: true),
    ],
  );
}
