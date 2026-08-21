import 'package:equatable/equatable.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileState extends Equatable {
  final ProfileEntity? profile;
  final List<Map<String, dynamic>> orders;
  final int wardrobeCount;
  final int cartCount;
  final int ordersCount;
  final bool isLoading;
  final bool isSaving;
  final bool isLoggedOut;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    this.profile,
    this.orders = const [],
    this.wardrobeCount = 0,
    this.cartCount = 0,
    this.ordersCount = 0,
    this.isLoading = false,
    this.isSaving = false,
    this.isLoggedOut = false,
    this.errorMessage,
    this.successMessage,
  });

  ProfileState copyWith({
    ProfileEntity? profile,
    List<Map<String, dynamic>>? orders,
    int? wardrobeCount,
    int? cartCount,
    int? ordersCount,
    bool? isLoading,
    bool? isSaving,
    bool? isLoggedOut,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      orders: orders ?? this.orders,
      wardrobeCount: wardrobeCount ?? this.wardrobeCount,
      cartCount: cartCount ?? this.cartCount,
      ordersCount: ordersCount ?? this.ordersCount,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        profile, orders, wardrobeCount, cartCount, ordersCount,
        isLoading, isSaving, isLoggedOut, errorMessage, successMessage,
      ];
}
