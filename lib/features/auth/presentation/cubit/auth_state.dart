import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;
  final bool isPasswordResetSent;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
    this.isPasswordResetSent = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
    bool? isPasswordResetSent,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isPasswordResetSent: isPasswordResetSent ?? this.isPasswordResetSent,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, errorMessage, isAuthenticated, isPasswordResetSent];
}
