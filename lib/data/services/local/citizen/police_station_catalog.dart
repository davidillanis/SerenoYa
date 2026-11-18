import 'package:sereno_ya/data/models/citizen/police_station.dart';

/// Sedes policiales del área urbana de Andahuaylas contrastadas con
/// directorios públicos de la PNP, municipios y fuentes cartográficas.
const andahuaylasPoliceStations = <PoliceStation>[
  PoliceStation(
    id: 'andahuaylas',
    name: 'Comisaría PNP Andahuaylas',
    type: 'Comisaría básica',
    district: 'Andahuaylas',
    address: 'Avenida Perú 189',
    mapQuery: 'Comisaría PNP Andahuaylas, Avenida Perú 189, Andahuaylas, Perú',
  ),
  PoliceStation(
    id: 'san-jeronimo',
    name: 'Comisaría PNP San Jerónimo',
    type: 'Comisaría básica',
    district: 'San Jerónimo',
    address: 'Avenida Alfonso Ugarte 111',
    mapQuery: 'Comisaría PNP San Jerónimo, Avenida Alfonso Ugarte 111, Andahuaylas, Perú',
  ),
  PoliceStation(
    id: 'talavera',
    name: 'Comisaría PNP Talavera',
    type: 'Comisaría básica',
    district: 'Talavera',
    address: 'Avenida Manco Cápac 501',
    mapQuery: 'Comisaría PNP Talavera, Avenida Manco Cápac 501, Talavera, Andahuaylas, Perú',
  ),
  PoliceStation(
    id: 'familia-andahuaylas',
    name: 'Comisaría de Familia Andahuaylas',
    type: 'Atención especializada',
    district: 'San Jerónimo',
    address: 'Jirón Carmen 542',
    mapQuery: 'Comisaría de Familia Andahuaylas, Jirón Carmen 542, San Jerónimo, Andahuaylas, Perú',
  ),
];
