import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../../auth/domain/usecases/forgot_password_usecase.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileUseCase _getProfile;
  final UpdateProfileUseCase _updateProfile;
  final ForgotPasswordUseCase _forgotPassword;
  final LogoutUseCase _logout;
  final ProfileRepository _repository;

  StreamSubscription? _ordersSub;
  StreamSubscription? _wardrobeSub;
  StreamSubscription? _cartSub;
  StreamSubscription? _ordersCountSub;

  ProfileCubit({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required LogoutUseCase logoutUseCase,
    required ProfileRepository repository,
  })  : _getProfile = getProfileUseCase,
        _updateProfile = updateProfileUseCase,
        _forgotPassword = forgotPasswordUseCase,
        _logout = logoutUseCase,
        _repository = repository,
        super(const ProfileState());

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> loadProfile() async {
    final uid = _userId;
    if (uid == null) return;
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _getProfile.call(uid);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (profile) {
        emit(state.copyWith(isLoading: false, profile: profile));
        _subscribeStreams(uid);
      },
    );
  }

  void _subscribeStreams(String uid) {
    _ordersSub?.cancel();
    _wardrobeSub?.cancel();
    _cartSub?.cancel();
    _ordersCountSub?.cancel();

    _ordersSub = _repository
        .watchOrders(uid)
        .listen((orders) => emit(state.copyWith(orders: orders)));
    _wardrobeSub = _repository
        .watchWardrobeCount(uid)
        .listen((c) => emit(state.copyWith(wardrobeCount: c)));
    _cartSub = _repository
        .watchCartCount(uid)
        .listen((c) => emit(state.copyWith(cartCount: c)));
    _ordersCountSub = _repository
        .watchOrdersCount(uid)
        .listen((c) => emit(state.copyWith(ordersCount: c)));
  }

  Future<void> uploadPhoto(XFile imageFile) async {
    final uid = _userId;
    if (uid == null) return;
    emit(state.copyWith(isSaving: true, clearError: true));

    final result = await _repository.uploadPhoto(uid, imageFile);
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, errorMessage: f.message)),
      (url) async {
        // Recharge le profil pour afficher la nouvelle photoUrl depuis Firestore
        final fresh = await _getProfile.call(uid);
        fresh.fold(
          (_) => emit(state.copyWith(isSaving: false, successMessage: 'Photo mise à jour')),
          (p) => emit(state.copyWith(
              isSaving: false, successMessage: 'Photo mise à jour', profile: p)),
        );
      },
    );
  }

  Future<void> updateProfile({
    required String nom,
    required String telephone,
    required int taille,
    required int poids,
    XFile? imageFile,
  }) async {
    final uid = _userId;
    if (uid == null || state.profile == null) return;
    emit(state.copyWith(isSaving: true, clearError: true));

    final updated = ProfileEntity(
      id: uid,
      nom: nom,
      email: state.profile!.email,
      telephone: telephone,
      taille: taille,
      poids: poids,
      photoUrl: state.profile!.photoUrl,
    );

    final result = await _updateProfile.call(
      userId: uid,
      profile: updated,
      imageFile: imageFile,
    );
    result.fold(
      (f) => emit(state.copyWith(isSaving: false, errorMessage: f.message)),
      (_) async {
        emit(state.copyWith(isSaving: false, successMessage: 'Profil mis à jour'));
        // Recharge depuis Firestore pour récupérer la vraie photoUrl uploadée
        final fresh = await _getProfile.call(uid);
        fresh.fold((_) => null, (p) => emit(state.copyWith(profile: p)));
      },
    );
  }

  Future<void> sendPasswordReset() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    final result = await _forgotPassword.call(email: email);
    result.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (_) => emit(state.copyWith(
          successMessage: 'Email de réinitialisation envoyé à $email')),
    );
  }

  Future<void> logout() async {
    await _logout.call();
    emit(state.copyWith(isLoggedOut: true));
  }

  void clearMessages() =>
      emit(state.copyWith(clearError: true, clearSuccess: true));

  @override
  Future<void> close() {
    _ordersSub?.cancel();
    _wardrobeSub?.cancel();
    _cartSub?.cancel();
    _ordersCountSub?.cancel();
    return super.close();
  }
}
