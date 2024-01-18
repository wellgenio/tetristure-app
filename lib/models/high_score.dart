import 'package:isar/isar.dart';

part 'high_score.g.dart';

@collection
class HighScore {
  Id id = Isar.autoIncrement;
  int? score = 0;
}
