import 'package:flutter/foundation.dart';
import 'package:sereno_ya/data/models/officer/officer_incident.dart';
import 'package:sereno_ya/data/repositories/officer/officer_repository.dart';

class OfficerDetailViewModel extends ChangeNotifier {
  OfficerDetailViewModel(this._repository, this.id) {
    load();
  }
  final OfficerRepository _repository;
  final String id;
  OfficerIncident? item;
  bool loading = false;
  bool saving = false;
  bool acceptedHere = false;
  bool changed = false;
  bool _disposed = false;
  String? error;
  Future<void> load() async {
    if (saving || _disposed) return;
    await _load();
  }

  Future<void> _load() async {
    if (loading || _disposed) return;
    loading = true;
    error = null;
    _notify();
    final result = await _repository.detail(id);
    if (_disposed) return;
    if (result.isSuccess) {
      item = result.data;
    } else {
      error = result.failure!.message;
    }
    loading = false;
    _notify();
  }

  Future<String?> act({int? etaMinutes}) async {
    if (_disposed || saving || loading || item == null) {
      return 'Espera a que termine la operación.';
    }
    final status = item!.status;
    if (status == OfficerIncidentStatus.pending &&
        (etaMinutes == null || etaMinutes < 1 || etaMinutes > 180)) {
      return 'Ingresa un tiempo entre 1 y 180 minutos.';
    }
    final next = switch (status) {
      OfficerIncidentStatus.enRoute => OfficerIncidentStatus.attending,
      OfficerIncidentStatus.attending => OfficerIncidentStatus.attended,
      _ => null,
    };
    if (status != OfficerIncidentStatus.pending && next == null) {
      return 'Este incidente no admite esa operación.';
    }
    saving = true;
    _notify();
    final result = status == OfficerIncidentStatus.pending
        ? await _repository.accept(id, etaMinutes!)
        : await _repository.update(id, next!);
    if (_disposed) return null;
    if (result.isSuccess) {
      changed = true;
      acceptedHere = acceptedHere || status == OfficerIncidentStatus.pending;
      item =
          null; // Never leave stale actions enabled after a successful write.
      await _load();
    }
    saving = false;
    _notify();
    return result.failure?.message;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
