// lib/views/table_type/widgets/table_type_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/table_type_model.dart';
import 'package:resto2/providers/table_type_provider.dart';
import 'package:resto2/utils/snackbar.dart';
import 'package:resto2/utils/constants.dart';
import 'package:resto2/views/widgets/shared/app_text_form_field.dart';
import 'package:resto2/views/widgets/shared/entity_dialog.dart';

class TableTypeDialog extends HookConsumerWidget {
  final TableType? tableType;
  const TableTypeDialog({super.key, this.tableType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = tableType != null;
    final nameController = useTextEditingController(text: tableType?.name);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading =
        ref.watch(tableTypeControllerProvider).status ==
        TableTypeActionStatus.loading;

    ref.listen<TableTypeState>(tableTypeControllerProvider, (prev, next) {
      if (next.status == TableTypeActionStatus.success) {
        showSnackBar(context, UIMessages.tableTypeSaved);
        if (isEditing) {
          Navigator.of(context).pop();
        } else {
          nameController.clear();
        }
      }
      if (next.status == TableTypeActionStatus.error) {
        showSnackBar(
          context,
          next.errorMessage ?? UIMessages.errorOccurred,
          isError: true,
        );
      }
    });

    void submit() {
      if (formKey.currentState?.validate() ?? false) {
        if (isEditing) {
          ref
              .read(tableTypeControllerProvider.notifier)
              .updateTableType(id: tableType!.id, name: nameController.text);
        } else {
          ref
              .read(tableTypeControllerProvider.notifier)
              .addTableType(name: nameController.text);
        }
      }
    }

    return EntityDialog(
      title: isEditing ? UIStrings.editTableType : UIStrings.addTableType,
      isLoading: isLoading,
      onSave: submit,
      content: Form(
        key: formKey,
        child: AppTextFormField(
          controller: nameController,
          labelText: UIStrings.typeName,
          validator: (v) =>
              v!.trim().isEmpty ? UIMessages.enterTableName : null,
        ),
      ),
    );
  }
}
