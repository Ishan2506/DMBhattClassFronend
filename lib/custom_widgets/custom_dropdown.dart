import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String labelText;
  final String hintText;
  final List<T> items;
  final T? value;
  final String Function(T) itemLabelBuilder;
  final void Function(T?) onChanged;
  final IconData? prefixIcon;

  const CustomDropdown({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.items,
    this.value,
    required this.itemLabelBuilder,
    required this.onChanged,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
      icon: Padding(padding: P.all8, child: const Icon(Icons.arrow_drop_down)),
      borderRadius: BorderRadius.circular(S.s12),
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabelBuilder(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
