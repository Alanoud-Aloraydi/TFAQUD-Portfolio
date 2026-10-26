import 'package:get_storage/get_storage.dart';
import 'package:injectable/injectable.dart';

/// Stores circle identifiers per account; authorization always comes from API.
@lazySingleton
class HomeLocalDataSource {
  HomeLocalDataSource(this._storage);

  final GetStorage _storage;

  String? selectedCircle(String accountId) =>
      _storage.read<String>('home.selected_circle.$accountId');

  Future<void> selectCircle(String accountId, String circleId) =>
      _storage.write('home.selected_circle.$accountId', circleId);
}
