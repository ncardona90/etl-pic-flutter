// lib/features/data_management/formulario_tamizaje_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:etl_tamizajes_app/core/models/tamizaje_model.dart';
import 'package:etl_tamizajes_app/core/services/calculation_service.dart';
import 'package:etl_tamizajes_app/features/auth/auth_provider.dart';
import 'package:geolocator/geolocator.dart';

// =======================================================================
// --- NUEVO FORMATEADOR DE FECHA (dd/MM/yyyy) ---
// =======================================================================
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Solo permite dígitos
    final newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limita a 8 dígitos (ddmmyyyy)
    if (newText.length > 8) {
      return oldValue;
    }

    var formattedText = '';
    if (newText.isNotEmpty) {
      formattedText += newText.substring(
        0,
        newText.length > 2 ? 2 : newText.length,
      );
      if (newText.length > 2) {
        formattedText += '/';
        formattedText += newText.substring(
          2,
          newText.length > 4 ? 4 : newText.length,
        );
        if (newText.length > 4) {
          formattedText += '/';
          formattedText += newText.substring(4, newText.length);
        }
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class FormularioTamizajeView extends StatefulWidget {

  const FormularioTamizajeView({
    super.key,
    this.initialData,
    required this.onSave,
    this.onCancel,
  });
  final Tamizaje? initialData;
  final void Function(Tamizaje) onSave;
  final VoidCallback? onCancel;

  @override
  State<FormularioTamizajeView> createState() => _FormularioTamizajeViewState();
}

class _FormularioTamizajeViewState extends State<FormularioTamizajeView> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _formData;
  final bool _isSaving = false;

  final _calculationService = CalculationService();

  // Variables de estado para la UI de resultados
  int? _edadCalculada;
  double? _imcCalculado;
  String? _clasificacionImc;
  int? _puntajeFindrisc;
  String? _riesgoFindrisc;
  String? _riesgoOmsPorcentaje;
  String? _clasificacionOms;

  final TextEditingController _otroGrupoEtnicoController =
      TextEditingController();

  double? _latitud;
  double? _longitud;

  // Listas de opciones
  final List<String> _opcionesEntorno = [
    'Hogar',
    'Educativo',
    'Comunitario',
    'Laboral',
    'Institucional',
  ];
  final List<String> _tiposDocumento = [
    'Cédula de Ciudadanía',
    'Cédula de Extranjería',
    'Pasaporte',
    'Otro',
  ];
  final List<String> _opcionesSexo = ['Masculino', 'Femenino'];
  final List<String> _opcionesGeneroIdentificado = [
    'Masculino',
    'Femenino',
    'Transgénero',
    'Transformista',
    'Travesti',
    'Transgenerista',
    'Transexual',
    'No binario',
    'Fluido',
  ];
  final List<String> _opcionesOrientacionSexual = [
    'Heterosexual',
    'Homosexual',
    'Bisexual',
    'Pansexual',
    'Asexual',
  ];
  final List<String> _opcionesGrupoEtnico = [
    'Ninguno',
    'Otro',
    'Indígena',
    'Rrom',
    'NARP',
  ];
  final List<String> _opcionesPoblacionCondicion = [
    'Ninguna',
    'Persona con discapacidad',
    'Víctima del conflicto armado',
    'Habitante de y en calle',
    'Persona privada de la libertad',
    'Campesino',
    'Madre Cabeza de Hogar',
  ];
  final List<String> _opcionesPoblacionMigrante = [
    'No aplica',
    'Regular',
    'Irregular',
  ];
  final List<String> _opcionesSiNo = ['Si', 'No'];
  final List<String> _opcionesComuna = List.generate(
    22,
    (i) => (i + 1).toString(),
  )..add('Corregimiento');
  final List<String> _opcionesTipoAseguramiento = [
    'Contributivo',
    'Subsidiado',
    'Sin Aseguramiento',
    'Régimen Especial',
  ];
  final List<String> _opcionesFrecuenciaFrutasVerduras = [
    'Todos los días',
    'NO todos los días',
  ];
  final List<String> _opcionesAntecedentesDiabetes = [
    'No',
    'Sí: abuelos, tía, tío, primo hermano',
    'Sí: padres, hermanos o hijos',
  ];
  final List<String> _opcionesTipoDiabetes = ['N/A', '1', '2', 'Gestacional'];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
    _otroGrupoEtnicoController.addListener(() {
      _formData['otroGrupoEtnico'] = _otroGrupoEtnicoController.text;
    });
    _getLocation();
  }

  @override
  void dispose() {
    _otroGrupoEtnicoController.dispose();
    super.dispose();
  }

  void _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, active los servicios de ubicación.'),
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El permiso de ubicación fue denegado permanentemente.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _latitud = pos.latitude;
          _longitud = pos.longitude;
          _formData['latitud'] = _latitud;
          _formData['longitud'] = _longitud;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener la ubicación: $e')),
        );
      }
    }
  }

  void _initializeFormData() {
    // --- CORRECCIÓN CLAVE AQUÍ ---
    // Se usa context.read<AuthProvider>() que es la forma segura de obtener
    // el provider dentro de initState.
    final authProvider = context.read<AuthProvider>();
    if (widget.initialData != null) {
      _formData = widget.initialData!.toMap();
      _otroGrupoEtnicoController.text = _formData['otroGrupoEtnico'] ?? '';
    } else {
      // Determinar el nombre del usuario autenticado para el campo 'uploaded_by'
      final appUser = authProvider.user;
      final String uploaderName = appUser == null
          ? 'App User'
          : (appUser.userName.isNotEmpty
              ? appUser.userName
              : (appUser.displayName.isNotEmpty
                  ? appUser.displayName
                  : appUser.email));

      _formData = {
        'uploaded_by': uploaderName, // usar la clave esperada por el modelo
        'fecha_intervencion': DateTime.now().toIso8601String(),
        'entorno_intervencion': 'Comunitario',
        'tipo_doc': 'Cédula de Ciudadanía',
        'nacionalidad': 'Colombiana',
        'sexo_asignado_nacimiento': 'Masculino',
        'grupo_etnico': 'Ninguno',
        'poblacion_condicion_situacion': 'Ninguna',
        'poblacion_migrante': 'No aplica',
        'tiene_seres_sintientes': 'No',
        'actividad_fisica': 'No',
        'frecuencia_frutas_verduras': 'NO todos los días',
        'medicacion_hipertension': 'No',
        'glucosa_alta_historico': 'No',
        'antecedentes_familiares_diabetes': 'No',
        'es_diabetico': 'No',
        'tipo_diabetes': 'N/A',
        'fuma': 'No',
        'enfermedad_cardiovascular_renal_colesterol': 'No',
      };
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _recalculateAllScores(),
    );
  }

  void _recalculateAllScores() {
    setState(() {
      final fechaNac = _parseDateFromDmy(_formData['fecha_nacimiento']);
      _edadCalculada = (fechaNac != null)
          ? _calculationService.calculateAge(fechaNac)
          : null;

      final peso = double.tryParse(
        _formData['peso']?.toString().replaceAll(',', '.') ?? '',
      );
      final talla = double.tryParse(
        _formData['talla']?.toString().replaceAll(',', '.') ?? '',
      );
      if (peso != null && talla != null && talla > 0) {
        _imcCalculado = _calculationService.calculateIMC(peso, talla);
        _clasificacionImc = _calculationService.classifyIMC(_imcCalculado!);
      } else {
        _imcCalculado = null;
        _clasificacionImc = null;
      }

      final findriscResult = _calculationService.calculateAndClassifyFINDRISC(
        age: _edadCalculada,
        imc: _imcCalculado,
        waistCircumference: double.tryParse(
          _formData['circunferencia_abdominal']?.toString().replaceAll(
                ',',
                '.',
              ) ??
              '',
        ),
        gender: _formData['sexo_asignado_nacimiento'],
        physicalActivity: _formData['actividad_fisica'],
        eatsFruitsAndVegs: _formData['frecuencia_frutas_verduras'],
        htaMedication: _formData['medicacion_hipertension'],
        highGlucoseHistory: _formData['glucosa_alta_historico'],
        familyDiabetesHistory: _formData['antecedentes_familiares_diabetes'],
      );
      _puntajeFindrisc = findriscResult['puntaje'];
      _riesgoFindrisc = findriscResult['clasificacion'];

      final omsResult = _calculationService.calculateAndClassifyWHORisk(
        age: _edadCalculada,
        gender: _formData['sexo_asignado_nacimiento'],
        systolicPressure: int.tryParse(
          _formData['presion_sistolica']?.toString() ?? '',
        ),
        smokes: _formData['fuma'],
        isDiabetic: _formData['es_diabetico'],
        hasPreviousCVD: _formData['enfermedad_cardiovascular_renal_colesterol'],
      );
      _riesgoOmsPorcentaje = omsResult['riesgoPorcentaje'];
      _clasificacionOms = omsResult['clasificacionRiesgo'];
    });
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, revise los campos con error.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _formKey.currentState!.save();

    // Convertir fechas de dd/MM/yyyy a ISO String antes de guardar
    _formData['fecha_intervencion'] = _parseDateFromDmy(
      _formData['fecha_intervencion'],
    )?.toIso8601String();
    _formData['fecha_nacimiento'] = _parseDateFromDmy(
      _formData['fecha_nacimiento'],
    )?.toIso8601String();

    _formData['edad'] = _edadCalculada;
    _formData['imc'] = _imcCalculado;
    _formData['clasificacion_imc'] = _clasificacionImc;
    _formData['puntaje_findrisc_calculado'] = _puntajeFindrisc;
    _formData['riesgo_findrisc'] = _riesgoFindrisc;
    _formData['riesgo_cardiovascular_oms_porcentaje'] = _riesgoOmsPorcentaje;
    _formData['clasificacion_riesgo_cardiovascular_oms'] = _clasificacionOms;

    // Asegurar que el campo 'uploaded_by' esté presente al guardar
    final appUser = context.read<AuthProvider>().user;
    final String uploaderName = appUser == null
        ? 'App User'
        : (appUser.userName.isNotEmpty
            ? appUser.userName
            : (appUser.displayName.isNotEmpty
                ? appUser.displayName
                : appUser.email));
    if ((_formData['uploaded_by'] as String?)?.trim().isEmpty ?? true) {
      _formData['uploaded_by'] = uploaderName;
    }

    final tamizaje = Tamizaje.fromMap(_formData);
    widget.onSave(tamizaje);
  }

  DateTime? _parseDateFromDmy(String? dmyDate) {
    if (dmyDate == null || dmyDate.length != 10) return null;
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(dmyDate);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16.0),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: AppBar(
          title: Text(
            widget.initialData == null ? 'Nuevo Tamizaje' : 'Editar Tamizaje',
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          automaticallyImplyLeading: false,
          actions: [
            if (widget.onCancel != null)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
                tooltip: 'Cancelar',
              ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 900;
            return isMobile ? _buildMobileLayout() : _buildDesktopLayout();
          },
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildFormFields()),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _buildResultsSection(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _buildFormFields(isMobile: true);
  }

  Widget _buildFormFields({bool isMobile = false}) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGpsIndicator(),
            _buildSectionTitle('1. Información General'),
            _buildDateField(
              label: 'Fecha Intervención',
              mapKey: 'fecha_intervencion',
            ),
            _buildTextField(
              label: 'Lugar Intervención',
              mapKey: 'lugar_intervencion',
              isRequired: false,
            ),
            _buildTextField(
              label: 'Hora Inicial',
              mapKey: 'hora_inicial_intervencion',
              isRequired: false,
            ),
            _buildTextField(
              label: 'Hora Final',
              mapKey: 'hora_final_intervencion',
              isRequired: false,
            ),
            _buildDropdownField(
              label: 'Entorno Intervención',
              mapKey: 'entorno_intervencion',
              options: _opcionesEntorno,
            ),

            _buildSectionTitle('2. Datos del Participante'),
            _buildTextField(label: 'Nombres', mapKey: 'nombres'),
            _buildTextField(label: 'Apellidos', mapKey: 'apellidos'),
            _buildDropdownField(
              label: 'Tipo de Documento',
              mapKey: 'tipo_doc',
              options: _tiposDocumento,
            ),
            _buildTextField(
              label: 'Número de Documento',
              mapKey: 'numero_documento',
              keyboardType: TextInputType.number,
              isReadOnly: widget.initialData != null,
            ),
            _buildTextField(label: 'Nacionalidad', mapKey: 'nacionalidad'),
            _buildDateField(
              label: 'Fecha de Nacimiento',
              mapKey: 'fecha_nacimiento',
            ),
            _buildDropdownField(
              label: 'Sexo Asignado al Nacer',
              mapKey: 'sexo_asignado_nacimiento',
              options: _opcionesSexo,
            ),
            _buildDropdownField(
              label: 'Género con el que se identifica',
              mapKey: 'genero_identificado',
              options: _opcionesGeneroIdentificado,
              isRequired: false,
            ),
            _buildDropdownField(
              label: 'Orientación Sexual',
              mapKey: 'orientacion_sexual',
              options: _opcionesOrientacionSexual,
              isRequired: false,
            ),
            _buildDropdownField(
              label: 'Grupo Étnico',
              mapKey: 'grupo_etnico',
              options: _opcionesGrupoEtnico,
              isRequired: false,
            ),
            if (_formData['grupo_etnico'] == 'Otro')
              _buildTextField(
                controller: _otroGrupoEtnicoController,
                label: 'Especifique Otro Grupo Étnico',
                mapKey: 'otro_grupo_etnico',
                isRequired: false,
              ),
            _buildDropdownField(
              label: 'Población con Condición',
              mapKey: 'poblacion_condicion_situacion',
              options: _opcionesPoblacionCondicion,
              isRequired: false,
            ),
            _buildDropdownField(
              label: 'Población Migrante',
              mapKey: 'poblacion_migrante',
              options: _opcionesPoblacionMigrante,
              isRequired: false,
            ),
            _buildDropdownField(
              label: 'Tiene seres sintientes',
              mapKey: 'tiene_seres_sintientes',
              options: _opcionesSiNo,
              isRequired: false,
            ),
            _buildTextField(
              label: 'Correo Electrónico',
              mapKey: 'correo_electronico',
              keyboardType: TextInputType.emailAddress,
              isRequired: false,
            ),
            _buildTextField(
              label: 'Teléfono',
              mapKey: 'telefono_contacto',
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              label: 'Dirección',
              mapKey: 'direccion_residencia',
              isRequired: false,
            ),

            _buildSectionTitle('3. Ubicación y Afiliación'),
            _buildDropdownField(
              label: 'Comuna',
              mapKey: 'comuna',
              options: _opcionesComuna,
            ),
            _buildTextField(
              label: 'Barrio/Vereda',
              mapKey: 'barrio_corregimiento_vereda',
              isRequired: false,
            ),
            _buildTextField(label: 'EPS', mapKey: 'eps'),
            _buildDropdownField(
              label: 'Tipo Aseguramiento',
              mapKey: 'tipo_aseguramiento',
              options: _opcionesTipoAseguramiento,
              isRequired: false,
            ),

            _buildSectionTitle('4. Medidas Antropométricas'),
            _buildTextField(
              label: 'Talla (metros)',
              mapKey: 'talla',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d{0,2}')),
              ],
            ),
            _buildTextField(
              label: 'Peso (Kg)',
              mapKey: 'peso',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d{0,1}')),
              ],
            ),
            _buildTextField(
              label: 'Presión Sistólica (mmHg)',
              mapKey: 'presion_sistolica',
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              label: 'Presión Diastólica (mmHg)',
              mapKey: 'presion_diastolica',
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              label: 'Circunferencia Abdominal (cm)',
              mapKey: 'circunferencia_abdominal',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              isRequired: false,
            ),

            if (isMobile) _buildResultsSection(),

            _buildSectionTitle('5. Factores de Riesgo y Hábitos'),
            _buildDropdownField(
              label: 'Actividad Física >30min/día?',
              mapKey: 'actividad_fisica',
              options: _opcionesSiNo,
            ),
            _buildDropdownField(
              label: 'Consume Frutas/Verduras Diariamente?',
              mapKey: 'frecuencia_frutas_verduras',
              options: _opcionesFrecuenciaFrutasVerduras,
            ),
            _buildDropdownField(
              label: 'Toma Medicamentos para HTA?',
              mapKey: 'medicacion_hipertension',
              options: _opcionesSiNo,
            ),
            _buildDropdownField(
              label: 'Historial de Glucosa Alta?',
              mapKey: 'glucosa_alta_historico',
              options: _opcionesSiNo,
            ),
            _buildDropdownField(
              label: 'Antecedentes Familiares de Diabetes?',
              mapKey: 'antecedentes_familiares_diabetes',
              options: _opcionesAntecedentesDiabetes,
            ),
            _buildDropdownField(
              label: '¿Ha sido diagnosticado con Diabetes?',
              mapKey: 'es_diabetico',
              options: _opcionesSiNo,
            ),
            if (_formData['es_diabetico'] == 'Si')
              _buildDropdownField(
                label: 'Tipo de Diabetes',
                mapKey: 'tipo_diabetes',
                options: _opcionesTipoDiabetes,
                isRequired: false,
              ),
            _buildDropdownField(
              label: '¿Fuma actualmente?',
              mapKey: 'fuma',
              options: _opcionesSiNo,
            ),
            _buildDropdownField(
              label: '¿Tiene ECV, ERC o Hipercolesterolemia?',
              mapKey: 'enfermedad_cardiovascular_renal_colesterol',
              options: _opcionesSiNo,
              isRequired: false,
            ),

            _buildSectionTitle('6. Observaciones'),
            _buildTextField(
              label: 'Observaciones',
              mapKey: 'observaciones',
              isRequired: false,
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _latitud != null && _longitud != null
                  ? 'Ubicación capturada'
                  : 'Capturando ubicación...',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Text(
                    widget.initialData == null
                        ? 'Guardar Tamizaje'
                        : 'Actualizar Tamizaje',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String mapKey,
    TextInputType keyboardType = TextInputType.text,
    bool isReadOnly = false,
    bool isRequired = true,
    int? maxLines = 1,
    TextEditingController? controller,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? _formData[mapKey]?.toString() : null,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label + (isRequired ? '*' : ''),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        keyboardType: keyboardType,
        readOnly: isReadOnly,
        maxLines: maxLines,
        validator: (value) => (isRequired && (value == null || value.isEmpty))
            ? 'Campo requerido'
            : null,
        onSaved: (value) {
          if (controller == null) _formData[mapKey] = value;
        },
        onChanged: (value) {
          if (controller == null) _formData[mapKey] = value;
          _recalculateAllScores();
        },
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String mapKey,
    required List<String> options,
    bool isRequired = true,
  }) {
    String? currentValue = _formData[mapKey];
    if (currentValue != null && !options.contains(currentValue)) {
      currentValue = null;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label + (isRequired ? '*' : ''),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        items: options
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            _formData[mapKey] = value;
            _recalculateAllScores();
          });
        },
        onSaved: (value) => _formData[mapKey] = value,
        validator: (value) =>
            (isRequired && value == null) ? 'Seleccione una opción' : null,
      ),
    );
  }

  Widget _buildDateField({required String label, required String mapKey}) {
    String initialValue = '';
    if (_formData[mapKey] != null && (_formData[mapKey] as String).isNotEmpty) {
      final date =
          _parseDateFromDmy(_formData[mapKey]) ??
          DateTime.tryParse(_formData[mapKey]);
      if (date != null) {
        initialValue = DateFormat('dd/MM/yyyy').format(date);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: '$label*',
          hintText: 'dd/MM/yyyy',
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
          DateInputFormatter(),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) return 'Campo requerido';
          if (value.length != 10) return 'Formato debe ser dd/MM/yyyy';
          try {
            DateFormat('dd/MM/yyyy').parseStrict(value);
            return null;
          } catch (e) {
            return 'Fecha inválida';
          }
        },
        onChanged: (value) {
          _formData[mapKey] = value;
          _recalculateAllScores();
        },
        onSaved: (value) {
          _formData[mapKey] = value;
        },
      ),
    );
  }

  Widget _buildResultsSection() {
    Color getColorForRisk(String? classification) {
      if (classification == null) return Colors.grey.shade600;
      final text = classification.toLowerCase();
      if (text.contains('obesidad') || text.contains('alto')) {
        return Colors.red.shade700;
      }
      if (text.contains('sobrepeso') ||
          text.contains('moderado') ||
          text.contains('ligeramente')) {
        return Colors.orange.shade700;
      }
      if (text.contains('normal') || text.contains('bajo')) {
        return Colors.green.shade700;
      }
      return Colors.black87;
    }

    Widget resultRow(String label, String? value, {Color? valueColor}) {
      if (value == null || value.isEmpty || value.contains('null')) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Theme.of(context).primaryColor, width: 5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resultados Calculados',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24, thickness: 1),
            resultRow(
              'Edad',
              _edadCalculada == null ? null : '$_edadCalculada años',
            ),
            resultRow(
              'IMC',
              _imcCalculado == null
                  ? null
                  : '${_imcCalculado?.toStringAsFixed(1)} - ${_clasificacionImc ?? ""}',
              valueColor: getColorForRisk(_clasificacionImc),
            ),
            resultRow(
              'Riesgo FINDRISC',
              _puntajeFindrisc == null
                  ? null
                  : '$_puntajeFindrisc Puntos - ${_riesgoFindrisc ?? ""}',
              valueColor: getColorForRisk(_riesgoFindrisc),
            ),
            resultRow(
              'Riesgo Cardiovascular',
              _clasificacionOms == null
                  ? null
                  : '${_riesgoOmsPorcentaje ?? ""} (${_clasificacionOms ?? ""})',
              valueColor: getColorForRisk(_clasificacionOms),
            ),
          ],
        ),
      ),
    );
  }
}
