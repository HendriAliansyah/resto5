// lib/views/menu/widgets/menu_bottom_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:resto2/models/inventory_item_model.dart';
import 'package:resto2/models/menu_model.dart';
import 'package:resto2/providers/course_provider.dart';
import 'package:resto2/providers/inventory_provider.dart';
import 'package:resto2/providers/menu_provider.dart';
import 'package:resto2/providers/order_type_provider.dart';
import 'package:resto2/utils/snackbar.dart';
import 'package:resto2/views/widgets/multi_select_form_field.dart';
import 'package:resto2/utils/constants.dart';

class MenuBottomSheet extends HookConsumerWidget {
  final MenuModel? menu;
  const MenuBottomSheet({super.key, this.menu});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = menu != null;
    final nameController = useTextEditingController(text: menu?.name);
    final descController = useTextEditingController(text: menu?.description);
    final priceController = useTextEditingController(
      text: menu?.price.toString(),
    );
    final preparationTimeController = useTextEditingController(
      text: menu?.preparationTime.toString(),
    );
    final itemTaxController = useTextEditingController(
      text: menu?.itemTaxPercentage.toString(),
    );
    final isTaxFixed = useState(menu?.isTaxFixed ?? false);
    final selectedCourseId = useState<String?>(menu?.courseId);
    final selectedOrderTypeId = useState<String?>(menu?.orderTypeId);
    final selectedInventoryItems = useState<List<String>>(
      menu?.inventoryItems ?? [],
    );
    final localImageFile = useState<File?>(null);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final courses = ref.watch(coursesStreamProvider).asData?.value ?? [];
    final orderTypes = ref.watch(orderTypesStreamProvider).asData?.value ?? [];
    final inventories = ref.watch(inventoryStreamProvider).asData?.value ?? [];
    final menuState = ref.watch(menuControllerProvider);
    final isLoading = menuState.status == MenuActionStatus.loading;

    ref.listen<MenuState>(menuControllerProvider, (prev, next) {
      if (next.status == MenuActionStatus.success) {
        if (context.mounted) Navigator.of(context).pop();
        showSnackBar(context, UIMessages.menuSaved);
      }
      if (next.status == MenuActionStatus.error) {
        showSnackBar(
          context,
          next.errorMessage ?? UIMessages.errorOccurred,
          isError: true,
        );
      }
    });

    void pickImage() async {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        localImageFile.value = File(image.path);
      }
    }

    void submit() {
      if (formKey.currentState?.validate() ?? false) {
        formKey.currentState!.save();
        if (selectedCourseId.value == null ||
            selectedOrderTypeId.value == null) {
          showSnackBar(
            context,
            UIMessages.selectCourseAndOrderType,
            isError: true,
          );
          return;
        }
        final controller = ref.read(menuControllerProvider.notifier);
        final price = double.tryParse(priceController.text) ?? 0.0;
        final preparationTime =
            int.tryParse(preparationTimeController.text) ?? 0;
        final itemTaxValue = double.tryParse(itemTaxController.text) ?? 0.0;

        if (isEditing) {
          controller.updateMenu(
            id: menu!.id,
            name: nameController.text,
            description: descController.text,
            price: price,
            courseId: selectedCourseId.value!,
            orderTypeId: selectedOrderTypeId.value!,
            inventoryItems: selectedInventoryItems.value,
            imageFile: localImageFile.value,
            existingImageUrl: menu?.imageUrl,
            preparationTime: preparationTime,
            itemTaxPercentage: itemTaxValue,
            isTaxFixed: isTaxFixed.value,
          );
        } else {
          controller.addMenu(
            name: nameController.text,
            description: descController.text,
            price: price,
            courseId: selectedCourseId.value!,
            orderTypeId: selectedOrderTypeId.value!,
            inventoryItems: selectedInventoryItems.value,
            imageFile: localImageFile.value,
            preparationTime: preparationTime,
            itemTaxPercentage: itemTaxValue,
            isTaxFixed: isTaxFixed.value,
          );
        }
      }
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                isEditing ? UIStrings.editMenu : UIStrings.addMenu,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: pickImage,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                              image: localImageFile.value != null
                                  ? DecorationImage(
                                      image: FileImage(localImageFile.value!),
                                      fit: BoxFit.cover,
                                    )
                                  : (menu?.imageUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              menu!.imageUrl!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                            ),
                            child:
                                localImageFile.value == null &&
                                    menu?.imageUrl == null
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 48,
                                        ),
                                        SizedBox(height: 8),
                                        Text(UIStrings.tapToAddImage),
                                      ],
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: UIStrings.name,
                        ),
                        validator: (v) =>
                            v!.isEmpty ? UIStrings.requiredField : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: UIStrings.description,
                        ),
                        maxLines: 3,
                        validator: (v) =>
                            v!.isEmpty ? UIStrings.requiredField : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: UIStrings.price,
                          prefixText: '\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (v) =>
                            v!.isEmpty ? UIStrings.requiredField : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: preparationTimeController,
                        decoration: const InputDecoration(
                          labelText: UIStrings.preparationTime,
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) =>
                            v!.isEmpty ? UIStrings.requiredField : null,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        UIStrings.itemSpecificTax,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: itemTaxController,
                        decoration: InputDecoration(
                          labelText: isTaxFixed.value
                              ? UIStrings.taxFixedValue
                              : UIStrings.taxPercentage,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      SwitchListTile(
                        title: const Text(UIStrings.isTaxFixed),
                        value: isTaxFixed.value,
                        onChanged: (value) => isTaxFixed.value = value,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(height: 32),
                      DropdownButtonFormField2<String>(
                        value: selectedCourseId.value,
                        items: courses
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => selectedCourseId.value = v,
                        decoration: const InputDecoration(
                          labelText: UIStrings.course,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null ? UIStrings.requiredField : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField2<String>(
                        value: selectedOrderTypeId.value,
                        items: orderTypes
                            .map(
                              (ot) => DropdownMenuItem(
                                value: ot.id,
                                child: Text(ot.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => selectedOrderTypeId.value = v,
                        decoration: const InputDecoration(
                          labelText: UIStrings.orderType,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null ? UIStrings.requiredField : null,
                      ),
                      const SizedBox(height: 16),
                      MultiSelectBottomSheetField<InventoryItem>(
                        initialValue: inventories
                            .where(
                              (i) =>
                                  selectedInventoryItems.value.contains(i.id),
                            )
                            .toList(),
                        items: inventories,
                        dialogTitle: UIStrings.inventoryItems,
                        searchHint: UIStrings.searchInventoryItems,
                        chipLabelBuilder: (inventory) => Text(inventory.name),
                        tileLabelBuilder: (inventory) => Text(inventory.name),
                        onSaved: (selected) {
                          selectedInventoryItems.value =
                              selected?.map((i) => i.id).toList() ?? [];
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: isLoading ? null : submit,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Text(UIStrings.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
