import 'package:flutter/material.dart';

final class StudentDetailPage extends StatelessWidget {
  final int id;
  const StudentDetailPage({super.key, required this.id});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('学员详情 $id')));
}
