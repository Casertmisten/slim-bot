import 'package:flutter/material.dart';
import '../../../core/models/models.dart';

/// 学员详情头部摘要
class StudentHeader extends StatelessWidget {
  final Student student;
  const StudentHeader({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          CircleAvatar(radius: 24, child: Text(student.name.characters.first)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${student.gender.label} · ${student.age}岁 · ${student.heightCm}cm',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(
                    '目标 ${student.targetWeightKg}kg · 起 ${student.startDate.year}-${student.startDate.month}-${student.startDate.day}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
