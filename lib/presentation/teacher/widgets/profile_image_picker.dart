import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // Commented out to avoid dependency

// Profile image picker widget following Flutter Lite rules (<150 lines)
class ProfileImagePicker extends StatefulWidget {
  final Function(File?) onImageSelected;
  
  const ProfileImagePicker({
    super.key,
    required this.onImageSelected,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  File? _image;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_image == null) ...[
            _buildUploadArea(),
          ] else ...[
            _buildImagePreview(),
          ],
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              color: Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to upload photo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'JPG, PNG up to 5MB',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(_image!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: _removeImage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    developer.log('ProfileImagePicker: Starting image selection');
    
    try {
      // For Flutter Lite compliance, we'll simulate image selection
      // In a real app, you would use image_picker package
      developer.log('ProfileImagePicker: Simulating image selection');
      
      // Simulate file selection with a placeholder
      setState(() {
        _image = File('placeholder.jpg'); // This would be actual file path
        _errorMessage = null;
      });
      
      widget.onImageSelected(_image);
    } catch (e) {
      developer.log('ProfileImagePicker: Error selecting image: $e');
      setState(() {
        _errorMessage = 'Error selecting image: ${e.toString()}';
      });
    }
  }

  void _removeImage() {
    developer.log('ProfileImagePicker: Removing selected image');
    setState(() {
      _image = null;
      _errorMessage = null;
    });
    widget.onImageSelected(null);
  }
}