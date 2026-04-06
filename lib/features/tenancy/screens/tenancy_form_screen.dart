import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/tenancy_providers.dart';
import '../data/tenancy_model.dart';

class TenancyFormScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const TenancyFormScreen({super.key, required this.propertyId});

  @override
  ConsumerState<TenancyFormScreen> createState() => _TenancyFormScreenState();
}

class _TenancyFormScreenState extends ConsumerState<TenancyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _landlordNameController = TextEditingController();
  final _landlordPhoneController = TextEditingController();
  final _brokerNameController = TextEditingController();
  final _brokerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _saving = false;
  TenancyRecord? _existing;

  @override
  void initState() {
    super.initState();
    _startDateController.text = _dateFormat.format(_startDate);
    // Pre-fill if editing existing tenancy
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _existing =
          ref.read(tenancyByPropertyIdProvider(widget.propertyId));
      if (_existing != null) {
        _rentController.text = _existing!.monthlyRent.toStringAsFixed(0);
        _depositController.text =
            _existing!.securityDeposit.toStringAsFixed(0);
        _landlordNameController.text = _existing!.landlordName;
        _landlordPhoneController.text = _existing!.landlordPhone;
        _brokerNameController.text = _existing!.brokerName ?? '';
        _brokerPhoneController.text = _existing!.brokerPhone ?? '';
        _notesController.text = _existing!.notes ?? '';
        _startDate = _existing!.tenancyStartDate;
        _endDate = _existing!.tenancyEndDate;
        _startDateController.text = _dateFormat.format(_startDate);
        _endDateController.text =
            _endDate != null ? _dateFormat.format(_endDate!) : '';
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _rentController.dispose();
    _depositController.dispose();
    _landlordNameController.dispose();
    _landlordPhoneController.dispose();
    _brokerNameController.dispose();
    _brokerPhoneController.dispose();
    _notesController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: AppColors.textOnPrimary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startDateController.text = _dateFormat.format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = _dateFormat.format(picked);
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await ref.read(tenancyListProvider.notifier).save(
            existingId: _existing?.id,
            propertyId: widget.propertyId,
            monthlyRent: double.parse(_rentController.text.trim()),
            securityDeposit: double.parse(_depositController.text.trim()),
            tenancyStartDate: _startDate,
            tenancyEndDate: _endDate,
            landlordName: _landlordNameController.text.trim(),
            landlordPhone: _landlordPhoneController.text.trim(),
            brokerName: _brokerNameController.text.trim().isEmpty
                ? null
                : _brokerNameController.text.trim(),
            brokerPhone: _brokerPhoneController.text.trim().isEmpty
                ? null
                : _brokerPhoneController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Tenancy details saved'),
              ],
            ),
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final isEditing = _existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Tenancy' : 'Add Tenancy'),
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
            // Financial details
            const SectionHeader(title: 'Financial Details'),
            AppSpacing.vLg,

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Monthly Rent',
                    hint: '15000',
                    controller: _rentController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    prefix: const Icon(Icons.currency_rupee, size: 18),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                AppSpacing.hLg,
                Expanded(
                  child: AppTextField(
                    label: 'Security Deposit',
                    hint: '50000',
                    controller: _depositController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    prefix: const Icon(Icons.currency_rupee, size: 18),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            AppSpacing.vXxl,

            // Dates
            const SectionHeader(title: 'Tenancy Period'),
            AppSpacing.vLg,

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Start Date',
                    hint: 'Select date',
                    controller: _startDateController,
                    readOnly: true,
                    onTap: () => _pickDate(isStart: true),
                    suffix:
                        const Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                ),
                AppSpacing.hLg,
                Expanded(
                  child: AppTextField(
                    label: 'End Date',
                    hint: 'Select date',
                    controller: _endDateController,
                    readOnly: true,
                    onTap: () => _pickDate(isStart: false),
                    suffix:
                        const Icon(Icons.calendar_today_outlined, size: 18),
                    optional: true,
                  ),
                ),
              ],
            ),
            AppSpacing.vXxl,

            // Landlord details
            const SectionHeader(title: 'Landlord Details'),
            AppSpacing.vLg,

            AppTextField(
              label: 'Landlord Name',
              hint: 'Full name',
              controller: _landlordNameController,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            AppSpacing.vLg,

            AppTextField(
              label: 'Landlord Phone',
              hint: '9876543210',
              controller: _landlordPhoneController,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            AppSpacing.vXxl,

            // Broker details
            const SectionHeader(title: 'Broker Details'),
            AppSpacing.vLg,

            AppTextField(
              label: 'Broker Name',
              hint: 'Full name',
              controller: _brokerNameController,
              textCapitalization: TextCapitalization.words,
              optional: true,
            ),
            AppSpacing.vLg,

            AppTextField(
              label: 'Broker Phone',
              hint: '9876543210',
              controller: _brokerPhoneController,
              keyboardType: TextInputType.phone,
              optional: true,
            ),
            AppSpacing.vXxl,

            // Notes
            AppTextField(
              label: 'Notes',
              hint: 'Any additional details about the tenancy...',
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              optional: true,
            ),
            AppSpacing.vXxxl,

            AppButton(
              label: isEditing ? 'Update Tenancy' : 'Save Tenancy',
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
