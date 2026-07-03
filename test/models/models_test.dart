import 'package:flutter_test/flutter_test.dart';
import 'package:slim_bot/core/models/models.dart';

void main() {
  test('Student 反序列化（snake_case → 驼峰，日期为后端 date 格式）', () {
    // 后端 Pydantic date 字段序列化为 "2026-07-01"（无时间分量）
    final json = {
      'id': 1,
      'name': '小王',
      'gender': 'male',
      'age': 30,
      'height_cm': 175.0,
      'target_weight_kg': 70.0,
      'start_date': '2026-07-01',
      'notes': '',
      'created_at': '2026-07-01T00:00:00',
      'updated_at': '2026-07-01T00:00:00',
    };
    final s = Student.fromJson(json);
    expect(s.name, '小王');
    expect(s.gender, Gender.male);
    expect(s.heightCm, 175.0);
    expect(s.startDate.year, 2026);
  });

  test('WeightRecord 反序列化', () {
    final w = WeightRecord.fromJson({
      'id': 1, 'student_id': 2, 'record_date': '2026-07-01',
      'weight_kg': 80.5, 'note': '', 'created_at': '2026-07-01T00:00:00',
    });
    expect(w.weightKg, 80.5);
    expect(w.studentId, 2);
  });

  test('Student round-trip（toJson → fromJson 稳定）', () {
    final s = Student(
      id: 1, name: '小王', gender: Gender.female, age: 28,
      heightCm: 162.0, targetWeightKg: 55.0,
      startDate: DateTime(2026, 7, 1), notes: '备注',
      createdAt: DateTime(2026, 7, 1), updatedAt: DateTime(2026, 7, 2),
    );
    final encoded = s.toJson();
    expect(encoded['height_cm'], 162.0);
    expect(encoded['target_weight_kg'], 55.0);
    final decoded = Student.fromJson(encoded);
    expect(decoded.name, s.name);
    expect(decoded.gender, s.gender);
    expect(decoded.heightCm, s.heightCm);
  });
}
