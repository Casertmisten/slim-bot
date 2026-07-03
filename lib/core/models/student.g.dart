// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Student _$StudentFromJson(Map<String, dynamic> json) => Student(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  gender: $enumDecode(_$GenderEnumMap, json['gender']),
  age: (json['age'] as num).toInt(),
  heightCm: (json['height_cm'] as num).toDouble(),
  targetWeightKg: (json['target_weight_kg'] as num).toDouble(),
  startDate: DateTime.parse(json['start_date'] as String),
  notes: json['notes'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$StudentToJson(Student instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'gender': _$GenderEnumMap[instance.gender]!,
  'age': instance.age,
  'height_cm': instance.heightCm,
  'target_weight_kg': instance.targetWeightKg,
  'start_date': instance.startDate.toIso8601String(),
  'notes': instance.notes,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$GenderEnumMap = {
  Gender.male: 'male',
  Gender.female: 'female',
  Gender.other: 'other',
};

StudentInput _$StudentInputFromJson(Map<String, dynamic> json) => StudentInput(
  name: json['name'] as String,
  gender: $enumDecode(_$GenderEnumMap, json['gender']),
  age: (json['age'] as num).toInt(),
  heightCm: (json['height_cm'] as num).toDouble(),
  targetWeightKg: (json['target_weight_kg'] as num).toDouble(),
  startDate: DateTime.parse(json['start_date'] as String),
  notes: json['notes'] as String? ?? '',
);

Map<String, dynamic> _$StudentInputToJson(StudentInput instance) =>
    <String, dynamic>{
      'name': instance.name,
      'gender': _$GenderEnumMap[instance.gender]!,
      'age': instance.age,
      'height_cm': instance.heightCm,
      'target_weight_kg': instance.targetWeightKg,
      'start_date': instance.startDate.toIso8601String(),
      'notes': instance.notes,
    };
