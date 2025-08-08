// --- core/models/tamizaje_model.dart ---

import 'package:cloud_firestore/cloud_firestore.dart';
// 1. IMPORTAMOS EL SERVICIO DE CÁLCULO
import 'package:etl_tamizajes_app/core/services/calculation_service.dart';

class Tamizaje {
  // Campo para rastrear quién subió el registro
  // ... (El constructor principal no cambia)
  Tamizaje({
    required this.id,
    required this.sourceFile,
    required this.uploadedBy,
    required this.fechaIntervencion,
    required this.lugarIntervencion,
    required this.entornoIntervencion,
    required this.horaInicialIntervencion,
    required this.horaFinalIntervencion,
    this.codigoTamizajeManual,
    required this.nombres,
    required this.apellidos,
    required this.tipoDoc,
    required this.numeroDocumento,
    required this.nacionalidad,
    required this.fechaNacimiento,
    required this.edad,
    required this.sexoAsignadoNacimiento,
    required this.generoIdentificado,
    this.orientacionSexual,
    required this.grupoEtnico,
    this.otroGrupoEtnico,
    required this.poblacionCondicionSituacion,
    required this.poblacionMigrante,
    required this.tieneSeresSintientes,
    this.correoElectronico,
    required this.telefonoContacto,
    this.direccionResidencia,
    required this.barrioCorregimientoVereda,
    required this.comuna,
    this.eapb,
    this.tipoAseguramiento,
    required this.eps,
    required this.talla,
    required this.peso,
    required this.imc,
    required this.clasificacionImc,
    required this.presionSistolica,
    required this.presionDiastolica,
    this.circunferenciaAbdominal,
    required this.actividadFisica,
    required this.frecuenciaFrutasVerduras,
    required this.medicacionHipertension,
    required this.glucosaAltaHistorico,
    required this.antecedentesFamiliaresDiabetes,
    required this.esDiabetico,
    this.tipoDiabetes,
    required this.fuma,
    this.puntajeFindriscCalculado,
    this.riesgoFindrisc,
    required this.enfermedadCardiovascularRenalColesterol,
    this.riesgoCardiovascularOmsPorcentaje,
    this.clasificacionRiesgoCardiovascularOms,
    this.observaciones,
    required this.fechaRegistroBd,
    this.estratoSocioeconomico,
    this.latitud,
    this.longitud,
  });

