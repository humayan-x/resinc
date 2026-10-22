import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resinc/screens/saved/widgets/dialog/saved_detail_actions.dart';
import 'package:resinc/utils/constants.dart';

void main() {
  testWidgets('SavedDetailActions renders Open in Gallery with white text and equal-sized action buttons',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedDetailActions(
            onShare: () {},
            onDelete: () {},
            cardColor: AppConstants.cardDark,
            textColor: Colors.white,
          ),
        ),
      ),
    );

    // Verify Open in Gallery text style is white
    final openButtonTextFinder = find.text('Open in Gallery');
    expect(openButtonTextFinder, findsOneWidget);
    final textWidget = tester.widget<Text>(openButtonTextFinder);
    expect(textWidget.style?.color, Colors.white);

    // Verify Open in Gallery button foregroundColor is white
    final elevatedButtonFinder = find.byType(ElevatedButton);
    expect(elevatedButtonFinder, findsOneWidget);
    final elevatedButton = tester.widget<ElevatedButton>(elevatedButtonFinder);
    expect(elevatedButton.style?.foregroundColor?.resolve({}), Colors.white);

    // Verify Share and Delete icon buttons have identical size
    final iconButtons = tester.widgetList<IconButton>(find.byType(IconButton)).toList();
    expect(iconButtons.length, 2);

    final shareButtonSize = tester.getSize(find.byType(IconButton).at(0));
    final deleteButtonSize = tester.getSize(find.byType(IconButton).at(1));
    expect(shareButtonSize, equals(deleteButtonSize));
    expect(shareButtonSize.width, 48.0);
    expect(shareButtonSize.height, 48.0);

    // Verify icon sizes are equal (20.0)
    final shareIcon = tester.widget<Icon>(find.byIcon(Icons.share_rounded));
    final deleteIcon = tester.widget<Icon>(find.byIcon(Icons.delete_outline));
    expect(shareIcon.size, 20.0);
    expect(deleteIcon.size, 20.0);

    // Verify icon buttons have non-null callbacks
    expect(iconButtons[0].onPressed, isNotNull);
    expect(iconButtons[1].onPressed, isNotNull);
  });
}
