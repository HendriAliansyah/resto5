// lib/views/widgets/shared/app_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:resto2/utils/constants.dart';

class AppBottomSheet extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onSave;
  final bool isLoading;

  const AppBottomSheet({
    super.key,
    required this.title,
    required this.content,
    required this.onSave,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: content,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: isLoading ? null : onSave,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text(UIStrings.save),
            ),
          ),
        ],
      ),
    );
  }
}
