import 'package:equatable/equatable.dart';

class WeatherEntity extends Equatable {
  final int temperature;
  final String description;
  final String icon;
  final int humidity;
  final String city;

  const WeatherEntity({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.city,
  });

  @override
  List<Object?> get props =>
      [temperature, description, icon, humidity, city];
}
