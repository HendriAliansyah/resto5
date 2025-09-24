// lib/views/widgets/shared/entity_dialog.dart
import 'package:flutter/material.dart';
import 'package:resto2/utils/constants.dart';

class EntityDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onSave;
  final bool isLoading;

  const EntityDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onSave,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content,
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(UIStrings.cancel),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : onSave,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(UIStrings.save),
        ),
      ],
    );
  }
}