  factory Tamizaje.fromMap(Map<String, dynamic> map) {
    // --- 2. INSTANCIAMOS EL SERVICIO Y PREPARAMOS LOS DATOS ---
    final calculationService = CalculationService();

    // Funciones seguras para convertir tipos
    int safeInt(dynamic val, [int fallback = 0]) =>
        int.tryParse(val?.toString() ?? '') ?? fallback;
    double safeDouble(dynamic val, [double fallback = 0.0]) =>
        double.tryParse(val?.toString() ?? '') ?? fallback;
    DateTime? safeDateTime(dynamic val) =>
        DateTime.tryParse(val?.toString() ?? '');

    final docId = map['numero_documento']?.toString().trim() ?? '';
    if (docId.isEmpty) {
      throw ArgumentError('El número de documento no puede ser nulo o vacío.');
    }

    // --- 3. PROCESO DE CÁLCULO Y ENRIQUECIMIENTO DE DATOS ---

    // 3.1. Parsear datos crudos necesarios para los cálculos
    final fechaNacimientoRaw = safeDateTime(map['fecha_nacimiento']);
    final pesoRaw = safeDouble(map['peso']);
    final tallaCmRaw = safeDouble(map['talla']);
    final presionSistolicaRaw = safeInt(map['presion_sistolica']);
    final circunferenciaAbdominalRaw =
        safeDouble(map['circunferencia_abdominal'], -1.0) == -1.0
        ? null
        : safeDouble(map['circunferencia_abdominal']);

    // 3.2. Normalizar valores de texto que se usarán en los cálculos
    final sexoNormalizado = _normalizeSexo(map['sexo_asignado_nacimiento']);
    final actividadFisicaNormalizado = _normalizeSiNo(map['actividad_fisica']);
    final medicacionHtaNormalizado = _normalizeSiNo(
      map['medicacion_hipertension'],
    );
    final glucosaAltaNormalizado = _normalizeSiNo(
      map['glucosa_alta_historico'],
    );
    final esDiabeticoNormalizado = _normalizeSiNo(map['es_diabetico']);
    final fumaNormalizado = _normalizeSiNo(map['fuma']);
    final enfermedadCardioNormalizado = _normalizeSiNo(
      map['enfermedad_cardiovascular_renal_colesterol'],
    );
    // Nota: 'frecuencia_frutas_verduras' y 'antecedentes_familiares_diabetes' no usan _normalizeSiNo, se pasan directamente.

    // 3.3. Ejecutar cálculos en secuencia

    // CÁLCULO DE EDAD
    final edadCalculada = fechaNacimientoRaw != null
        ? calculationService.calculateAge(fechaNacimientoRaw)
        : safeInt(map['edad']); // Fallback por si no hay fecha de nacimiento

    // CÁLCULO DE IMC Y SU CLASIFICACIÓN
    // Asumimos que la talla viene en cm si es > 3, y la convertimos a metros.
    final tallaEnMetros = tallaCmRaw > 3 ? tallaCmRaw / 100.0 : tallaCmRaw;
    final imcCalculado = calculationService.calculateIMC(
      pesoRaw,
      tallaEnMetros,
    );
    final clasificacionImcCalculada = calculationService.classifyIMC(
      imcCalculado,
    );

    // CÁLCULO DE FINDRISC
    final findriscResult = calculationService.calculateAndClassifyFINDRISC(
      age: edadCalculada,
      imc: imcCalculado,
      waistCircumference: circunferenciaAbdominalRaw,
      gender: sexoNormalizado,
      physicalActivity: actividadFisicaNormalizado,
      eatsFruitsAndVegs:
          map['frecuencia_frutas_verduras'], // Pasa el valor original
      htaMedication: medicacionHtaNormalizado,
      highGlucoseHistory: glucosaAltaNormalizado,
      familyDiabetesHistory:
          map['antecedentes_familiares_diabetes'], // Pasa el valor original
    );
    final puntajeFindriscCalculado = findriscResult['puntaje'] as int?;
    final riesgoFindriscCalculado = findriscResult['clasificacion'] as String?;

    // CÁLCULO DE RIESGO CARDIOVASCULAR (OMS)
    final whoRiskResult = calculationService.calculateAndClassifyWHORisk(
      age: edadCalculada,
      gender: sexoNormalizado,
      systolicPressure: presionSistolicaRaw,
      smokes: fumaNormalizado,
      isDiabetic: esDiabeticoNormalizado,
      hasPreviousCVD: enfermedadCardioNormalizado,
    );
    final riesgoCardioPorcentajeCalculado = whoRiskResult['riesgoPorcentaje'];
    final clasificacionRiesgoCardioCalculada =
        whoRiskResult['clasificacionRiesgo'];

    // --- 4. CONSTRUIMOS EL OBJETO TAMIZAJE CON LOS DATOS ENRIQUECIDOS ---
    return Tamizaje(
      uploadedBy: map['uploaded_by'] ?? 'Desconocido',
      // --- Datos de Identificación y Contexto ---
      id: docId,
      sourceFile: map['_sourceFile'] ?? 'N/A',
      fechaIntervencion: safeDateTime(map['fecha_intervencion']),
      lugarIntervencion: map['lugar_intervencion'] ?? '',
      entornoIntervencion: map['entorno_intervencion'] ?? '',
      horaInicialIntervencion: map['hora_inicial_intervencion'] ?? '',
      horaFinalIntervencion: map['hora_final_intervencion'] ?? '',
      codigoTamizajeManual: map['codigo_tamizaje_manual'],

      // --- Datos Demográficos (usando valores calculados y normalizados) ---
      nombres: map['nombres'] ?? '',
      apellidos: map['apellidos'] ?? '',
      tipoDoc: map['tipo_doc'] ?? '',
      numeroDocumento: docId,
      nacionalidad: map['nacionalidad'] ?? '',
      fechaNacimiento: fechaNacimientoRaw,
      edad: edadCalculada, // <= VALOR CALCULADO
      sexoAsignadoNacimiento: sexoNormalizado, // <= VALOR NORMALIZADO
      generoIdentificado: map['genero_identificado'] ?? '',
      orientacionSexual: map['orientacion_sexual'],
      grupoEtnico: map['grupo_etnico'] ?? '',
      otroGrupoEtnico: map['otro_grupo_etnico'],
      poblacionCondicionSituacion: map['poblacion_condicion_situacion'] ?? '',
      poblacionMigrante: map['poblacion_migrante'] ?? '',
      estratoSocioeconomico: map['estrato_socioeconomico'],
      latitud: map['latitud'] != null
          ? (map['latitud'] as num).toDouble()
          : null,
      longitud: map['longitud'] != null
          ? (map['longitud'] as num).toDouble()
          : null,

      // --- Contacto y Ubicación (normalizados) ---
      correoElectronico: map['correo_electronico'],
      telefonoContacto: map['telefono_contacto']?.toString() ?? '',
      direccionResidencia: map['direccion_residencia'],
      barrioCorregimientoVereda: map['barrio_corregimiento_vereda'] ?? '',
      comuna: _normalizeBarrio(map['comuna']),
      eps: _normalizeEps(map['eps']),
      eapb: map['eapb'],
      tipoAseguramiento: map['tipo_aseguramiento'],

      // --- Medidas Antropométricas (usando valores calculados) ---
      talla: tallaCmRaw, // Guardamos la talla original en cm
      peso: pesoRaw,
      imc: imcCalculado, // <= VALOR CALCULADO
      clasificacionImc: clasificacionImcCalculada, // <= VALOR CALCULADO
      presionSistolica: presionSistolicaRaw,
      presionDiastolica: safeInt(map['presion_diastolica']),
      circunferenciaAbdominal: circunferenciaAbdominalRaw,

      // --- Hábitos y Antecedentes (usando valores normalizados) ---
      actividadFisica: actividadFisicaNormalizado,
      frecuenciaFrutasVerduras: map['frecuencia_frutas_verduras'] ?? '',
      medicacionHipertension: medicacionHtaNormalizado,
      glucosaAltaHistorico: glucosaAltaNormalizado,
      antecedentesFamiliaresDiabetes:
          map['antecedentes_familiares_diabetes'] ?? '',
      esDiabetico: esDiabeticoNormalizado,
      tipoDiabetes: map['tipo_diabetes'],
      fuma: fumaNormalizado,
      tieneSeresSintientes: _normalizeSiNo(map['tiene_seres_sintientes']),
      enfermedadCardiovascularRenalColesterol: enfermedadCardioNormalizado,

      // --- Riesgos Calculados ---
      puntajeFindriscCalculado: puntajeFindriscCalculado, // <= VALOR CALCULADO
      riesgoFindrisc: riesgoFindriscCalculado, // <= VALOR CALCULADO
      riesgoCardiovascularOmsPorcentaje:
          riesgoCardioPorcentajeCalculado, // <= VALOR CALCULADO
      clasificacionRiesgoCardiovascularOms:
          clasificacionRiesgoCardioCalculada, // <= VALOR CALCULADO
      // --- Campos Adicionales ---
      observaciones: map['observaciones'],
      fechaRegistroBd: map['fecha_registro_bd'] is Timestamp
          ? map['fecha_registro_bd']
          : Timestamp.now(),
    );
  }
  final String uploadedBy;

