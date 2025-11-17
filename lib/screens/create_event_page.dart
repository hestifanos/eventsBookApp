// lib/screens/create_event_page.dart
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/event_service.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventService = EventService();
  final _auth = FirebaseAuth.instance;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateTimeController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _locationController = TextEditingController();

  bool _saving = false;

  // ------ image picking state ------
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateTimeController.dispose();
    _maxAttendeesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      debugPrint('Picking image from $source');
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        imageQuality: 85,
      );
      debugPrint('Picker returned: $image');

      if (image == null) return;

      if (!mounted) return;
      setState(() {
        _pickedImage = image;
      });
    } on PlatformException catch (e) {
      // This will catch channel / permission errors and show them on screen
      debugPrint('Image pick failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to pick image: ${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Unknown error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final user = _auth.currentUser!;
      await _eventService.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        hostId: user.uid,
        hostName: user.email ?? 'Organizer',
        maxAttendees:
        int.tryParse(_maxAttendeesController.text.trim()) ?? 0,
        dateTimeText: _dateTimeController.text.trim(),
        locationName: _locationController.text.trim(),
        latitude: null,
        longitude: null,
        imageFile: _pickedImage, // send image to service
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Create Event'),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4C1D95),
                Color(0xFF6D28D9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF7F7FB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Center(
                  child: Form(
                    key: _formKey,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // image picker card
                          _ImagePickerCard(
                            pickedImage: _pickedImage,
                            onPickFromGallery: () =>
                                _pickImage(ImageSource.gallery),
                            onPickFromCamera: () =>
                                _pickImage(ImageSource.camera),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Event Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(14)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Title is required'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(14)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),

                          // Date & Time
                          TextFormField(
                            controller: _dateTimeController,
                            decoration: const InputDecoration(
                              labelText:
                              'Date & Time (e.g., Nov 28, 3:00 PM)',
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(14)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Max attendees
                          TextFormField(
                            controller: _maxAttendeesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max attendees',
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(14)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Location
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location name / address',
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(14)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Location is required'
                                : null,
                          ),
                          const SizedBox(height: 24),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _saveEvent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4C1D95),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                                  : const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final XFile? pickedImage;
  final VoidCallback onPickFromGallery;
  final VoidCallback onPickFromCamera;

  const _ImagePickerCard({
    required this.pickedImage,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF7F7FB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            if (pickedImage == null)
              Column(
                children: [
                  Icon(
                    Icons.photo_outlined,
                    size: 40,
                    color: const Color(0xFF6D28D9),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add an event image',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose from gallery or use the camera.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(pickedImage!.path),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickFromGallery,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPickFromCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9),
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
