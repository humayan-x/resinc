import 'package:flutter/material.dart';

import '../state/workbench_controller.dart';
import '../utils/constants.dart';
import 'floating_bar_frame.dart';

class WorkbenchActionBar extends StatelessWidget {
  final WorkbenchController controller;
  final VoidCallback onSave;
  const WorkbenchActionBar({
    super.key,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final busy = controller.isBusy;
    final style = ElevatedButton.styleFrom(
      backgroundColor: AppConstants.primaryAccent,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppConstants.primaryAccent.withValues(
        alpha: .35,
      ),
      disabledForegroundColor: Colors.white70,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
    return FloatingBarFrame(
      child: controller.hasResult
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: busy || controller.isSavedToGallery
                        ? null
                        : onSave,
                    style: style,
                    icon: Icon(
                      controller.isSavedToGallery
                          ? Icons.check
                          : Icons.save_outlined,
                      size: 20,
                    ),
                    label: Text(controller.isSavedToGallery ? 'Saved' : 'Save'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: IconButton.filled(
                    tooltip: 'New preset',
                    onPressed: busy ? null : controller.clearResult,
                    style: IconButton.styleFrom(
                      backgroundColor: AppConstants.primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: IconButton.filled(
                    tooltip: 'Share',
                    onPressed: busy ? null : controller.shareResult,
                    style: IconButton.styleFrom(
                      backgroundColor: AppConstants.primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.share_outlined),
                  ),
                ),
              ],
            )
          : ElevatedButton.icon(
              onPressed: busy || !controller.options.isValid
                  ? null
                  : controller.compress,
              style: style,
              icon: controller.isCompressing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.compress, size: 20),
              label: Text(
                controller.isCompressing ? 'Optimising…' : 'Optimise',
              ),
            ),
    );
  }
}
