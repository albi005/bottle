import 'package:flutter/material.dart';

import 'package:bottle/state/bottle_controller.dart';
import 'package:bottle/ui/widgets/bottle_detail_widget.dart';

class BottleDetailPage extends StatelessWidget {
  final BottleController controller;

  const BottleDetailPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(controller.name)),
      body: BottleDetailWidget(controller: controller),
    );
  }
}
