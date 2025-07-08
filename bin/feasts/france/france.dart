import '../../classes/feasts.dart';
//fêtes du calendrier général

Map<String, FeastDates> generateFeastList() {
  Map<String, FeastDates> feastList = {
    'genevieve_of_paris_virgin': FeastDates(month: 1, day: 3, priority: 12),
  };
  return feastList;
}
