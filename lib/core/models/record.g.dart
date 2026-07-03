// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeightRecord _$WeightRecordFromJson(Map<String, dynamic> json) => WeightRecord(
  id: (json['id'] as num).toInt(),
  studentId: (json['student_id'] as num).toInt(),
  recordDate: DateTime.parse(json['record_date'] as String),
  weightKg: (json['weight_kg'] as num).toDouble(),
  note: json['note'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$WeightRecordToJson(WeightRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'record_date': instance.recordDate.toIso8601String(),
      'weight_kg': instance.weightKg,
      'note': instance.note,
      'created_at': instance.createdAt.toIso8601String(),
    };

WeightInput _$WeightInputFromJson(Map<String, dynamic> json) => WeightInput(
  recordDate: DateTime.parse(json['record_date'] as String),
  weightKg: (json['weight_kg'] as num).toDouble(),
  note: json['note'] as String? ?? '',
);

Map<String, dynamic> _$WeightInputToJson(WeightInput instance) =>
    <String, dynamic>{
      'record_date': instance.recordDate.toIso8601String(),
      'weight_kg': instance.weightKg,
      'note': instance.note,
    };

BodyMetricRecord _$BodyMetricRecordFromJson(Map<String, dynamic> json) =>
    BodyMetricRecord(
      id: (json['id'] as num).toInt(),
      studentId: (json['student_id'] as num).toInt(),
      recordDate: DateTime.parse(json['record_date'] as String),
      metricType: json['metric_type'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$BodyMetricRecordToJson(BodyMetricRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'record_date': instance.recordDate.toIso8601String(),
      'metric_type': instance.metricType,
      'value': instance.value,
      'unit': instance.unit,
      'created_at': instance.createdAt.toIso8601String(),
    };

BodyMetricInput _$BodyMetricInputFromJson(Map<String, dynamic> json) =>
    BodyMetricInput(
      recordDate: DateTime.parse(json['record_date'] as String),
      metricType: json['metric_type'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
    );

Map<String, dynamic> _$BodyMetricInputToJson(BodyMetricInput instance) =>
    <String, dynamic>{
      'record_date': instance.recordDate.toIso8601String(),
      'metric_type': instance.metricType,
      'value': instance.value,
      'unit': instance.unit,
    };

DailyLog _$DailyLogFromJson(Map<String, dynamic> json) => DailyLog(
  id: (json['id'] as num).toInt(),
  studentId: (json['student_id'] as num).toInt(),
  logDate: DateTime.parse(json['log_date'] as String),
  logType: $enumDecode(_$LogTypeEnumMap, json['log_type']),
  content: json['content'] as String,
  calories: (json['calories'] as num?)?.toDouble(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$DailyLogToJson(DailyLog instance) => <String, dynamic>{
  'id': instance.id,
  'student_id': instance.studentId,
  'log_date': instance.logDate.toIso8601String(),
  'log_type': _$LogTypeEnumMap[instance.logType]!,
  'content': instance.content,
  'calories': instance.calories,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$LogTypeEnumMap = {
  LogType.breakfast: 'breakfast',
  LogType.lunch: 'lunch',
  LogType.dinner: 'dinner',
  LogType.snack: 'snack',
  LogType.exercise: 'exercise',
};

DailyLogInput _$DailyLogInputFromJson(Map<String, dynamic> json) =>
    DailyLogInput(
      logDate: DateTime.parse(json['log_date'] as String),
      logType: $enumDecode(_$LogTypeEnumMap, json['log_type']),
      content: json['content'] as String,
      calories: (json['calories'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$DailyLogInputToJson(DailyLogInput instance) =>
    <String, dynamic>{
      'log_date': instance.logDate.toIso8601String(),
      'log_type': _$LogTypeEnumMap[instance.logType]!,
      'content': instance.content,
      'calories': instance.calories,
    };
