import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../utils/constants.dart';

/// Text input field for specifying custom target maximum size in KB.
class CustomKBInput extends StatelessWidget {
  final TextEditingController controller;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;
  final ValueChanged<int?> onChanged;

  const CustomKBInput({
    super.key,
    required this.controller,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(color: textColor, fontSize: 13),
      decoration: InputDecoration(
        labelText: 'Target Maximum Size (KB)',
        labelStyle: TextStyle(color: mutedColor, fontSize: 12),
        hintText: '50 KB or more',
        errorText:
            (int.tryParse(controller.text) ?? 0) < AppConstants.minimumTargetKB
            ? 'Minimum target is 50 KB'
            : null,
        hintStyle: TextStyle(color: mutedColor),
        filled: true,
        fillColor: cardColor,
        suffixText: 'KB',
        suffixStyle: const TextStyle(
          color: AppConstants.primaryAccent,
          fontWeight: FontWeight.bold,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppConstants.primaryAccent,
            width: 1.5,
          ),
        ),
      ),
      onChanged: (val) {
        final parsed = int.tryParse(val);
        onChanged(parsed);
      },
    );
  }
}
