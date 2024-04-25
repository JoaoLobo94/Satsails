import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_button/group_button.dart';

final selectedButtonProvider = StateProvider<String>((ref) => "Stablecoin Swap");
final groupButtonControllerProvider = Provider<GroupButtonController>((ref) {
  return GroupButtonController(selectedIndex: 0);
});

class ButtonPicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(groupButtonControllerProvider);

    return GroupButton(
      isRadio: true,
      controller: controller,
      onSelected: (index, isSelected, isLongPress) {
        switch (index) {
          case 0:
            ref.read(selectedButtonProvider.notifier).state = "Bitcoin Layer Swap";
            break;
          case 1:
            ref.read(selectedButtonProvider.notifier).state = "Swap";
            break;
          default:
            ref.read(selectedButtonProvider.notifier).state = "Stablecoin Swap";
        }
      },
      buttons: ["Bitcoin Layer Swap", 'Swap'],
      options: GroupButtonOptions(
        unselectedTextStyle: const TextStyle(
            fontSize: 16, color: Colors.black),
        selectedTextStyle: const TextStyle(
            fontSize: 16, color: Colors.white),
        selectedColor: Colors.deepOrange,
        mainGroupAlignment: MainGroupAlignment.center,
        crossGroupAlignment: CrossGroupAlignment.center,
        groupRunAlignment: GroupRunAlignment.center,
        unselectedColor: Colors.white,
        groupingType: GroupingType.row,
        alignment: Alignment.center,
        elevation: 0,
        textPadding: EdgeInsets.zero,
        selectedShadow: <BoxShadow>[
          const BoxShadow(color: Colors.transparent)
        ],
        unselectedShadow: <BoxShadow>[
          const BoxShadow(color: Colors.transparent)
        ],
        borderRadius: BorderRadius.circular(30.0),
      ),
    );
  }
}