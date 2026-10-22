import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

/// Full-page audit of the application's offline-only, zero-network architecture.
class OfflineArchitecturePage extends StatelessWidget {
  const OfflineArchitecturePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppConstants.backgroundDark
        : AppConstants.backgroundLight;
    final surfaceColor = isDark
        ? AppConstants.surfaceDark
        : AppConstants.surfaceLight;
    final cardColor = isDark ? AppConstants.cardDark : AppConstants.cardLight;
    final borderColor = isDark
        ? AppConstants.borderDark
        : AppConstants.borderLight;
    final textColor = isDark ? AppConstants.textLight : AppConstants.textDark;
    final mutedColor = isDark
        ? AppConstants.textMuted
        : AppConstants.textMutedLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Offline-Only Architecture',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Status Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.primaryAccent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryAccent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.primaryAccent.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: AppConstants.primaryAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Zero Network Permissions',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Strictly Sandboxed • Air-Gapped Image Processing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppConstants.primaryAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Security & Privacy Guarantees
            Text(
              'Security Guarantees',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            _buildAuditItem(
              icon: Icons.wifi_off_rounded,
              title: 'No Internet Permission Declared',
              description: 'The Android Manifest does not declare android.permission.INTERNET. At the OS kernel level, the application cannot establish outgoing or incoming network sockets.',
              surfaceColor: surfaceColor,
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 12),

            _buildAuditItem(
              icon: Icons.memory_rounded,
              title: '100% On-Device Compute',
              description: 'All decoding, downscaling, quantization, and EXIF strip operations execute locally inside device RAM via native hardware decoders and Flutter compute isolates.',
              surfaceColor: surfaceColor,
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 12),

            _buildAuditItem(
              icon: Icons.no_accounts_rounded,
              title: 'Zero Tracking & Ad SDKs',
              description: 'ReSinc contains no analytics libraries (Firebase Analytics, Google Analytics), no crash telemetry transmitting stack traces over the network, and no advertisement SDKs.',
              surfaceColor: surfaceColor,
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 12),

            _buildAuditItem(
              icon: Icons.lock_outline_rounded,
              title: 'Independent Storage Isolation',
              description: 'Images saved via ReSinc are stored in isolated local application sandboxes or committed directly to the user\'s local MediaStore using Android native Gal APIs.',
              surfaceColor: surfaceColor,
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditItem({
    required IconData icon,
    required String title,
    required String description,
    required Color surfaceColor,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppConstants.primaryAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
