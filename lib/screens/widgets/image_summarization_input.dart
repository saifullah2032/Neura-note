import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/themes.dart';
import '../../core/fluid_components.dart';

class ImageSummarizationInput extends StatelessWidget {
  final File? selectedImage;
  final Function(File) onImageSelected;
  final VoidCallback onProcessImage;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickImage;
  final bool isProcessing;

  const ImageSummarizationInput({
    super.key,
    this.selectedImage,
    required this.onImageSelected,
    required this.onProcessImage,
    required this.onTakePhoto,
    required this.onPickImage,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return OceanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: colorScheme.primary.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(4),
                 ),
                child: Icon(
                  Icons.image,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Image Summary',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onPickImage,
            child: Container(
               height: 160,
               decoration: BoxDecoration(
                 color: colorScheme.primary.withValues(alpha: 0.05),
                 borderRadius: BorderRadius.circular(4),
                 border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: selectedImage != null
                   ? ClipRRect(
                       borderRadius: BorderRadius.circular(4),
                       child: Image.file(
                        selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to select image',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTakePhoto,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                     side: BorderSide(color: colorScheme.primary),
                     padding: const EdgeInsets.symmetric(vertical: 12),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(4),
                     ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LiquidButton(
                  onPressed: selectedImage != null && !isProcessing ? onProcessImage : null,
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isProcessing)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else ...[
                        Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        'Summarize',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ImageSummarizationInputWithPicker extends StatefulWidget {
  final Function(File) onImageSelected;
  final Function(File) onProcessImage;
  final bool isProcessing;

  const ImageSummarizationInputWithPicker({
    super.key,
    required this.onImageSelected,
    required this.onProcessImage,
    this.isProcessing = false,
  });

  @override
  State<ImageSummarizationInputWithPicker> createState() => _ImageSummarizationInputWithPickerState();
}

class _ImageSummarizationInputWithPickerState extends State<ImageSummarizationInputWithPicker> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      widget.onImageSelected(_selectedImage!);
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      widget.onImageSelected(_selectedImage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ImageSummarizationInput(
      selectedImage: _selectedImage,
      onImageSelected: (file) {
        setState(() => _selectedImage = file);
      },
      onProcessImage: () {
        if (_selectedImage != null) {
          widget.onProcessImage(_selectedImage!);
        }
      },
      onTakePhoto: _takePhoto,
      onPickImage: _pickImage,
      isProcessing: widget.isProcessing,
    );
  }
}
