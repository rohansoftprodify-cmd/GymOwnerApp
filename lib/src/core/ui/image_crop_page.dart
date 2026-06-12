import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Picks an image from the gallery, then opens a crop screen.
/// Returns cropped bytes, or null if the user cancels.
Future<Uint8List?> pickAndCropImage(
  BuildContext context, {
  ImageSource source = ImageSource.gallery,
  double? aspectRatio = 1,
  String cropTitle = 'Crop image',
}) async {
  final file = await ImagePicker().pickImage(source: source);
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  if (!context.mounted) return null;

  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      builder: (_) => ImageCropPage(
        imageBytes: bytes,
        aspectRatio: aspectRatio,
        title: cropTitle,
      ),
    ),
  );
}

class ImageCropPage extends StatefulWidget {
  const ImageCropPage({
    super.key,
    required this.imageBytes,
    this.aspectRatio = 1,
    this.title = 'Crop image',
  });

  final Uint8List imageBytes;
  final double? aspectRatio;
  final String title;

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  final _controller = CropController();
  bool _cropping = false;

  void _crop() {
    if (_cropping) return;
    setState(() => _cropping = true);
    _controller.crop();
  }

  void _onCropped(CropResult result) {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(croppedImage);
      case CropFailure(:final cause):
        setState(() => _cropping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not crop image: $cause')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _cropping ? null : _crop,
            child: _cropping
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.imageBytes,
              controller: _controller,
              aspectRatio: widget.aspectRatio,
              interactive: true,
              baseColor: colorScheme.surface,
              maskColor: Colors.black.withValues(alpha: 0.55),
              onCropped: _onCropped,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Drag to reposition. Pinch to zoom. Tap Done when ready.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FilledButton(
            onPressed: _cropping ? null : _crop,
            child: const Text('Use cropped image'),
          ),
        ),
      ),
    );
  }
}
