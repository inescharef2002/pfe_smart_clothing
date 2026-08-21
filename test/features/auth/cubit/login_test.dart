import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import 'package:pfe_smart_clothing/features/auth/domain/entities/user_entity.dart';
import 'package:pfe_smart_clothing/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:pfe_smart_clothing/features/auth/domain/usecases/google_signin_usecase.dart';
import 'package:pfe_smart_clothing/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:pfe_smart_clothing/features/auth/domain/usecases/logout_usecase.dart';
import 'package:pfe_smart_clothing/features/auth/domain/usecases/register_usecase.dart';
import 'package:pfe_smart_clothing/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:pfe_smart_clothing/features/auth/presentation/cubit/auth_state.dart';

//  Mocks 
class MockLoginUseCase          extends Mock implements LoginWithEmailUseCase {}
class MockRegisterUseCase       extends Mock implements RegisterUseCase {}
class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}
class MockLogoutUseCase         extends Mock implements LogoutUseCase {}
class MockGoogleSignInUseCase   extends Mock implements GoogleSignInUseCase {}

void main() {
  late AuthCubit cubit;
  late MockLoginUseCase mockLoginUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    cubit = AuthCubit(
      loginUseCase:          mockLoginUseCase,
      registerUseCase:       MockRegisterUseCase(),
      forgotPasswordUseCase: MockForgotPasswordUseCase(),
      logoutUseCase:         MockLogoutUseCase(),
      googleSignInUseCase:   MockGoogleSignInUseCase(),
    );
  });

  tearDown(() => cubit.close());

  //  connexion avec identifiants valides 
  blocTest<AuthCubit, AuthState>(
    'user can login with valid credentials',
    build: () {
      when(() => mockLoginUseCase.call(
            email: 'test@example.com',
            password: 'password123',
          )).thenAnswer((_) async => const Right(
            UserEntity(id: 'uid_1', email: 'test@example.com', name: 'Test User'),
          ));
      return cubit;
    },
    act: (c) => c.signIn('test@example.com', 'password123'),
    // ASSERT : vérifier que la connexion est réussie
    expect: () => [
      const AuthState(isLoading: true),
      const AuthState(isLoading: false, isAuthenticated: true),
    ],
  );

  //  connexion avec identifiants invalides 
  blocTest<AuthCubit, AuthState>(
    'user cannot login with invalid credentials',
    build: () {
      //  mauvais mot de passe
      when(() => mockLoginUseCase.call(
            email: 'test@example.com',
            password: 'wrong-password',
          )).thenAnswer((_) async =>
              const Left(ServerFailure('Invalid credentials')));
      return cubit;
    },
    //  se connecter avec un mauvais mot de passe
    act: (c) => c.signIn('test@example.com', 'wrong-password'),
    // ASSERT : vérifier que l'authentification échoue
    expect: () => [
      const AuthState(isLoading: true),
      const AuthState(isLoading: false, errorMessage: 'Invalid credentials'),
    ],
  );
}