  // El ID del documento en Firestore será el número de documento del paciente.
  final String id;
  // Campo para rastrear de qué archivo JSON provino el registro.
  final String sourceFile;

  // Campos del modelo de datos
  final DateTime? fechaIntervencion;
  final String lugarIntervencion;
  final String entornoIntervencion;
  final String horaInicialIntervencion;
  final String horaFinalIntervencion;
  final String? codigoTamizajeManual;
  final String nombres;
  final String apellidos;
  final String tipoDoc;
  final String numeroDocumento;
  final String nacionalidad;
  final DateTime? fechaNacimiento;
  final int edad;
  final String sexoAsignadoNacimiento;
  final String generoIdentificado;
  final String? orientacionSexual;
  final String grupoEtnico;
  final String? otroGrupoEtnico;
  final String poblacionCondicionSituacion;
  final String poblacionMigrante;
  final String tieneSeresSintientes;
  final String? correoElectronico;
  final String telefonoContacto;
  final String? direccionResidencia;
  final String barrioCorregimientoVereda;
  final String comuna;
  final String? eapb;
  final String? tipoAseguramiento;
  final String eps;
  final double talla;
  final double peso;
  final double imc;
  final String clasificacionImc;
  final int presionSistolica;
  final int presionDiastolica;
  final double? circunferenciaAbdominal;
  final String actividadFisica;
  final String frecuenciaFrutasVerduras;
  final String medicacionHipertension;
  final String glucosaAltaHistorico;
  final String antecedentesFamiliaresDiabetes;
  final String esDiabetico;
  final String? tipoDiabetes;
  final String fuma;
  final int? puntajeFindriscCalculado; // Ajustado a int?
  final String? riesgoFindrisc;
  final String enfermedadCardiovascularRenalColesterol;
  final String? riesgoCardiovascularOmsPorcentaje;
  final String? clasificacionRiesgoCardiovascularOms;
  final String? observaciones;
  final Timestamp fechaRegistroBd;
  final String? estratoSocioeconomico;
  final double? latitud;
  final double? longitud;

  // --- FUNCIONES DE NORMALIZACIÓN (PRIVADAS Y ESTÁTICAS) ---
  /// Normaliza valores de respuesta 'Si'/'No' a un formato estándar.
  ///
  /// Recibe un valor dinámico, lo limpia y lo compara contra un conjunto
  /// de variaciones conocidas para "Si" y "No". Usa Sets para una búsqueda
  /// de alta eficiencia.
  static String _normalizeSiNo(dynamic valor) {
    if (valor == null) return 'N/A'; // Retorna un valor por defecto para nulos

    // Normaliza la entrada: sin espacios y en minúsculas.
    final texto = valor.toString().trim().toLowerCase();
    if (texto.isEmpty) return 'N/A'; // Retorna un valor por defecto para vacíos

    // Usamos Sets (conjuntos) para una búsqueda de variaciones casi instantánea.
    // Solo necesitamos las versiones en minúsculas gracias a la normalización previa.
    const siValues = {'si', 'sí', 'sì', 'sí́'};
    const noValues = {'no', 'nó'};

    if (siValues.contains(texto)) {
      return 'Si';
    }
    if (noValues.contains(texto)) {
      return 'No';
    }

    // Si el valor no es un claro "Si" o "No" (p. ej., "No aplica", "No sabe"),
    // se retorna el valor original, pero capitalizado para mantener la consistencia.
    return texto[0].toUpperCase() + texto.substring(1);
  }

  static String _normalizeSexo(dynamic sexo) {
    if (sexo == null) return 'NO REGISTRA';
    final upperSexo = sexo.toString().trim().toUpperCase();
    if (upperSexo == 'FEMENINO' || upperSexo.contains('INTERSEXUAL')) {
      return 'Mujer';
    }
    if (upperSexo == 'MASCULINO') return 'Hombre';
    return upperSexo;
  }

