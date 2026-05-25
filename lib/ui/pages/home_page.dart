import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'package:bottle/state/app_state.dart';
import 'package:bottle/state/bottle_controller.dart';
import 'package:bottle/ui/widgets/bottle_list_tile.dart';
import 'package:bottle/ui/widgets/bottle_detail_widget.dart';
import 'package:bottle/ui/pages/bottle_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LARQ Bottles')),
      body: Watch((context) {
        final bottles = activeBottles.value;
        final selectedIdx = selectedBottleIndex.value;
        final isWide = MediaQuery.of(context).size.width > 600;

        if (bottles.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Scanning for bottles...'),
              ],
            ),
          );
        }

        if (isWide) {
          return Row(children: [
            SizedBox(
              width: 250,
              child: _BottleListWidget(
                bottles: bottles,
                selectedIndex: selectedIdx,
                onSelect: (i) => selectedBottleIndex.value = i,
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: selectedIdx != null && selectedIdx < bottles.length
                  ? BottleDetailWidget(controller: bottles[selectedIdx])
                  : const Center(child: Text('Select a bottle')),
            ),
          ]);
        } else {
          return _BottleListWidget(
            bottles: bottles,
            selectedIndex: selectedIdx,
            onSelect: (i) {
              selectedBottleIndex.value = i;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BottleDetailPage(controller: bottles[i]),
                ),
              );
            },
          );
        }
      }),
    );
  }
}

class _BottleListWidget extends StatelessWidget {
  final List<BottleController> bottles;
  final int? selectedIndex;
  final void Function(int) onSelect;

  const _BottleListWidget({
    required this.bottles,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: bottles.length,
      itemBuilder: (context, index) {
        return BottleListTile(
          controller: bottles[index],
          selected: index == selectedIndex,
          onTap: () => onSelect(index),
        );
      },
    );
  }
}
