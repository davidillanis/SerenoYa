import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/citizen/incident_category.dart';
import 'package:sereno_ya/data/repositories/citizen/incident_repository.dart';
import 'package:sereno_ya/data/services/api/file/image_api_service.dart';
import 'package:sereno_ya/models/auth/result.dart';
import 'package:sereno_ya/ui/citizen/report_incident/view_models/report_incident_view_model.dart';

void main() {
  final first = IncidentCategory(id: 'first', name: 'Robo', description: '');
  final second = IncidentCategory(
    id: 'second',
    name: 'Accidente',
    description: '',
  );

  test('selecciona la primera categoría cuando termina de cargar', () async {
    final repository = _CategoryRepository();
    final model = ReportIncidentViewModel(repository, StorageService());
    addTearDown(model.dispose);

    expect(model.selectedCategory, isNull);
    repository.complete([first, second]);
    await repository.loaded;

    expect(model.selectedCategory, same(first));
    model.setSelectedCategory(second);
    expect(model.selectedCategory, same(second));
  });

  test('no selecciona ninguna categoría si la lista está vacía', () async {
    final repository = _CategoryRepository();
    final model = ReportIncidentViewModel(repository, StorageService());
    addTearDown(model.dispose);

    repository.complete([]);
    await repository.loaded;

    expect(model.selectedCategory, isNull);
  });

  test('prefiere la categoría recomendada si está disponible', () async {
    final repository = _CategoryRepository();
    final model = ReportIncidentViewModel(repository, StorageService());
    addTearDown(model.dispose);
    final recommended = IncidentCategory(
      id: 'recommended',
      name: 'Recomendado',
      description: '',
    );

    repository.complete([first, recommended]);
    await repository.loaded;

    expect(model.selectedCategory, same(recommended));
  });

  test('excluye las categorías inactivas del reporte', () async {
    final repository = _CategoryRepository();
    final model = ReportIncidentViewModel(repository, StorageService());
    addTearDown(model.dispose);
    final inactiveRecommended = IncidentCategory(
      id: 'inactive',
      name: 'Recomendado',
      description: '',
      enabled: false,
    );

    repository.complete([inactiveRecommended, first]);
    await repository.loaded;

    expect(model.categories, [first]);
    expect(model.selectedCategory, same(first));
  });
}

class _CategoryRepository implements IncidentRepository {
  final _categories = Completer<Result<List<IncidentCategory>>>();
  final _loaded = Completer<void>();

  Future<void> get loaded => _loaded.future;

  void complete(List<IncidentCategory> categories) {
    _categories.complete(Result.success(categories));
  }

  @override
  Future<Result<List<IncidentCategory>>> getCategories() async {
    final result = await _categories.future;
    // La continuación del modelo se ejecuta después de esta respuesta.
    Future<void>.delayed(Duration.zero, _loaded.complete);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