  static String _normalizeEps(dynamic eps) {
    if (eps == null) {
      return 'N/A'; // Es más consistente devolver 'N/A' como estándar nulo.
    }

    final upperEps = eps.toString().trim().toUpperCase();
    if (upperEps.isEmpty) return 'N/A';

    // Mapa de patrones completo, consolidado y limpio.
    // Esta es ahora nuestra "fuente de la verdad".
    const patterns = {
      'N/A': [
        '(EN BLANCO)',
        'MMCC',
        'NA',
        'NO',
        'NO APLICA',
        'NO EPS',
        'NO REFIERE',
        'NO REPORTA',
        'NO TIENE',
        'OTRA',
        'OTRO',
        'SIDEMA',
        'SIN AFILIACION',
        'SIN ASEGURAMIENTO',
        'SIN ASEGURAMIENTOS',
      ],
      'ASOCIACIÓN INDÍGENA DEL CAUCA': [
        'AIC',
        'ASOCIACIÓN INDÍGENAS DEL CAUCA',
      ],
      'ALIANZA LUZ': ['ALIANZA LUZ'],
      'ASMET SALUD': [
        'AMET SALUD',
        'ASMED SALUD',
        'ASMET SALUD',
        'ASMETSALUD',
        'ASMETU',
        'ASNETSALUD',
      ],
      'PONAL': ['APONAL', 'POLICÍA NACIONAL', 'PONAL'],
      'SANIDAD MILITAR': [
        'BATALLON MILITAR',
        'MILITAR',
        'SANIDAD',
        'SANIDAD MILITAR',
      ],
      'NUEVA EPS': [
        'BUEVA EPS',
        'NIEVA EPS',
        'NUEBA EPS',
        'NUEVA EPS',
        'NUEVA EPS 1.67',
        'NUEVA EPS1.67',
        'NUEVA ESP',
        'NUEVAEPS',
      ],
      'CAPRECOM': ['CAPRECOM'],
      'COMFACHOCÓ': ['COMFA CHOCO'],
      'SOS': ['COMFANDI', 'CONFAMDI', 'S O S', 'S.O.S', 'SOS', 'SOS COMFANDI'],
      'COMFENALCO': ['COMFENALCO', 'COMFENALXO', 'CONFENALCO', 'CONTRIBUTIVO'],
      'COMPENSAR': ['COMPENSAR'],
      'COOMEVA': ['COOMEVA'],
      'COOSALUD': ['COOOSALUD', 'COOSALUD', 'COSALUD', 'COSSALUD'],
      'COSMITET': ['COSMITET'],
      'ECOPETROL': ['ECOPETROL'],
      'EMSSANAR': [
        'EMMSANAR',
        'EMSANAR',
        'EMSSANAE',
        'EMSSANAR',
        'EMSSANAY',
        'EMSSANR',
        'EMSSNAR',
        'ENSSANAR',
        'ESM3056',
        'ESPECIAL',
      ],
      'FAMISANAR': ['FAMIFANAR', 'FAMISANAR'],
      'FIDEICOMISO': ['FIDECOMISO'],
      'FOMAG': ['FOMAG'],
      'MALLAMAS': ['MALLAMAS', 'MAYAMAS'],
      'MUTUALSER': ['MUTUAL', 'MUTUALSER'],
      'SALUD TOTAL': ['SALID TOTAL', 'SALUD TOTAL', 'SALUDTOTAL'],
      'SALUDCOOP': ['SALUD COP', 'SALUDCOOP'],
      'SANITAS': ['SANITA', 'SANITARIO', 'SANITAS'],
      'SISANAR': ['SISANAR'],
      'SURA': ['SURA'],
    };

    for (final entry in patterns.entries) {
      // Si la entrada del usuario coincide con alguna de las variaciones conocidas...
      if (entry.value.contains(upperEps)) {
        return entry.key; // ...devolver el nombre canónico.
      }
    }

    // Si no hay coincidencias, devolver la entrada original normalizada.
    return upperEps;
  }

