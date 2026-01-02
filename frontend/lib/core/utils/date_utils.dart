import 'package:intl/intl.dart';

String? formatShortDate(DateTime? date) {
  if (date == null) return null;
  return DateFormat.yMMMd().format(date.toLocal());
}
