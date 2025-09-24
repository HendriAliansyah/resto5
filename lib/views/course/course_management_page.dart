// lib/views/course/course_management_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/course_model.dart';
import 'package:resto2/providers/course_provider.dart';
import 'package:resto2/utils/snackbar.dart';
import 'package:resto2/views/course/widgets/course_dialog.dart';
import 'package:resto2/utils/constants.dart';
import 'package:resto2/views/widgets/shared/entity_management_page.dart';

class CourseManagementPage extends ConsumerWidget {
  const CourseManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesStreamProvider);
    final courseController = ref.read(courseControllerProvider.notifier);

    ref.listen<CourseState>(courseControllerProvider, (previous, next) {
      if (next.status == CourseActionStatus.success) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        showSnackBar(context, UIMessages.courseSaved);
      }
      if (next.status == CourseActionStatus.error) {
        showSnackBar(
          context,
          next.errorMessage ?? UIMessages.unknownError,
          isError: true,
        );
      }
    });

    void showCourseDialog({Course? course}) {
      showDialog(
        context: context,
        builder: (dialogContext) => CourseDialog(course: course),
      );
    }

    return EntityManagementPage<Course>(
      title: UIStrings.courseMaster,
      noItemsFoundText: UIStrings.noCoursesFound,
      items: coursesAsync.asData?.value ?? [],
      onAdd: () => showCourseDialog(),
      filterTile: const SizedBox.shrink(), // No filter for this page
      itemBuilder: (context, course) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(course.name),
            subtitle: Text(course.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showCourseDialog(course: course),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () async {
                    await courseController.deleteCourse(course.id);
                    if (!context.mounted) return;
                    showSnackBar(context, UIMessages.courseDeleted);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
