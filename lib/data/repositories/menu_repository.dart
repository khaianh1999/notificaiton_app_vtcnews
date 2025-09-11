import '../models/tab_model.dart';
import '../services/menu_service.dart';

class MenuRepository {
  final _svc = MenuService();

  Future<List<TabModel>> getTabs() => _svc.fetchMenuTabs();

  Future<List<TabModel>> getPageMenu() => _svc.fetchMenuTabMenu();
}
