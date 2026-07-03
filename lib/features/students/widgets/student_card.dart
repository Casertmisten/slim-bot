import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';

/// 学员列表卡片
class StudentCard extends StatelessWidget {
  final Student student;
  const StudentCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0x1A0B6B1D),
          child: Text(student.name.characters.first,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
        title: Text(student.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${student.gender.label} · ${student.age}岁 · 目标 ${student.targetWeightKg}kg'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
        onTap: () => context.push('/students/${student.id}'),
      ),
    );
  }
}
