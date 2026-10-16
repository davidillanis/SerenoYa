import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/admin/categories/admin_categories_screen.dart';
import 'package:sereno_ya/ui/admin/categories/view_models/admin_categories_view_model.dart';
import 'package:sereno_ya/ui/admin/incidents/admin_incidents_screen.dart';
import 'package:sereno_ya/ui/admin/incidents/view_models/admin_incidents_view_model.dart';
import 'package:sereno_ya/ui/admin/users/admin_users_screen.dart';
import 'package:sereno_ya/ui/admin/users/view_models/admin_users_view_model.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/widgets/app_drawer.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late int _currentIndex;
  late final List<bool> _visitedTabs;

  static const _tabs = [
    AdminIncidentsScreen(),
    AdminCategoriesScreen(),
    AdminUsersScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _tabs.length - 1);
    _visitedTabs = List.generate(
      _tabs.length,
      (index) => index == _currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compactScreen = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: const Text(
          'Administración',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: switch (_currentIndex) {
          0 => [const _IncidentRefreshAction()],
          1 => [
            _CreateCategoryAction(onPressed: _openCreateCategory),
            const _CategoryRefreshAction(),
          ],
          _ => [
            if (!compactScreen) _RegisterUserAction(onPressed: _openCreateUser),
            const _UserRefreshAction(),
          ],
        },
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _tabs.length,
          (index) => _visitedTabs[index] ? _tabs[index] : const SizedBox(),
        ),
      ),
      floatingActionButton: compactScreen ? _compactAction() : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: context.appColors.tabIconSelected,
        unselectedItemColor: context.appColors.tabIconDefault,
        onTap: _selectTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Incidencias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Categorías',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Usuarios',
          ),
        ],
      ),
    );
  }

  Widget? _compactAction() => switch (_currentIndex) {
    1 => Consumer<AdminCategoriesViewModel>(
      builder: (context, viewModel, child) => FloatingActionButton.extended(
        onPressed: viewModel.isLoading ? null : _openCreateCategory,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    ),
    2 => Consumer<AdminUsersViewModel>(
      builder: (context, viewModel, child) => FloatingActionButton.extended(
        onPressed: viewModel.isLoadingInitial ? null : _openCreateUser,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Registrar'),
      ),
    ),
    _ => null,
  };

  void _selectTab(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _visitedTabs[index] = true;
    });
  }

  Future<void> _openCreateUser() async {
    final created = await context.push<bool>(RouteNames.adminUserCreate);
    if (!mounted || created != true) return;
    await context.read<AdminUsersViewModel>().loadInitial(forceRefresh: true);
  }

  Future<void> _openCreateCategory() async {
    final created = await context.push<bool>(RouteNames.adminCategoryCreate);
    if (!mounted || created != true) return;
    await context.read<AdminCategoriesViewModel>().loadInitial(
      forceRefresh: true,
    );
  }
}

class _CreateCategoryAction extends StatelessWidget {
  const _CreateCategoryAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminCategoriesViewModel>(
      builder: (context, viewModel, child) => IconButton(
        tooltip: 'Crear categoría',
        onPressed: viewModel.isLoading ? null : onPressed,
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryRefreshAction extends StatelessWidget {
  const _CategoryRefreshAction();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminCategoriesViewModel>(
      builder: (context, viewModel, child) => IconButton(
        tooltip: 'Actualizar categorías',
        onPressed: viewModel.isLoading
            ? null
            : () => viewModel.loadInitial(forceRefresh: true),
        icon: viewModel.isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
      ),
    );
  }
}

class _IncidentRefreshAction extends StatelessWidget {
  const _IncidentRefreshAction();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminIncidentsViewModel>(
      builder: (context, viewModel, child) => IconButton(
        tooltip: 'Actualizar incidencias',
        onPressed: viewModel.isLoadingInitial
            ? null
            : () => viewModel.loadInitial(forceRefresh: true),
        icon: viewModel.isLoadingInitial
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
      ),
    );
  }
}

class _RegisterUserAction extends StatelessWidget {
  const _RegisterUserAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminUsersViewModel>(
      builder: (context, viewModel, child) => IconButton(
        tooltip: 'Registrar usuario',
        onPressed: viewModel.isLoadingInitial ? null : onPressed,
        icon: const Icon(Icons.person_add_alt_1_outlined),
      ),
    );
  }
}

class _UserRefreshAction extends StatelessWidget {
  const _UserRefreshAction();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminUsersViewModel>(
      builder: (context, viewModel, child) => IconButton(
        tooltip: 'Actualizar usuarios',
        onPressed: viewModel.isLoadingInitial
            ? null
            : () => viewModel.loadInitial(forceRefresh: true),
        icon: viewModel.isLoadingInitial
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
      ),
    );
  }
}
