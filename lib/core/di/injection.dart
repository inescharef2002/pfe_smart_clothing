import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

// ====================== OUTFIT ANALYSIS IMPORTS ======================
import '../../features/outfit_analysis/data/datasources/outfit_analysis_datasource.dart';
import '../../features/outfit_analysis/data/repositories/outfit_analysis_repository_impl.dart';
import '../../features/outfit_analysis/domain/repositories/outfit_analysis_repository.dart';
import '../../features/outfit_analysis/domain/usecases/analyze_clothing_usecase.dart';
import '../../features/outfit_analysis/domain/usecases/get_weather_usecase.dart';
import '../../features/outfit_analysis/domain/usecases/suggest_outfits_usecase.dart';
import '../../features/outfit_analysis/domain/usecases/suggest_weather_outfits_usecase.dart';
import '../../features/outfit_analysis/presentation/cubit/outfit_analysis_cubit.dart';

// ====================== AUTH IMPORTS ======================
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/google_signin_usecase.dart';
import '../../features/auth/domain/usecases/login_with_email_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

// ====================== WARDROBE IMPORTS ======================
import '../../features/wardrobe/data/datasources/wardrobe_remote_datasource.dart';
import '../../features/wardrobe/data/repositories/wardrobe_repository_impl.dart';
import '../../features/wardrobe/domain/repositories/wardrobe_repository.dart';
import '../../features/wardrobe/presentation/cubit/wardrobe_cubit.dart';

// ====================== PROFILE IMPORTS ======================
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile_usecase.dart';
import '../../features/profile/domain/usecases/update_profile_usecase.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';

// ====================== MARKETPLACE IMPORTS ======================
import '../../features/marketplace/data/datasources/marketplace_remote_datasource.dart';
import '../../features/marketplace/data/repositories/marketplace_repository_impl.dart';
import '../../features/marketplace/domain/repositories/marketplace_repository.dart';
import '../../features/marketplace/presentation/cubit/marketplace_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── Auth ────────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    ),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl<AuthRemoteDataSource>()),
  );

  sl.registerFactory(() => LoginWithEmailUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => ForgotPasswordUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => GetCurrentUserUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => GoogleSignInUseCase(sl<AuthRepository>()));

  sl.registerFactory(() => AuthCubit(
        loginUseCase: sl<LoginWithEmailUseCase>(),
        registerUseCase: sl<RegisterUseCase>(),
        forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
        logoutUseCase: sl<LogoutUseCase>(),
        googleSignInUseCase: sl<GoogleSignInUseCase>(),
      ));

  // ── Wardrobe ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<WardrobeDataSource>(
    () => WardrobeRemoteDataSource(
      firestore: FirebaseFirestore.instance,
    ),
  );

  sl.registerLazySingleton<WardrobeRepository>(
    () => WardrobeRepositoryImpl(sl<WardrobeDataSource>()),
  );

  sl.registerFactory<WardrobeCubit>(
    () => WardrobeCubit(sl<WardrobeRepository>()),
  );

  // ── Profile ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileDataSource>(
    () => ProfileRemoteDataSource(firestore: FirebaseFirestore.instance),
  );

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl<ProfileDataSource>()),
  );

  sl.registerFactory(() => GetProfileUseCase(sl<ProfileRepository>()));
  sl.registerFactory(() => UpdateProfileUseCase(sl<ProfileRepository>()));

  sl.registerFactory(() => ProfileCubit(
        getProfileUseCase: sl<GetProfileUseCase>(),
        updateProfileUseCase: sl<UpdateProfileUseCase>(),
        forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
        logoutUseCase: sl<LogoutUseCase>(),
        repository: sl<ProfileRepository>(),
      ));

  // ── Marketplace ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<MarketplaceDataSource>(
    () => MarketplaceRemoteDataSource(firestore: FirebaseFirestore.instance),
  );

  sl.registerLazySingleton<MarketplaceRepository>(
    () => MarketplaceRepositoryImpl(sl<MarketplaceDataSource>()),
  );

  sl.registerFactory<MarketplaceCubit>(
    () => MarketplaceCubit(sl<MarketplaceRepository>()),
  );

  // ── Outfit Analysis ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<OutfitAnalysisDataSource>(
    () => OutfitAnalysisRemoteDataSource(),
  );

  sl.registerLazySingleton<OutfitAnalysisRepository>(
    () => OutfitAnalysisRepositoryImpl(sl<OutfitAnalysisDataSource>()),
  );

  sl.registerFactory(() => AnalyzeClothingUseCase(sl<OutfitAnalysisRepository>()));
  sl.registerFactory(() => GetWeatherUseCase(sl<OutfitAnalysisRepository>()));
  sl.registerFactory(() => SuggestOutfitsUseCase(sl<OutfitAnalysisRepository>()));
  sl.registerFactory(() => SuggestWeatherOutfitsUseCase(sl<OutfitAnalysisRepository>()));

  sl.registerFactory<OutfitAnalysisCubit>(
    () => OutfitAnalysisCubit(
      analyzeClothingUseCase: sl<AnalyzeClothingUseCase>(),
      getWeatherUseCase: sl<GetWeatherUseCase>(),
      suggestOutfitsUseCase: sl<SuggestOutfitsUseCase>(),
      suggestWeatherOutfitsUseCase: sl<SuggestWeatherOutfitsUseCase>(),
    ),
  );
}
