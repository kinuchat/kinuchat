import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shows an avatar picker bottom sheet
/// Returns the selected File or null if cancelled
Future<File?> showAvatarPicker(BuildContext context) async {
  final picker = ImagePicker();

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );

  if (source == null) return null;

  try {
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image == null) return null;

    return File(image.path);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }
}

/// A clickable avatar widget that shows the picker when tapped
class AvatarPickerWidget extends StatelessWidget {
  final String? currentAvatarUrl;
  final File? selectedFile;
  final double radius;
  final IconData placeholderIcon;
  final void Function(File?) onImageSelected;

  const AvatarPickerWidget({
    super.key,
    this.currentAvatarUrl,
    this.selectedFile,
    this.radius = 50,
    this.placeholderIcon = Icons.group,
    required this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.blue.shade200,
          backgroundImage: _getImage(),
          child: _shouldShowPlaceholder()
              ? Icon(
                  placeholderIcon,
                  size: radius,
                  color: Colors.blue.shade700,
                )
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: CircleAvatar(
            radius: radius * 0.36,
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: Icon(Icons.camera_alt, size: radius * 0.36),
              color: Colors.white,
              padding: EdgeInsets.zero,
              onPressed: () async {
                final file = await showAvatarPicker(context);
                onImageSelected(file);
              },
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? _getImage() {
    if (selectedFile != null) {
      return FileImage(selectedFile!);
    }
    if (currentAvatarUrl != null) {
      return NetworkImage(currentAvatarUrl!);
    }
    return null;
  }

  bool _shouldShowPlaceholder() {
    return selectedFile == null && currentAvatarUrl == null;
  }
}
