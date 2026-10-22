import 'package:flutter/material.dart';

import '../../models/saved_item.dart';
import '../../state/saved_controller.dart';
import '../../utils/constants.dart';
import 'widgets/saved_detail_dialog.dart';
import 'widgets/saved_empty_state.dart';
import 'widgets/saved_grid_item.dart';
import 'widgets/saved_stats_header.dart';

/// Screen for Tab 2 (Saved): Saved image references, cumulative stats, and detail inspection.
class SavedTab extends StatelessWidget {
  final SavedController controller;

  const SavedTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppConstants.backgroundDark
        : AppConstants.backgroundLight;
    final textColor = isDark ? AppConstants.textLight : AppConstants.textDark;
    final mutedColor = isDark
        ? AppConstants.textMuted
        : AppConstants.textMutedLight;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            title: Text(
              'Saved',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                onPressed: controller.loadSaved,
                icon: Icon(Icons.refresh, color: mutedColor),
                tooltip: 'Refresh Saved',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: controller.loadSaved,
            color: AppConstants.primaryAccent,
            backgroundColor: isDark
                ? AppConstants.surfaceDark
                : AppConstants.surfaceLight,
            child: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryAccent,
                    ),
                  )
                : controller.itemCount == 0
                ? const SavedEmptyState()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: SavedStatsHeader(
                            totalSavedBytes: controller.totalSavedBytes,
                            itemCount: controller.itemCount,
                            onClearAll: controller.clearSaved,
                          ),
                        ),
                        SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.0,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = controller.items[index];
                            return SavedGridItem(
                              item: item,
                              onTap: () => _openDetailDialog(context, item),
                              onShare: () => controller.shareItem(item),
                            );
                          }, childCount: controller.items.length),
                        ),
                        // Clearance for floating bottom nav bar
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _openDetailDialog(BuildContext context, SavedItem item) {
    showDialog(
      context: context,
      builder: (ctx) => SavedDetailDialog(
        item: item,
        onShare: () => controller.shareItem(item),
        onDelete: () => controller.deleteItem(item),
      ),
    );
  }
}
