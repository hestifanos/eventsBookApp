// lib/screens/create_event_page.dart
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

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

  // ------ media picking state ------
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  XFile? _pickedVideo;

  VideoPlayerController? _videoController;
  bool _videoReady = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateTimeController.dispose();
    _maxAttendeesController.dispose();
    _locationController.dispose();
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _videoReady = false;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (image == null) return;

      // If user selects an image, clear any previously selected video
      _disposeVideo();
      setState(() {
        _pickedVideo = null;
        _pickedImage = image;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 3),
      );
      if (video == null) return;

      // If user selects a video, clear any previously selected image
      setState(() {
        _pickedImage = null;
        _pickedVideo = video;
      });

      _disposeVideo();
      final controller = VideoPlayerController.file(File(video.path));
      await controller.initialize();
      controller.setLooping(true);
      setState(() {
        _videoController = controller;
        _videoReady = true;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick video: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick video: $e')),
      );
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final user = _auth.currentUser!;

      // --- Normalize date/time text before saving ---
      // fixes cases like "Nov 28 6.00pm" → "Nov 28 6:00pm"
      String rawDate = _dateTimeController.text.trim();
      String normalizedDate = rawDate.replaceAll('.', ':');

      await _eventService.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        hostId: user.uid,
        hostName: user.email ?? 'Organizer',
        maxAttendees: int.tryParse(_maxAttendeesController.text.trim()) ?? 0,
        dateTimeText: normalizedDate,
        locationName: _locationController.text.trim(),
        latitude: null,
        longitude: null,
        imageFile: _pickedImage,   // pass image if selected
        videoFile: _pickedVideo,   // pass video if selected
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
              colors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints:
                BoxConstraints(minHeight: constraints.maxHeight - 40),
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
                          _MediaPickerCard(
                            pickedImage: _pickedImage,
                            pickedVideo: _pickedVideo,
                            videoReady: _videoReady,
                            controller: _videoController,
                            onPickImageFromGallery: () =>
                                _pickImage(ImageSource.gallery),
                            onPickImageFromCamera: () =>
                                _pickImage(ImageSource.camera),
                            onPickVideoFromGallery: () =>
                                _pickVideo(ImageSource.gallery),
                            onPickVideoFromCamera: () =>
                                _pickVideo(ImageSource.camera),
                            onToggleVideo: () {
                              if (_videoController == null) return;
                              setState(() {
                                if (_videoController!.value.isPlaying) {
                                  _videoController!.pause();
                                } else {
                                  _videoController!.play();
                                }
                              });
                            },
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

                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(14)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            validator: (v) =>
                            v == null || v.isEmpty ? 'Title is required' : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(14)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _dateTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Date & Time (e.g., Nov 28, 7:00 PM)',
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(14)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 16),

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
                                  horizontal: 12, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location name / address',
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(14)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Location is required'
                                : null,
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _saveEvent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4C1D95),
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
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
                                      Colors.white),
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

class _MediaPickerCard extends StatelessWidget {
  final XFile? pickedImage;
  final XFile? pickedVideo;
  final bool videoReady;
  final VideoPlayerController? controller;

  final VoidCallback onPickImageFromGallery;
  final VoidCallback onPickImageFromCamera;
  final VoidCallback onPickVideoFromGallery;
  final VoidCallback onPickVideoFromCamera;
  final VoidCallback onToggleVideo;

  const _MediaPickerCard({
    required this.pickedImage,
    required this.pickedVideo,
    required this.videoReady,
    required this.controller,
    required this.onPickImageFromGallery,
    required this.onPickImageFromCamera,
    required this.onPickVideoFromGallery,
    required this.onPickVideoFromCamera,
    required this.onToggleVideo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasImage = pickedImage != null;
    final hasVideo = pickedVideo != null;

    String selectedLabel;
    if (hasImage) {
      selectedLabel = 'Image selected';
    } else if (hasVideo) {
      selectedLabel = 'Video selected';
    } else {
      selectedLabel = 'No media selected (optional)';
    }

    return Card(
      color: const Color(0xFFF7F7FB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Event media',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: cs.primary.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    'Optional',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Add an image or a short video to make your event more engaging.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),

            // ---------- PREVIEW ----------
            if (!hasImage && !hasVideo)
              Column(
                children: [
                  Icon(
                    Icons.insert_photo_outlined,
                    size: 40,
                    color: cs.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No media selected yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose an image or a short video below.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),

            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(pickedImage!.path),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            if (hasVideo && videoReady && controller != null)
              GestureDetector(
                onTap: onToggleVideo,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: controller!.value.aspectRatio == 0
                          ? 16 / 9
                          : controller!.value.aspectRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: VideoPlayer(controller!),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        controller!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),

            if (hasVideo && (!videoReady || controller == null))
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),

            if (hasImage || hasVideo) const SizedBox(height: 10),

            // Selected info
            Row(
              children: [
                Icon(
                  hasImage
                      ? Icons.image_outlined
                      : hasVideo
                      ? Icons.videocam_outlined
                      : Icons.info_outline,
                  size: 16,
                  color: Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(
                  selectedLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 24),

            // ---------- IMAGE CONTROLS ----------
            Text(
              'Image',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Best for posters, flyers or simple photos of the venue.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickImageFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPickImageFromCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ---------- VIDEO CONTROLS ----------
            Text(
              'Video',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use a short clip (max ~3 minutes) to showcase the event.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickVideoFromGallery,
                    icon: const Icon(Icons.video_library_outlined),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPickVideoFromCamera,
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
