import 'package:flutter/material.dart';

final class StudentEditPage extends StatelessWidget {
  final int? studentId;
  const StudentEditPage({super.key, this.studentId});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(child: Text('学员编辑 ${studentId ?? "新建"}')));
}
