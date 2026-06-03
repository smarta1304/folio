import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {}

class AddFolder extends DashboardEvent {
  final String name;
  final int? expiryHours;
  const AddFolder(this.name, {this.expiryHours});

  @override
  List<Object?> get props => [name, expiryHours];
}

class DeleteDocument extends DashboardEvent {
  final int id;
  const DeleteDocument(this.id);

  @override
  List<Object> get props => [id];
}

class DeleteFolder extends DashboardEvent {
  final int id;
  const DeleteFolder(this.id);

  @override
  List<Object> get props => [id];
}

class SearchDashboard extends DashboardEvent {
  final String query;
  const SearchDashboard(this.query);

  @override
  List<Object> get props => [query];
}