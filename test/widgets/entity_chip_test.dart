import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuranotteai/model/summary_model.dart';
import 'package:neuranotteai/screens/widgets/entity_chip.dart';

void main() {
  group('EntityChip Widget', () {
    testWidgets('renders datetime entity chip correctly', (tester) async {
      final entity = DateTimeEntity(
        originalText: 'tomorrow at 3 PM',
        parsedDateTime: DateTime(2026, 2, 15, 15, 0),
        type: DateTimeType.relative,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntityChip.dateTime(
              entity: entity,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify the chip is rendered
      expect(find.byType(EntityChip), findsOneWidget);
      
      // Verify it shows a calendar icon for datetime
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('renders location entity chip correctly', (tester) async {
      const entity = LocationEntity(
        originalText: 'Walmart',
        type: LocationType.placeName,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntityChip.location(
              entity: entity,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify the chip is rendered
      expect(find.byType(EntityChip), findsOneWidget);
      
      // Verify it shows a location icon
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      
      // Verify the text is displayed
      expect(find.text('Walmart'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      
      final entity = DateTimeEntity(
        originalText: 'next Monday',
        parsedDateTime: DateTime(2026, 2, 16),
        type: DateTimeType.relative,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntityChip.dateTime(
              entity: entity,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Tap the chip
      await tester.tap(find.byType(EntityChip));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows selected state correctly', (tester) async {
      final entity = DateTimeEntity(
        originalText: 'March 15',
        parsedDateTime: DateTime(2026, 3, 15),
        type: DateTimeType.dateOnly,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntityChip.dateTime(
              entity: entity,
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify the chip is rendered
      expect(find.byType(EntityChip), findsOneWidget);
      
      // Verify checkmark icon is shown when selected
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('hides add icon when showAddIcon is false', (tester) async {
      final entity = DateTimeEntity(
        originalText: 'March 15',
        parsedDateTime: DateTime(2026, 3, 15),
        type: DateTimeType.dateOnly,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntityChip.dateTime(
              entity: entity,
              showAddIcon: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify the chip is rendered
      expect(find.byType(EntityChip), findsOneWidget);
      
      // Verify add icon is not shown
      expect(find.byIcon(Icons.add_circle_outline), findsNothing);
    });
  });

  group('EntitySection Widget', () {
    testWidgets('renders section with title and entity chips', (tester) async {
      final entities = [
        DateTimeEntity(
          originalText: 'tomorrow',
          parsedDateTime: DateTime.now().add(const Duration(days: 1)),
          type: DateTimeType.relative,
        ),
        DateTimeEntity(
          originalText: 'next week',
          parsedDateTime: DateTime.now().add(const Duration(days: 7)),
          type: DateTimeType.relative,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntitySection(
              title: 'Dates & Times',
              icon: Icons.calendar_today,
              color: Colors.blue,
              children: entities.map((e) => EntityChip.dateTime(
                entity: e,
                onTap: () {},
              )).toList(),
            ),
          ),
        ),
      );

      // Verify section title is displayed
      expect(find.text('Dates & Times'), findsOneWidget);
      
      // Verify section icon is displayed
      expect(find.byIcon(Icons.calendar_today), findsWidgets);
      
      // Verify both entity chips are rendered
      expect(find.byType(EntityChip), findsNWidgets(2));
    });

    testWidgets('renders location entities section', (tester) async {
      const entities = [
        LocationEntity(
          originalText: 'Walmart',
          type: LocationType.placeName,
        ),
        LocationEntity(
          originalText: 'Home',
          type: LocationType.placeName,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EntitySection(
              title: 'Locations',
              icon: Icons.place,
              color: Colors.orange,
              children: entities.map((e) => EntityChip.location(
                entity: e,
                onTap: () {},
              )).toList(),
            ),
          ),
        ),
      );

      // Verify section title is displayed
      expect(find.text('Locations'), findsOneWidget);
      
      // Verify entity chips are rendered
      expect(find.text('Walmart'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('handles empty children list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EntitySection(
              title: 'Dates & Times',
              icon: Icons.calendar_today,
              color: Colors.blue,
              children: [],
            ),
          ),
        ),
      );

      // Verify section title is still displayed
      expect(find.text('Dates & Times'), findsOneWidget);
      
      // Verify no entity chips are rendered
      expect(find.byType(EntityChip), findsNothing);
    });
  });

  group('HighlightedText Widget', () {
    testWidgets('renders text without highlights', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HighlightedText(
              text: 'This is plain text without any entities.',
              dateTimeEntities: [],
              locationEntities: [],
            ),
          ),
        ),
      );

      // Verify the widget renders
      expect(find.byType(HighlightedText), findsOneWidget);
      // Verify RichText is rendered (HighlightedText uses RichText internally)
      expect(find.byType(RichText), findsOneWidget);
      
      // Verify the RichText contains the expected text
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), contains('This is plain text'));
    });

    testWidgets('renders text with datetime highlights', (tester) async {
      final entities = [
        DateTimeEntity(
          originalText: 'tomorrow',
          parsedDateTime: DateTime.now().add(const Duration(days: 1)),
          type: DateTimeType.relative,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightedText(
              text: 'Meeting tomorrow at the office.',
              dateTimeEntities: entities,
              locationEntities: const [],
            ),
          ),
        ),
      );

      // Verify the widget renders
      expect(find.byType(HighlightedText), findsOneWidget);
    });

    testWidgets('renders text with location highlights', (tester) async {
      const entities = [
        LocationEntity(
          originalText: 'office',
          type: LocationType.placeName,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HighlightedText(
              text: 'Meeting tomorrow at the office.',
              dateTimeEntities: [],
              locationEntities: entities,
            ),
          ),
        ),
      );

      // Verify the widget renders
      expect(find.byType(HighlightedText), findsOneWidget);
    });

    testWidgets('renders with both datetime and location entities', (tester) async {
      final dateEntities = [
        DateTimeEntity(
          originalText: 'tomorrow',
          parsedDateTime: DateTime.now().add(const Duration(days: 1)),
          type: DateTimeType.relative,
        ),
      ];
      
      const locationEntities = [
        LocationEntity(
          originalText: 'office',
          type: LocationType.placeName,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightedText(
              text: 'Meeting tomorrow at the office.',
              dateTimeEntities: dateEntities,
              locationEntities: locationEntities,
            ),
          ),
        ),
      );

      // Verify the widget renders
      expect(find.byType(HighlightedText), findsOneWidget);
    });
  });
}
