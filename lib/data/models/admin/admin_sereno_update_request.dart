enum AdminSerenoStatus {
  available('AVAILABLE', 'Disponible'),
  busy('BUSY', 'Atendiendo una incidencia'),
  offDuty('OFF_DUTY', 'Fuera de servicio');

  const AdminSerenoStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class AdminSerenoUpdateRequest {
  const AdminSerenoUpdateRequest({this.codeSereno, this.serviceStatus});

  final String? codeSereno;
  final AdminSerenoStatus? serviceStatus;

  Map<String, dynamic> toJson() => {
    if (codeSereno != null) 'codeSereno': codeSereno,
    if (serviceStatus != null) 'serviceStatus': serviceStatus!.apiValue,
  };
}
