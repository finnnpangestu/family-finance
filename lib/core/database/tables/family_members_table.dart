// People a transaction can be assigned to (Ayah, Ibu, ...).
abstract final class FamilyMembersTable {
  static const String name = 'family_members';

  static const String id = 'id';
  static const String memberName = 'name';

  static const String createSql =
      '''
CREATE TABLE $name (
  $id INTEGER PRIMARY KEY AUTOINCREMENT,
  $memberName TEXT NOT NULL UNIQUE
)''';
}
