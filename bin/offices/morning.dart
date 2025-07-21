import '../classes/calendar_class.dart'; //classe de calendar
import '../classes/morning_class.dart';
import '../assets/psalms_data/morning_psalms.dart';
import '../tools/days_name.dart';

bool detectFerialDays(String celebrationName) {
  // détecte si le nom du jour correspnd à un jour de férie (pour éliminer les jours de fête, à traiter à part)
  final prefixes = ['OT', 'ADVENT', 'LENT', 'CHRISMAS', 'PT'];
  return prefixes.any((prefix) => celebrationName.startsWith(prefix));
}

Map<String, Morning> morningFerialResolution(
    Calendar calendar, DateTime date, location)
//fonction de résolution des Laudes pour le cas des féries (on surajoutera le reste ensuite)
{
  Morning ferialMorning = Morning();
  final calendarDay = calendar.getDayContent(date);
  final celebrationName = calendarDay?.defaultCelebration;
  ferialMorning.celebrationGrade = calendarDay?.defaultPriority;
  ferialMorning.celebrationTitle = calendarDay?.defaultCelebration;

  if (detectFerialDays(celebrationName!)) {
    // si c'est bien un jour de férie, alors on met les psaumes correspondants
    List<String>? morningPsalmList = morningPsalms(calendarDay!.liturgicalTime,
        calendarDay.breviaryWeek!, dayName[date.weekday]);
    ferialMorning.psalm1Ref = morningPsalmList?[0];
    ferialMorning.psalm2Ref = morningPsalmList?[1];
    ferialMorning.psalm3Ref = morningPsalmList?[2];
  }
  return {celebrationName: ferialMorning};
}
