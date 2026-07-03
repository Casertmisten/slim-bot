import 'package:json_annotation/json_annotation.dart';

part 'student.g.dart';

/// 性别
enum Gender {
  @JsonValue('male') male,
  @JsonValue('female') female,
  @JsonValue('other') other;

  String get label {
    switch (this) {
      case Gender.male:
        return '男';
      case Gender.female:
        return '女';
      case Gender.other:
        return '其他';
    }
  }
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Student {
  final int id;
  final String name;
  final Gender gender;
  final int age;
  final double heightCm;
  final double targetWeightKg;
  final DateTime startDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Student({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.targetWeightKg,
    required this.startDate,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);
  Map<String, dynamic> toJson() => _$StudentToJson(this);
}

/// 新建/更新学员请求体（不含 id 与时间戳）
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class StudentInput {
  final String name;
  final Gender gender;
  final int age;
  final double heightCm;
  final double targetWeightKg;
  final DateTime startDate;
  final String notes;

  const StudentInput({
    required this.name,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.targetWeightKg,
    required this.startDate,
    this.notes = '',
  });

  factory StudentInput.fromJson(Map<String, dynamic> json) =>
      _$StudentInputFromJson(json);
  Map<String, dynamic> toJson() => _$StudentInputToJson(this);
}
