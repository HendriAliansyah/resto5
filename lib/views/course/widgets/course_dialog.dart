// lib/views/course/widgets/course_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/course_model.dart';
import 'package:resto2/providers/course_provider.dart';
import 'package:resto2/utils/constants.dart';
import 'package:resto2/views/widgets/shared/app_text_form_field.dart';
import 'package:resto2/views/widgets/shared/entity_dialog.dart';

class CourseDialog extends HookConsumerWidget {
  final Course? course;
  const CourseDialog({super.key, this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = course != null;
    final nameController = useTextEditingController(text: course?.name);
    final descriptionController = useTextEditingController(
      text: course?.description,
    );
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final isLoading =
        ref.watch(courseControllerProvider).status ==
        CourseActionStatus.loading;

    void submit() {
      if (formKey.currentState?.validate() ?? false) {
        final courseController = ref.read(courseControllerProvider.notifier);
        if (isEditing) {
          courseController.updateCourse(
            courseId: course!.id,
            name: nameController.text,
            description: descriptionController.text,
          );
        } else {
          courseController.addCourse(
            name: nameController.text,
            description: descriptionController.text,
          );
        }
      }
    }

    return EntityDialog(
      title: isEditing ? UIStrings.editCourse : UIStrings.addCourse,
      isLoading: isLoading,
      onSave: submit,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextFormField(
              controller: nameController,
              labelText: UIStrings.courseName,
              hintText: UIStrings.courseNameHint,
              validator: (value) =>
                  value!.trim().isEmpty ? UIMessages.enterCourseName : null,
            ),
            const SizedBox(height: 16),
            AppTextFormField(
              controller: descriptionController,
              labelText: UIStrings.description,
              hintText: UIStrings.courseDescriptionHint,
              maxLines: 2,
              validator: (value) =>
                  value!.trim().isEmpty ? UIMessages.enterDescription : null,
            ),
          ],
        ),
      ),
    );
  }
}
