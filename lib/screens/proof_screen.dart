import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/focus_provider.dart';
import '../services/app_blocker_service.dart';
import '../services/camera_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dashed_slot.dart';
import '../widgets/proof_preview.dart';

class ProofScreen extends StatefulWidget {
  final Task task;
  const ProofScreen({super.key, required this.task});
  @override
  State<ProofScreen> createState() => _ProofScreenState();
}

class _ProofScreenState extends State<ProofScreen> {
  final camera = CameraService();
  File? localPhoto;
  bool uploading = false;

  Future<void> take() async {
    final f = await camera.takePhoto();
    if (f != null) setState(() => localPhoto = f);
  }

  Future<void> complete() async {
    if (widget.task.verificationType == 'Photo' && localPhoto == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Take a proof photo first.')));
      return;
    }

    String? proofUrl;
    if (localPhoto != null) {
      final uid = context.read<AuthProvider>().uid;
      if (uid == null) return;
      setState(() => uploading = true);
      try {
        proofUrl = await camera.uploadProof(
          uid: uid,
          taskId: widget.task.id,
          file: localPhoto!,
        );
      } catch (e) {
        // ignore: avoid_print
        print('Proof upload failed: $e');
        if (mounted) {
          setState(() => uploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    final focus = context.read<FocusProvider>();
    await context.read<TaskProvider>().completeTask(
      widget.task.id,
      proofImageUrl: proofUrl,
    );
    // Task is done: only now is focus mode released.
    await AppBlockerService().stopBlocking();
    await NotificationService().cancelFocusTimer();
    focus.stop();
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Complete Task'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.verified_rounded, size: 52, color: AppColors.signal),
        const SizedBox(height: 16),
        Text(
          'Great work!',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.task.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 28),
        if (widget.task.verificationType == 'Photo') ...[
          const Text(
            'Take a photo showing your completed task.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (localPhoto != null)
            ProofPreview(file: localPhoto!)
          else
            const DashedSlot(
              icon: Icons.photo_camera_outlined,
              label: 'No photo yet',
            ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: uploading ? null : take,
            icon: const Icon(Icons.camera_alt),
            label: Text(localPhoto == null ? 'Take Photo' : 'Retake Photo'),
          ),
        ] else
          const Text(
            'Confirm that you completed this task.',
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: uploading ? null : complete,
          icon: uploading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle),
          label: Padding(
            padding: const EdgeInsets.all(13),
            child: Text(uploading ? 'Uploading...' : 'Confirm Completion'),
          ),
        ),
      ],
    ),
    ),
  );
}