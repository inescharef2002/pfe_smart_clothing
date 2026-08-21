import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? name;
  final bool isBlocked;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.isBlocked = false,
  });

  @override
  List<Object?> get props => [id, email, name, isBlocked];
}
