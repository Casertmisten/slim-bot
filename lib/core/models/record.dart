import 'package:json_annotation/json_annotation.dart';
part 'record.g.dart';

/// 体重记录
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class WeightRecord {
  final int id;
  final int studentId;
  final DateTime recordDate;
  final double weightKg;
  final String note;
  final DateTime createdAt;

  const WeightRecord({
    required this.id,
    required this.studentId,
    required this.recordDate,
    required this.weightKg,
    required this.note,
    required this.createdAt,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) =>
      _$WeightRecordFromJson(json);
  Map<String, dynamic> toJson() => _$WeightRecordToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class WeightInput {
  final DateTime recordDate;
  final double weightKg;
  final String note;

  const WeightInput({
    required this.recordDate,
    required this.weightKg,
    this.note = '',
  });

  factory WeightInput.fromJson(Map<String, dynamic> json) =>
      _$WeightInputFromJson(json);
  Map<String, dynamic> toJson() => _$WeightInputToJson(this);
}

/// 围度 / 体脂记录
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class BodyMetricRecord {
  final int id;
  final int studentId;
  final DateTime recordDate;
  final String metricType;
  final double value;
  final String unit;
  final DateTime createdAt;

  const BodyMetricRecord({
    required this.id,
    required this.studentId,
    required this.recordDate,
    required this.metricType,
    required this.value,
    required this.unit,
    required this.createdAt,
  });

  factory BodyMetricRecord.fromJson(Map<String, dynamic> json) =>
      _$BodyMetricRecordFromJson(json);
  Map<String, dynamic> toJson() => _$BodyMetricRecordToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class BodyMetricInput {
  final DateTime recordDate;
  final String metricType;
  final double value;
  final String unit;

  const BodyMetricInput({
    required this.recordDate,
    required this.metricType,
    required this.value,
    required this.unit,
  });

  factory BodyMetricInput.fromJson(Map<String, dynamic> json) =>
      _$BodyMetricInputFromJson(json);
  Map<String, dynamic> toJson() => _$BodyMetricInputToJson(this);
}

/// 饮食/运动类型
enum LogType {
  @JsonValue('breakfast') breakfast,
  @JsonValue('lunch') lunch,
  @JsonValue('dinner') dinner,
  @JsonValue('snack') snack,
  @JsonValue('exercise') exercise;

  String get label {
    switch (this) {
      case LogType.breakfast:
        return '早餐';
      case LogType.lunch:
        return '午餐';
      case LogType.dinner:
        return '晚餐';
      case LogType.snack:
        return '加餐';
      case LogType.exercise:
        return '运动';
    }
  }
}

/// 饮食 / 运动记录
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DailyLog {
  final int id;
  final int studentId;
  final DateTime logDate;
  final LogType logType;
  final String content;
  final double? calories;
  final DateTime createdAt;

  const DailyLog({
    required this.id,
    required this.studentId,
    required this.logDate,
    required this.logType,
    required this.content,
    this.calories,
    required this.createdAt,
  });

  factory DailyLog.fromJson(Map<String, dynamic> json) =>
      _$DailyLogFromJson(json);
  Map<String, dynamic> toJson() => _$DailyLogToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DailyLogInput {
  final DateTime logDate;
  final LogType logType;
  final String content;
  final double? calories;

  const DailyLogInput({
    required this.logDate,
    required this.logType,
    required this.content,
    this.calories,
  });

  factory DailyLogInput.fromJson(Map<String, dynamic> json) =>
      _$DailyLogInputFromJson(json);
  Map<String, dynamic> toJson() => _$DailyLogInputToJson(this);
}
