import 'package:flutter/foundation.dart';

import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

class CreateProjectScreen extends StatelessWidget {
  const CreateProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project'),
      ),
      body: const Center(
        child: Text('Create Project Screen'),
      ),
    );
  }
}