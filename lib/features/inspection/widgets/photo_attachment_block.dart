import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_radius.dart';

class PhotoAttachmentBlock extends StatelessWidget {
  final List<String> photos;
  final ValueChanged<List<String>> onChanged;
  final String label;

  const PhotoAttachmentBlock({
    super.key,
    required this.photos,
    required this.onChanged,
    this.label = 'Photos',
  });

  Future<void> _pickPhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.borderRadiusPill,
                ),
              ),
              const SizedBox(height: 16),
              Text('Add Photo', style: AppTypography.h3),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary, size: 20),
                ),
                title: Text('Camera', style: AppTypography.labelLarge),
                subtitle:
                    Text('Take a new photo', style: AppTypography.bodySmall),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: AppRadius.borderRadiusMd,
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.accent, size: 20),
                ),
                title: Text('Gallery', style: AppTypography.labelLarge),
                subtitle: Text('Choose from gallery',
                    style: AppTypography.bodySmall),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (file != null) {
      onChanged([...photos, file.path]);
    }
  }

  void _removePhoto(int index) {
    final updated = List<String>.from(photos)..removeAt(index);
    onChanged(updated);
  }

  void _viewPhoto(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(
          photos: photos,
          initialIndex: index,
          onRemove: (i) {
            _removePhoto(i);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTypography.labelLarge),
            if (photos.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderRadiusPill,
                ),
                child: Text(
                  '${photos.length}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add button
              GestureDetector(
                onTap: () => _pickPhoto(context),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.borderRadiusMd,
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 22, color: AppColors.textSecondary),
                      const SizedBox(height: 4),
                      Text('Add',
                          style: AppTypography.labelSmall
                              .copyWith(fontSize: 10)),
                    ],
                  ),
                ),
              ),
              // Photo thumbnails
              ...photos.asMap().entries.map((entry) {
                final index = entry.key;
                final path = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => _viewPhoto(context, index),
                    child: ClipRRect(
                      borderRadius: AppRadius.borderRadiusMd,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Icon(Icons.broken_image_outlined,
                                    size: 24, color: AppColors.textTertiary),
                              ),
                            ),
                            // Remove button
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removePhoto(index),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final List<String> photos;
  final int initialIndex;
  final ValueChanged<int> onRemove;

  const _PhotoViewer({
    required this.photos,
    required this.initialIndex,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Photo ${initialIndex + 1} of ${photos.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => onRemove(initialIndex),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            File(photos[initialIndex]),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: Colors.white38,
            ),
          ),
        ),
      ),
    );
  }
}