  static String _normalizeBarrio(dynamic barrio) {
    if (barrio == null) return 'NO IDENTIFICADO';

    // Normalizar la entrada una sola vez
    final upperBarrio = barrio.toString().trim().toUpperCase();

    // Si la entrada normalizada está vacía, retornar 'N/A'
    if (upperBarrio.isEmpty) return 'N/A';

    // Mapa con claves únicas y todas sus variaciones.
    // Las variaciones ya están en mayúsculas para una comparación directa.
    const patterns = {
      'N/A': ['', 'NO REFIERE', 'NO SABE'],
      'CAPRI': ['CAPRI'],
      'MOJICA I': ['MOJICA 1', 'MOGICA', 'MOJICA', 'MOJICA1'],
      'POBLADO II': ['POBLADO 2', 'POBLADO II', 'POBLADO2'],
      'VALLE GRANDE': ['VALLE GRANDE', 'VALE GRANDE'],
      '12 DE OCTUBRE': ['12 DE OCTUBRE', '12 OCTUBRE'],
      '7 DE AGOSTO': ['7 DE AGOSTO'],
      'EL AGUACATAL': ['AGUACATAL', 'AGUACATALA', 'EL AGUACATAL'],
      'ALFEREZ REAL': ['ALFEREZ REAL'],
      'ALFONSO BONILLA': [
        'ALFONSO BONILLA',
        'ALFONSO BONILLA ARAGON',
        'ALFONSO BONILLA ARANGON',
        'ALFONZO BONILLA',
        'ALGONSO BONILLA',
        'BONILLA',
        'BONILLA ARAGON',
        'BONILLA ARANGON',
        'BONILLQ ARAGÓN',
      ],
      'ALFONSO LOPEZ': ['ALFONSO LOPEZ', 'ALFONSO LÓPEZ'],
      'ALIRIO MORA': ['ALIRIO MORA'],
      'ALTA SUIZA': ['ALTA SUIZA'],
      'ALTO JORDAN': ['ALTO JORDAN'],
      'ALTO MELÉNDEZ': ['ALTO MELÉNDEZ'],
      'ANDRES SANIN': ['ANDRES SANIN'],
      'ANTONIO NARIÑO': ['ANTONIO', 'ANTONIO NARIÑO'],
      'ARMENIA QUINDIO': ['ARMENIA', 'ARMENIA QUINDIO'],
      'ASENTAMIENTO BRISAS DE CARTON': ['ASENTAMIENTO BRISAS DE CARTON'],
      'ASENTAMIENTO BRISAS DE COMUNEROS': ['ASENTAMIENTO BRISAS DE COMUNEROS'],
      'ATANACIO GIRARDOT': ['ATANACIO GIRARDOT'],
      'BAJO AGUACATAL': ['BAJO AGUACATAL'],
      'BARRANCA BERMEJA': ['BARRANCA BERMEJA'],
      'BARRIO TALLER': ['BARRIO TALLER'],
      'BELARCAZAR': ['BELARCAZAR'],
      'BELISARIO BETANCOURT': [
        'BELISARIO',
        'BELISARIO BETANCOURT',
        'BELIZARIO NETANCOUR',
      ],
      'BELISARIO CAICEDo': ['BELISARIO CAICEDO'],
      'BELLO HORIZONTE': ['BELLO HORIZONTE'],
      'VILLA MERCEDES': ['BILLA MERCEDES', 'VILLA MERCEDES'],
      'BOGOTÁ': ['BOGOTA'],
      'BONANZAS JAMUNDI': ['BONANZAS JAMUNDI'],
      'BRISA DE LAS TORRES': ['BRISA DE LAS TORRES'],
      'BRISAS DE COMUNEROS I': ['BRISAS DE COMUNEROS 1'],
      'BRISAS DE SALOMIA': ['BRISAS DE SALOMIA'],
      'BRISAS DEL BOSQUE': ['BRISAS DEL BOSQUE'],
      'BRISAS PALMA': ['BRISAS PALMA'],
      'CACHIPAY': ['CACHIPAY'],
      'CALI MÍO NORTE': ['CALI MÍO NORTE'],
      'CALIMIO DECEPAZ': ['CALIMIO', 'CALIMIO DECEPAS', 'CALIMIO DECEPAZ'],
      'CALIPSO': ['CALIPSO'],
      'CANDELARIA': ['CANDELARIA'],
      'CANEY': ['CANEY'],
      'CARLOS LLERAS': ['CARLOS LLERAS'],
      'PIZAMOS': ['CARRERA 36 95A - 15'],
      'LA CEIBA': ['CEIBA', 'CEIBAS'],
      'CEREZOS TALANGA': ['CEREZOS TALANGA'],
      'CHAMPAÑAG': ['CHAMPAÑAG'],
      'CHARCO AZUL': ['CHARCO AZUL'],
      'CHIMINANGOS II': ['CHIMINANGOS 2'],
      'CHIPICHAPE': ['CHIPICHAPE'],
      'CIUDAD CÓRDOBA': [
        'CIRDOBA',
        'CIUDAD COEDOT',
        'CIUDAD CORDOBA',
        'CIUDAD CROSIBAY',
        'CIUSAD CORDOBA',
        'CORDOBA',
        'CORSOBA',
        'COUDAD CÓRDOBA',
        'CTOUDAD CÓRDOBA',
        'CUIDAD CORDOBA',
      ],
      'CIUDAD 2000': ['CIUDAD 2000'],
      'CIUDAD DEL CAMPO': ['CIUDAD DEL CAMPO'],
      'CIUDAD MELENDEZ': ['CIUDAD MELENDEZ', 'COUDAD MELENDEZ'],
      'CIUDAD MODELO': ['CIUDAD MODELO'],
      'CIUDADELA COMFANDI': ['CIUDADELA COMFANDI'],
      'CIUDADELA DEL RIO': [
        'CIUDADELA DEL RIO',
        'COIDADELA DEL RIO',
        'COUDADELA DEL RIO',
      ],
      'CIUDADELA INVICALI': ['CIUDADELA IMVICALI'],
      'CIUDADELA SAN MARCOS': ['CIUDADELA SAN MARCO'],
      'CIUDADELA TERRANOVA': ['CIUDADELA TERRANOVA'],
      'COLONIA NARIÑENSE': ['COLONIA NARIÑENSE'],
      'COLSEGUROS': ['COLSEGUROS'],
      'COMUNEROS I': [
        'COMENEROS 1',
        'COMINEROS1',
        'COMUNERO',
        'COMUNERO 1',
        'COMUNEROS',
        'COMUNEROS 1',
        'COMUNEROS1',
      ],
      'COMFENALCO': ['COMFENALCO'],
      'COMPARTIR': ['COMPARRIR', 'COMPARTIR'],
      'COMUNEROS II': ['COMUNEROS 2', 'COMUNEROS II'],
      'EL PONDAJE': ['CONDAJO', 'EL PONDAJE', 'PONDAJE'],
      'CORREGIMIENTO DE NAVARRO': [
        'CORREGIMIENTO',
        'CORREGIMIENTO DE NAVARRO',
        'NAVARRO',
      ],
      'CORREGIMIENTOS LA TUPIA PRADERA': ['CORREGIMIENTOS LA TUPIA PRADERA'],
      'CRISTO REY': ['CRISTO REY'],
      'CRISTÓBAL COLÓN': ['CRISTÓBAL COLON'],
      'DECEPAZ': ['DECEPA', 'DECEPAS', 'DECEPAZ', 'DESEPAS'],
      'DEPARTAMENTAL': ['DEPARTAMENTAL'],
      'EL DIAMANTE': [
        'DIAAMANTE',
        'DIAMANETE',
        'DIAMANTE',
        'DIAMENTE',
        'EL DIAMANTE',
      ],
      'EL DORADO': ['DORADO', 'EL DORADO'],
      'EDUARDO SANTOS': ['EDUARDO SANTOS'],
      'EL VERGEL': ['EL BERGEL', 'EL VERGEL', 'ELVERGER', 'VERGEL'],
      'EL GUABAL': ['EL GUABAL', 'GUABAL'],
      'EL LAGUITO': ['EL LAGUITO'],
      'EL POBLADO I': [
        'EL POBLADO',
        'POBLA 2',
        'POBLADO',
        'POBLADO 1',
        'POBLADO I',
        'POBLADO1',
      ],
      'EL RETIRO': ['EL RETIRO', 'RESOS', 'RETIRO', 'RETIRÓ'],
      'EL RODEO': ['EL RODEO', 'RODEO'],
      'EL VALLADO': ['EL VALLADO', 'VALLADO'],
      'EUCARISTICO': ['EUCARISTICO'],
      'CIUDADELA FLORALIA': ['FLORALIA'],
      'LA FLORESTA': ['FLORESTA', 'LA FLORESTA', 'VIEJA FLORESTA'],
      'FLORIDA': ['FLORIDA'],
      'LA FORTALEZA': ['FORTALEZA'],
      'LA GRAN COLOMBIA': ['GRAN COLOMBIA'],
      'GRANADA': ['GRANADAS'],
      'LOS GUADUALES': ['GUADUALES'],
      'GUALANDAY': ['GUALANDAI', 'GUALANDAY'],
      'GUAYACANES, LA RIVERA': ['GUAYACANES, LA RIVERA'],
      'EL INGENIO': ['INGENIO'],
      'INVASION VALLADITO': ['INVASION VALLADITO'],
      'INVASION VILLA LUZ': ['INVASION VILLA LUZ'],
      'INVICALI': ['INVICALI'],
      'IPIALES NARIÑO': ['IPIALES NARIÑO'],
      'JAMUNDI VALLE': ['JAMUNDI'],
      'JARILLON RIO CAUCA': ['JARILLON RIO CAUCA'],
      'JORGE ELIECER GAITAN': ['JORGE ELIECER GAITAN'],
      'JUANCHITO': ['JUANCHITO'],
      'JUNIN': ['JUNIN'],
      'LA ALEMEDA': ['LA ALEMEDA'],
      'LA BASE': ['LA BASE'],
      'LA ESPERANZA': ['LA ESPERANZA'],
      'LA FLORA': ['LA FLORA'],
      'LA INDEPENDENCIA': ['LA INDEPENDENCIA'],
      'LA LUNA': ['LA LUNA'],
      'LA NUEVA BASE': ['LA NUEVA BASE'],
      'LA PAZ': ['LA PAZ'],
      'LA PAZ II': ['LA PAZ 2'],
      'LA RIVERA': ['LA RIVERA'],
      'LA UNION': ['LA UNION'],
      'UNIÓN DE VIVIENDA POPULAR': ['LA UNIÓN', 'UNION', 'UNION DE VIVIENDA'],
      'LOS LAGOS I': ['LAGOS', 'LOS LAGOS', 'LOS LAGOS 1', 'LOSLAGOS'],
      'LOS LAGOS II': ['LAGOS 2', 'LOS LAGOS 2'],
      'LANO VERDE': ['LANO VERDE'],
      'LAS ACACIAS': ['LAS ACACIAS'],
      'LAS AMÉRICAS': ['LAS AMÉRICAS'],
      'LAS AMERICAS, PALMIRA': ['LAS AMERICAS, PALMIRA'],
      'LAS DELICIAS': ['LAS DELICIAS'],
      'LAS GRANJAS': ['LAS GRANJAS'],
      'LAS ORQUIDEAS': ['LAS ORQUIDEAS', 'LAS ORQUÍDEAS', 'ORQUIDEAS'],
      'LAS PALMITAS': ['LAS PALMITAS'],
      'LAS VEGAS COMFANDI': [
        'LAS VEGAS',
        'VEGAS COMFANDI',
        'VEGAS DE COMFANDI',
        'VEGAS DE CONFANDI',
      ],
      'LAUREANO GÓMEZ': [
        'LAUREANO',
        'LAUREANO G',
        'LAUREANO GOMEZ',
        'LAUREANO GÓMEZ',
        'LAURIANO GOMEZ',
        'LAURIANO GÓMEZ',
      ],
      'LEÓN XIII': ['LEON 13', 'LEON XIII'],
      'LOS LIBERTADORES': ['LIBERTADORES', 'LIBERTASLRES', 'LIBERTTADORES'],
      'EL LIDO': ['LIDO'],
      'EL LIMONAR': ['LIMONAR'],
      'LLANO VERDE': ['LLANO VERDE'],
      'LLERAS CAMARGO': ['LLERAS', 'LLERAS CAMARGO', 'LLERAS RESTREPO'],
      'LOS ALCAZARES': ['LOS ALCAZARES'],
      'LOS CEREZOS': ['LOS CEREZOS'],
      'LOS CHORROS': ['LOS CHORROS'],
      'LOS FARALLONES': ['LOS FARALLONES'],
      'LOS NARANJOS I': ['LOS NARANJOS', 'NARANJOS', 'NARANJOS 1'],
      'LOS NARANJOS II': ['LOS NARANJOS 2', 'NARANJOS 2', 'NATANJOS 2'],
      'LOS PINOS': ['LOS PINOS'],
      'LOS ROBLES': ['LOS ROBLES', 'ROBLES'],
      'LUCES': ['LUCES'],
      'MELENDEZ': ['MALENDEZ', 'MELENDEZ'],
      'MANUELA BELTRÁN': [
        'MANUELA',
        'MANUELA BELTRAB',
        'MANUELA BELTRAN',
        'MANUELA BELTYRAN',
      ],
      'MANZANARES': ['MANZANARES'],
      'MARIANO RAMOS': ['MARIANO RAMOS', 'MARIANOS RAMOS', 'MRIANO RAMOS'],
      'MARROQUIN I': [
        'MAROQUIN',
        'MAROQUIN 1',
        'MARRONQUIN',
        'MARROQUIN',
        'MARROQUÍN',
        'MARROQUIN 1',
        'MARROQUÍN 1',
        'MARROQUIN I',
        'MARROQUIN1',
        'MORROQUIN',
      ],
      'MARROQUIN II': [
        'MAROQUIN 2',
        'MARROQIN II',
        'MARROQUIN 2',
        'MARROQUÍN 2',
        'MARROQUIN II',
        'MARROQUIN2',
      ],
      'MARROQUIN III': ['MAROQUIN 3', 'MARROQUIN 3', 'MARROQUÍN TRES'],
      'MATAPALOS PALMIRA': ['MATAPALOS'],
      'MEDELLIN': ['MEDELLIN'],
      'MIRAFLORES': ['MIRAFLORES'],
      'MODELO BOGOTÁ': ['MODELO BOGOTÁ'],
      'MOJICA II': ['MIJICA2', 'MOJICA 2', 'MOJICA2'],
      'MOJICA INVASIÓN PALMA ALTA': ['MOJICA INVASIÓN PALMA ALTA'],
      'MONTEBELLO': ['MONTEBELLO'],
      'MORICHAL DE COMFANDI': ['MORICHAL'],
      'MORTIÑAL': ['MUTIÑAL'],
      'NAPOLES': ['NAPOLES'],
      'NORMANDÍA': ['NORMANDÍA'],
      'NUEVA FLORESTA': ['NUEVA FLORESTA'],
      'NUEVO HORIZONTE': ['NUEVO HORIZONTE'],
      'NUEVO LATIR': ['NUEVO LATIR'],
      'OASIS TERRANOVA': ['OASIS TERRANOVA'],
      'OBRERO': ['OBRERO'],
      'OLAYA HERRERA': ['OLAYA HERRERA'],
      'OMAR TORRIJOS': [
        'OMAR TORRIJO',
        'OMAR TORRIJOS',
        'OMAR TORRILLO',
        'OMAR TRUJILLO',
      ],
      'PALMIRA': ['PALMIRA'],
      'PANAMERICANO': ['PANAMERICANO'],
      'PETECUY': ['PETECUY'],
      'PUERTAS DEL SOL I': [
        'PIERTAS DEL SOL',
        'PUERTA DEL SOL',
        'PUERTAS DE SOL',
        'PUERTAS DEL SOL',
        'PUERTAS DEL SOL 1',
        'PUERTS DEL SOL',
        'PUESTAS DEL SOL',
      ],
      'PILAR TAYRONA': ['PILAR TAYRONA'],
      'PIZAMOS I': ['PIZAMOS', 'PIZAMOS 1', 'SUERTE 90'],
      'PIZAMOS II': ['PIZAMOS 2'],
      'PIZAMOS III': ['PIZAMOS 3'],
      'POBLADO CAMPESTRE': ['POBLADO CAMPESTRE'],
      'POPULAR': ['POPULAR'],
      'PORTAL': ['PORTAL'],
      'POTRERO GRANDE': [
        'POTERORO GRANDE',
        'POTRERO',
        'POTRERO GRANDE',
        'POTRERO GRANDE GRANDE',
        'POTRERO GRANDE GRANDE SECTOR 4',
        'POTRERO GRANDE SECTOR 2',
        'POTRERO GRANDE SECTOR 8',
        'POTRERO SECTOR 9',
        'SECTOR11',
      ],
      'PRADOS DEL SUR': ['PRADOS DEL SUR'],
      'LA PRIMAVERA': ['PRIMAVERA'],
      'PUERTAS DEL SOL III': ['PUERTAS DEL SOL 3'],
      'PUERTAS DEL SOL VI': ['PUESTAS DEL SOL6'],
      'QUINTAS DEL SOL': ['QUINTAS DEL SOL'],
      'EL REFUGIO': ['REFUGIO'],
      'REMANSOS DE COMFANDI': [
        'REMANSO DE COMFANDI',
        'REMANSOS',
        'REMANSOS DE COMFANDI',
      ],
      'REPUBLICA DE ISRAEL': ['REPUBLICA', 'REPUBLICA DE ISRAEL'],
      'RICARDO BALCAZAR': ['RICARDO BALCAZAR', 'RICARDO BELALCAZAR'],
      'RODRIGO LARA BONILLA': ['RODRIGO LARA', 'RODRIGO LARA BONILLA'],
      'SAN MARCOS': ['SA MARCO', 'SAN MARCO', 'SAN MARCOS'],
      'SALOMIA': ['SALOMIA'],
      'SAMANES DE GUADALUPE': ['SAMANAS DE GUADALUPE', 'SAMANES'],
      'SAMANES DEL CAUCA': ['SAMANES DEL CAUCA'],
      'SAN ANTONIO': ['SAN ANTONIO', 'SAN ANTONIO MEDELLÍN'],
      'SAN BENITO': ['SAN BENITO'],
      'SAN BOSCO': ['SAN BOSCO'],
      'SAN CALLETANO': ['SAN CALLETANO'],
      'SAN CARLOS': ['SAN CARLOS'],
      'SAN CRISTOBAL': ['SAN CRISTOBAL'],
      'SAN FERNANDO': ['SAN FERNANDO'],
      'SAN JUDAS': ['SAN JUDAS'],
      'SAN LUIS': ['SAN LUIS'],
      'SAN MARINO': ['SAN MARINO'],
      'SAN PEDRO': ['SAN PEDRO'],
      'SAN PEDRO CLAVER': ['SAN PEDRO CLAVEL', 'SAN PEDRO CLAVER'],
      'SAN VICENTE': ['SAN VICENTE'],
      'SANTA ANITA': ['SANTA ANITA'],
      'SANTA ELENA': ['SANTA ELENA'],
      'SANTA FE': ['SANTA FE'],
      'SANTA ISABEL': ['SANTA ISABEL'],
      'SANTA MÓNICA': ['SANTA MÓNICA'],
      'SANTA RITA': ['SANTA RITA'],
      'SANTA TERESITA': ['SANTA TERESITA'],
      'SANTO DOMINGO': ['SANTO DOMINGO'],
      'ASENTAMIENTO CINTA DE SARDI': ['SARDI'],
      'SILOE': ['SILOE'],
      'LA SIRENA': ['SIRENA'],
      'SOL DE ORIENTE': ['SOL DE ORIENTE'],
      'EL SUCRE': ['SUCRE'],
      'TALANGA I': ['TALANGA', 'TALANGA 1'],
      'TALANGA III': ['TALANFA 3', 'TALANGA 3', 'TALANGA 3COMPARTIR'],
      'TALANGA IV': ['TALANGA 4'],
      'TALANGA V': ['TALANGA 5'],
      'TERCER MILENIO': ['TERCER MILENIO'],
      'TERRON COLORADO': ['TERRON'],
      'EL TREBOL': ['TREBOL'],
      'EL TRONCAL': ['TRONCAL'],
      'TULUA VALLE': ['TULUA'],
      'ULPIANO LLOREDA': ['ULPIANO', 'ULPIANO LLOREDA'],
      'VALLE DEL LILI': ['VALLE DEL LILI'],
      'VEREDA EL ARENAL': ['VEREDA ARENAL'],
      'VIA CANDELARIA': ['VIA CANDELARIA'],
      'VILLA BLANCA': ['VILLA BLANCA'],
      'VILLA COLOMBIA': ['VILLA COLOMBIA'],
      'VILLA DEL LAGO': ['VILLA DEL LAGO'],
      'VILLA DEL LIDO': ['VILLA DEL LIDO'],
      'VILLA DEL SUR': ['VILLA DEL SUR'],
      'VILLA LUZ': ['VILLA LUZ'],
      'VILLANUEVA': ['VILLA NUEVA'],
      'VILLA SAN MARCOS': [
        'VILLA SAN MARCO',
        'VILLA SAN MARCOS',
        'VILLA SANMARCOS',
      ],
      'VIPASA': ['VIPASA'],
      'VISTA HERMOSA FLORENCIA': ['VISTA HERMOSA FLORENCIA'],
      'YIRA CASTRO': ['YIRA CASTRO'],
      'YUMBO VALLE': ['YUMBO-VALLE'],
    };

    // Iterar sobre las entradas del mapa
    for (final entry in patterns.entries) {
      // Usar una lista que incluya la clave canónica y todas sus variaciones
      final allVariations = [entry.key.toUpperCase(), ...entry.value];
      if (allVariations.contains(upperBarrio)) {
        return entry.key; // Retornar la clave canónica y estandarizada
      }
    }

    // Si no se encuentra ninguna coincidencia, devolver la entrada original normalizada
    return upperBarrio;
  }

