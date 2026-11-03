import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

String historicalRangeLabel(PopularRange range) => switch (range) {
  PopularRange.day => t.discovery.calendarDay,
  PopularRange.week => t.discovery.calendarWeek,
  PopularRange.month => t.discovery.calendarMonth,
  _ => rangeLabel(range, PopularTimeBasis.calendarUploadPeriod),
};

String rangeLabel(PopularRange range, PopularTimeBasis basis) {
  if (basis == PopularTimeBasis.calendarUploadPeriod) {
    return switch (range) {
      PopularRange.day => t.discovery.today,
      PopularRange.week => t.discovery.thisWeek,
      _ => t.discovery.thisMonth,
    };
  }
  return switch (range) {
    PopularRange.day => t.discovery.lastDay,
    PopularRange.threeDays => t.discovery.lastThreeDays,
    PopularRange.week => t.discovery.lastWeek,
    PopularRange.month => t.discovery.lastMonth,
    PopularRange.threeMonths => t.discovery.lastThreeMonths,
    PopularRange.sixMonths => t.discovery.lastSixMonths,
    PopularRange.year => t.discovery.lastYear,
  };
}

String feedLabel(FeedKind kind) => switch (kind) {
  FeedKind.historicalPopular => t.discovery.historicalPopular,
  FeedKind.random => t.discovery.random,
  FeedKind.lifetimeViews => t.discovery.lifetimeViews,
  FeedKind.lifetimeFavorites => t.discovery.lifetimeFavorites,
  FeedKind.latest => t.discovery.latest,
  _ => t.discovery.popular,
};
