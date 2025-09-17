// lib/views/kitchen/widgets/reset_approval_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/role_permission_model.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/utils/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:resto2/utils/constants.dart';

class ResetApprovalDialog extends HookConsumerWidget {
  final Function(bool wasWasted) onApproved;

  const ResetApprovalDialog({super.key, required this.onApproved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final isPasswordVisible = useState(false);
    final wasWasted = useState(false);

    void handleApproval() async {
      if (formKey.currentState?.validate() ?? false) {
        isLoading.value = true;
        FirebaseApp? tempApp; // Keep a reference to the temp app

        try {
          // Use a unique name for the temporary app to avoid conflicts
          tempApp = await Firebase.initializeApp(
            name: 'tempManagerAuth-${DateTime.now().millisecondsSinceEpoch}',
            options: Firebase.app().options,
          );
          final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

          final credential = await tempAuth.signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

          if (credential.user == null) {
            throw Exception(UIMessages.authFailed);
          }

          final userDoc = await ref
              .read(firestoreProvider)
              .collection('users')
              .doc(credential.user!.uid)
              .get();

          if (!userDoc.exists) {
            throw Exception(UIMessages.userDataNotFound);
          }

          final userRole = UserRole.values.firstWhere(
            (e) => e.name == userDoc.data()?['role'],
            orElse: () => UserRole.cashier,
          );

          if (userRole == UserRole.manager || userRole == UserRole.owner) {
            if (context.mounted) {
              Navigator.of(context).pop(true);
              onApproved(wasWasted.value);
            }
          } else {
            throw Exception(UIMessages.insufficientPermissions);
          }
        } catch (e) {
          if (context.mounted) {
            showSnackBar(context, 'Error: ${e.toString()}', isError: true);
          }
        } finally {
          // THE FIX IS HERE: Properly delete the temporary app instance.
          if (tempApp != null) {
            await tempApp.delete();
          }

          if (context.mounted) {
            isLoading.value = false;
          }
        }
      }
    }

    return AlertDialog(
      title: const Text(UIStrings.managerApprovalRequired),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: UIStrings.managerOwnerEmail,
              ),
              validator: (v) => v!.isEmpty ? UIMessages.enterEmailPrompt : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: !isPasswordVisible.value,
              decoration: InputDecoration(
                labelText: UIStrings.passwordLabel,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () =>
                      isPasswordVisible.value = !isPasswordVisible.value,
                ),
              ),
              validator: (v) => v!.isEmpty ? UIMessages.enterPassword : null,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text(UIStrings.ingredientsWasted),
              value: wasWasted.value,
              onChanged: (newValue) {
                if (newValue != null) {
                  wasWasted.value = newValue;
                }
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading.value ? null : () => Navigator.of(context).pop(),
          child: const Text(UIStrings.cancel),
        ),
        ElevatedButton(
          onPressed: isLoading.value ? null : handleApproval,
          child: isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(UIStrings.approve),
        ),
      ],
    );
  }
}