  // static String? _normalizeRiesgoFindrisc(dynamic riesgo) {
  //   if (riesgo == null) return null;
  //   final upperRiesgo = riesgo.toString().trim().toUpperCase();
  //   if (upperRiesgo.contains('MUY ALTO')) return 'RIESGO MUY ALTO';
  //   if (upperRiesgo.contains('ALTO')) return 'RIESGO ALTO';
  //   if (upperRiesgo.contains('MODERADO')) return 'RIESGO MODERADO';
  //   if (upperRiesgo.contains('LIGERAMENTE ELEVADO')) {
  //     return 'LIGERAMENTE ELEVADO';
  //   }
  //   if (upperRiesgo.contains('BAJO')) return 'RIESGO BAJO';
  //   return upperRiesgo; // O 'NO REGISTRA' si se prefiere un valor por defecto
  // }

  // Método para convertir la instancia a un mapa, útil para subir a Firebase.
  Map<String, dynamic> toMap() {
    return {
      'uploaded_by': uploadedBy,
      'fecha_intervencion': fechaIntervencion?.toIso8601String(),
      'lugar_intervencion': lugarIntervencion,
      'entorno_intervencion': entornoIntervencion,
      'hora_inicial_intervencion': horaInicialIntervencion,
      'hora_final_intervencion': horaFinalIntervencion,
      'codigo_tamizaje_manual': codigoTamizajeManual,
      'nombres': nombres,
      'apellidos': apellidos,
      'tipo_doc': tipoDoc,
      'numero_documento': numeroDocumento,
      'nacionalidad': nacionalidad,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'edad': edad,
      'sexo_asignado_nacimiento': sexoAsignadoNacimiento,
      'genero_identificado': generoIdentificado,
      'orientacion_sexual': orientacionSexual,
      'grupo_etnico': grupoEtnico,
      'otro_grupo_etnico': otroGrupoEtnico,
      'poblacion_condicion_situacion': poblacionCondicionSituacion,
      'poblacion_migrante': poblacionMigrante,
      'tiene_seres_sintientes': tieneSeresSintientes,
      'correo_electronico': correoElectronico,
      'telefono_contacto': telefonoContacto,
      'direccion_residencia': direccionResidencia,
      'barrio_corregimiento_vereda': barrioCorregimientoVereda,
      'comuna': comuna,
      'eapb': eapb,
      'tipo_aseguramiento': tipoAseguramiento,
      'eps': eps,
      'talla': talla,
      'peso': peso,
      'imc': imc,
      'clasificacion_imc': clasificacionImc,
      'presion_sistolica': presionSistolica,
      'presion_diastolica': presionDiastolica,
      'circunferencia_abdominal': circunferenciaAbdominal,
      'actividad_fisica': actividadFisica,
      'frecuencia_frutas_verduras': frecuenciaFrutasVerduras,
      'medicacion_hipertension': medicacionHipertension,
      'glucosa_alta_historico': glucosaAltaHistorico,
      'antecedentes_familiares_diabetes': antecedentesFamiliaresDiabetes,
      'es_diabetico': esDiabetico,
      'tipo_diabetes': tipoDiabetes,
      'fuma': fuma,
      'puntaje_findrisc_calculado': puntajeFindriscCalculado,
      'riesgo_findrisc': riesgoFindrisc,
      'enfermedad_cardiovascular_renal_colesterol':
          enfermedadCardiovascularRenalColesterol,
      'riesgo_cardiovascular_oms_porcentaje': riesgoCardiovascularOmsPorcentaje,
      'clasificacion_riesgo_cardiovascular_oms':
          clasificacionRiesgoCardiovascularOms,
      'observaciones': observaciones,
      'fecha_registro_bd': fechaRegistroBd,
      'estrato_socioeconomico': estratoSocioeconomico,
      'latitud': latitud,
      'longitud': longitud,
      '_sourceFile': sourceFile,
    };
  }
}
