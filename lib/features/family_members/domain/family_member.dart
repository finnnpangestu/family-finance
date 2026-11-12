import 'package:equatable/equatable.dart';

class FamilyMember extends Equatable {
  const FamilyMember({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
