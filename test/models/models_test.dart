import 'package:flutter_test/flutter_test.dart';
import 'package:slim_bot/core/models/models.dart';

void main() {
  test('Student 反序列化（snake_case → 驼峰）', () {
    final json = {
      'id': 1,
      'name': '小王',
      'gender': 'male',
      'age': 30,
      'height_cm': 175.0,
      'target_weight_kg': 70.0,
      'start_date': '2026-07-01T00:00:00',
      'notes': '',
      'created_at': '2026-07-01T00:00:00',
      'updated_at': '2026-07-01T00:00:00',
    };
    final s = Student.fromJson(json);
    expect(s.name, '小王');
    expect(s.gender, Gender.male);
    expect(s.heightCm, 175.0);
  });

  test('WeightRecord 反序列化', () {
    final w = WeightRecord.fromJson({
      'id': 1, 'student_id': 2, 'record_date': '2026-07-01T00:00:00',
      'weight_kg': 80.5, 'note': '', 'created_at': '2026-07-01T00:00:00',
    });
    expect(w.weightKg, 80.5);
  });
}
