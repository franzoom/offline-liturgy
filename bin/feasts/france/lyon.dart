import '../../classes/feasts.dart';
//fêtes du calendrier général

Map<String, FeastDates> generateFeastList() {
  Map<String, FeastDates> feastList = {
    'gregory_x_pope': FeastDates(month: 1, day: 10, priority: 12),
  };
  return feastList;
}
