import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_with_email_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/google_signin_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginWithEmailUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final LogoutUseCase _logoutUseCase;
  final GoogleSignInUseCase _googleSignInUseCase;

  AuthCubit({
    required LoginWithEmailUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required LogoutUseCase logoutUseCase,
    required GoogleSignInUseCase googleSignInUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _forgotPasswordUseCase = forgotPasswordUseCase,
        _logoutUseCase = logoutUseCase,
        _googleSignInUseCase = googleSignInUseCase,
        super(const AuthState());

  Future<void> signIn(String email, String password) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _loginUseCase.call(email: email, password: password);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (_) => emit(state.copyWith(isLoading: false, isAuthenticated: true)),
    );
  }

  Future<void> signUp(String email, String password, String name) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _registerUseCase.call(
        email: email, password: password, name: name);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (_) => emit(state.copyWith(isLoading: false, isAuthenticated: true)),
    );
  }

  Future<void> sendPasswordReset(String email) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _forgotPasswordUseCase.call(email: email);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (_) => emit(state.copyWith(isLoading: false, isPasswordResetSent: true)),
    );
  }

  Future<void> signOut() async {
    try {
      await _logoutUseCase.call();
    } catch (_) {
      // Ignorer les erreurs de déconnexion
    } finally {
      // ✅ Toujours réinitialiser l'état même si erreur
      emit(const AuthState());
    }
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _googleSignInUseCase.call();
    result.fold(
      (f) {
        // ✅ Si annulé par l'utilisateur → pas d'erreur affichée
        final msg = f.message.toLowerCase();
        if (msg.contains('annulée') ||
            msg.contains('canceled') ||
            msg.contains('cancelled')) {
          emit(state.copyWith(isLoading: false));
          return;
        }
        emit(state.copyWith(isLoading: false, errorMessage: f.message));
      },
      (_) => emit(state.copyWith(isLoading: false, isAuthenticated: true)),
    );
  }

  void resetState() => emit(const AuthState());
}
