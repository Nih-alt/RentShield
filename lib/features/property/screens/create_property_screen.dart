import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/property_model.dart';
import '../providers/property_providers.dart';

class CreatePropertyScreen extends ConsumerStatefulWidget {
  final String? editPropertyId;

  const CreatePropertyScreen({super.key, this.editPropertyId});

  @override
  ConsumerState<CreatePropertyScreen> createState() =>
      _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends ConsumerState<CreatePropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _notesController = TextEditingController();
  PropertyType _selectedType = PropertyType.flat;
  bool _saving = false;

  bool get _isEditing => widget.editPropertyId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final property =
            ref.read(propertyByIdProvider(widget.editPropertyId!));
        if (property != null) {
          _nameController.text = property.name;
          _address1Controller.text = property.addressLine1;
          _address2Controller.text = property.addressLine2 ?? '';
          _cityController.text = property.city;
          _stateController.text = property.state;
          _pincodeController.text = property.pincode;
          _notesController.text = property.notes ?? '';
          setState(() => _selectedType = property.propertyType);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        final existing =
            ref.read(propertyByIdProvider(widget.editPropertyId!));
        if (existing != null) {
          final updated = existing.copyWith(
            name: _nameController.text.trim(),
            addressLine1: _address1Controller.text.trim(),
            addressLine2: _address2Controller.text.trim().isEmpty
                ? null
                : _address2Controller.text.trim(),
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            pincode: _pincodeController.text.trim(),
            propertyType: _selectedType,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
          await ref.read(propertyListProvider.notifier).update(updated);
        }
      } else {
        await ref.read(propertyListProvider.notifier).create(
              name: _nameController.text.trim(),
              addressLine1: _address1Controller.text.trim(),
              addressLine2: _address2Controller.text.trim().isEmpty
                  ? null
                  : _address2Controller.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              pincode: _pincodeController.text.trim(),
              propertyType: _selectedType,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isEditing
                  ? 'Property updated successfully'
                  : 'Property added successfully')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Property' : 'Add Property'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPaddingAll,
          children: [
            // Property name
            AppTextField(
              label: 'Property Name',
              hint: 'e.g. My Apartment, 2BHK Koramangala',
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            AppSpacing.vLg,

            // Property type
            Text('Property Type', style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            _PropertyTypeSelector(
              selected: _selectedType,
              onChanged: (type) => setState(() => _selectedType = type),
            ),
            AppSpacing.vLg,

            // Address
            AppTextField(
              label: 'Address Line 1',
              hint: 'Street address, flat no.',
              controller: _address1Controller,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            AppSpacing.vLg,

            AppTextField(
              label: 'Address Line 2',
              hint: 'Landmark, area',
              controller: _address2Controller,
              textCapitalization: TextCapitalization.words,
              optional: true,
            ),
            AppSpacing.vLg,

            // City & State
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'City',
                    hint: 'City',
                    controller: _cityController,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                AppSpacing.hLg,
                Expanded(
                  child: AppTextField(
                    label: 'State',
                    hint: 'State',
                    controller: _stateController,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            AppSpacing.vLg,

            AppTextField(
              label: 'Pincode',
              hint: '560001',
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            AppSpacing.vLg,

            AppTextField(
              label: 'Notes',
              hint: 'Any additional details...',
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              optional: true,
            ),
            AppSpacing.vXxxl,

            AppButton(
              label: _isEditing ? 'Update Property' : 'Save Property',
              onPressed: _save,
              isLoading: _saving,
              icon: Icons.check_rounded,
            ),
            AppSpacing.vXxl,
          ],
        ),
      ),
    );
  }
}

class _PropertyTypeSelector extends StatelessWidget {
  final PropertyType selected;
  final ValueChanged<PropertyType> onChanged;

  const _PropertyTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: PropertyType.values.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surfaceVariant,
              borderRadius: AppRadius.borderRadiusMd,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(type.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  type.label,
                  style: AppTypography.labelLarge.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
