// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get selectSexError => 'Selecciona sexo masculino o femenino';

  @override
  String get selectDobError => 'Selecciona tu fecha de nacimiento';

  @override
  String get onboardingTitle => 'Bienvenido a\nProject Wellness';

  @override
  String get onboardingSubtitle =>
      'Configuremos tu perfil. Todo se queda en tu dispositivo: sin cuentas, sin nube.';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get nameRequiredError => 'Ingresa tu nombre';

  @override
  String get dobLabel => 'Fecha de nacimiento';

  @override
  String get selectDate => 'Selecciona una fecha';

  @override
  String get male => 'Masculino';

  @override
  String get female => 'Femenino';

  @override
  String weightLabelWithUnit(String unit) {
    return 'Peso ($unit)';
  }

  @override
  String get invalid => 'No válido';

  @override
  String get heightCmLabel => 'Estatura (cm)';

  @override
  String get heightFtLabel => 'Estatura (ft)';

  @override
  String get inLabel => 'pulg';

  @override
  String get activityLevelLabel => '¿Qué tan activo eres en tu día a día?';

  @override
  String get activityLevelSubtitle =>
      'Opcional: ayuda a estimar tus calorías con más precisión desde el principio, antes de tener historial de entrenamientos.';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String greeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get trackPrompt => '¿Qué te gustaría registrar?';

  @override
  String get training => 'Entrenamiento';

  @override
  String get trainingSubtitle => 'Rutinas y peso';

  @override
  String get nutrition => 'Nutrición';

  @override
  String get nutritionSubtitle => 'Calorías y macros';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Racha de $count días',
      one: 'Racha de 1 día',
    );
    return '$_temp0';
  }

  @override
  String get replaceAllDataTitle => '¿Reemplazar todos los datos?';

  @override
  String get replaceAllDataContent =>
      'Esto reemplaza TODOS los datos actuales (perfil, rutinas, nutrición e historial de peso) con el contenido de este archivo. Esta acción no se puede deshacer.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get replace => 'Reemplazar';

  @override
  String get dataRestored => 'Datos restaurados';

  @override
  String get deleteAllDataTitle => '¿Eliminar todos los datos?';

  @override
  String get deleteAllDataContent =>
      'Esto elimina permanentemente tu perfil, rutinas, registro de nutrición e historial de peso de este dispositivo. No hay forma de deshacerlo a menos que hayas exportado una copia de seguridad antes. Volverás a la configuración inicial.';

  @override
  String get deleteEverything => 'Eliminar todo';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get editProfileSubtitle =>
      'Actualiza tu fecha de nacimiento, estatura y peso';

  @override
  String get reminders => 'Recordatorios';

  @override
  String get remindersSubtitle =>
      'Notificaciones de comidas, peso y entrenamiento';

  @override
  String get cycleTracking => 'Seguimiento del ciclo';

  @override
  String get cycleTrackingSubtitle =>
      'Opcional: sigue tu ciclo para ver información por fase';

  @override
  String get personalExercises => 'Ejercicios personales';

  @override
  String get personalExercisesSubtitle => 'Ejercicios que has creado tú mismo';

  @override
  String get personalFoods => 'Alimentos personales';

  @override
  String get personalFoodsSubtitle => 'Alimentos que has creado tú mismo';

  @override
  String get appearance => 'Apariencia';

  @override
  String get appearanceDescription =>
      'Sigue la configuración de tu sistema o fija el modo claro/oscuro. Elige un tema de color para toda la app.';

  @override
  String get units => 'Unidades';

  @override
  String get unitsDescription =>
      'Elige cómo se muestran el peso y la estatura en toda la app.';

  @override
  String get appleHealth => 'Apple Health';

  @override
  String get healthConnect => 'Health Connect';

  @override
  String healthSyncDescription(String service) {
    return 'Envía el peso y las rutinas que registras aquí a $service, y usa tu conteo de pasos para mejorar la estimación de tu meta de calorías.';
  }

  @override
  String get privacy => 'Privacidad';

  @override
  String get faceIdTouchId => 'Face ID/Touch ID';

  @override
  String get fingerprintOrFace => 'tu huella o rostro';

  @override
  String privacyDescription(String method) {
    return 'Requerir $method para abrir la app.';
  }

  @override
  String get yourData => 'Tus datos';

  @override
  String get yourDataDescription =>
      'Sin nube: nada sale de tu teléfono a menos que tú lo envíes. Respalda todo en un archivo o restáuralo en un dispositivo nuevo.';

  @override
  String get exportMyData => 'Guardar en el dispositivo';

  @override
  String get exportMyDataSubtitle =>
      'Guarda un archivo de respaldo directamente en el almacenamiento de tu teléfono';

  @override
  String get shareBackupFile => 'Compartir archivo de respaldo';

  @override
  String get shareBackupFileSubtitle =>
      'Envíalo por AirDrop, correo u otra app';

  @override
  String get importData => 'Importar datos';

  @override
  String get importDataSubtitle => 'Restaura desde un archivo de respaldo';

  @override
  String get dangerZone => 'Zona de peligro';

  @override
  String get dangerZoneDescription =>
      'Borra permanentemente todo lo almacenado en este dispositivo.';

  @override
  String get deleteAllData => 'Eliminar todos los datos';

  @override
  String get deleteAllDataCardSubtitle =>
      'Perfil, rutinas, nutrición, historial de peso';

  @override
  String get themeClassic => 'Clásico';

  @override
  String get themePink => 'Rosa';

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get unitSystemMetric => 'Métrico';

  @override
  String get unitSystemImperial => 'Imperial';

  @override
  String healthPermissionDenied(String service) {
    return 'No se otorgó el permiso de $service.';
  }

  @override
  String syncWithService(String service) {
    return 'Sincronizar con $service';
  }

  @override
  String get noBiometricsSetUp =>
      'Este dispositivo no tiene huella, rostro ni código de acceso configurado.';

  @override
  String get authenticationFailed => 'Error de autenticación.';

  @override
  String get fingerprintSlashFace => 'huella/rostro';

  @override
  String requireBiometric(String method) {
    return 'Requerir $method';
  }

  @override
  String get notificationsOff =>
      'Las notificaciones están desactivadas para Project Wellness. Actívalas en la configuración de tu dispositivo para usar los recordatorios.';

  @override
  String get localOnlyNotice =>
      'Solo notificaciones locales: nada sale de tu teléfono.';

  @override
  String get breakfast => 'Desayuno';

  @override
  String get breakfastSubtitle => 'Recuérdame registrar el desayuno';

  @override
  String get lunch => 'Almuerzo';

  @override
  String get lunchSubtitle => 'Recuérdame registrar el almuerzo';

  @override
  String get dinner => 'Cena';

  @override
  String get dinnerSubtitle => 'Recuérdame registrar la cena';

  @override
  String get weighIn => 'Pesaje';

  @override
  String get weighInSubtitle => 'Recuérdame registrar mi peso';

  @override
  String get workout => 'Entrenamiento';

  @override
  String get workoutSubtitle =>
      'Se omite automáticamente si ya registraste un entrenamiento ese día';

  @override
  String get backup => 'Respaldo';

  @override
  String get backupSubtitle =>
      'Recordatorio semanal para exportar un respaldo (domingos)';

  @override
  String get appLockedTitle => 'Project Wellness está bloqueado';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get unlocking => 'Desbloqueando…';

  @override
  String get cycleTrackingNotice =>
      'Disponible para cualquier persona que lo quiera usar, sin relación con tu perfil. Todo se queda en este dispositivo.';

  @override
  String get cycleTrackingEnable => 'Activar seguimiento del ciclo';

  @override
  String get cycleTrackingEnableSubtitle =>
      'Registra las fechas de inicio de tu periodo para ver tu fase actual';

  @override
  String get cycleAdjustCaloriesTitle =>
      'Ajustar meta de calorías en la fase lútea';

  @override
  String get cycleAdjustCaloriesSubtitle =>
      'Agrega una estimación fija y pequeña durante la fase lútea; no es una medición precisa';

  @override
  String get cyclePeriodHistory => 'Historial del periodo';

  @override
  String get cycleLogPeriodStart => 'Registrar inicio de periodo';

  @override
  String get cycleNoEntries =>
      'Aún no hay fechas de inicio de periodo registradas';

  @override
  String get cycleCurrentPhase => 'Fase actual';

  @override
  String get cycleNotEnoughData => 'Aún no hay suficientes datos';

  @override
  String get cyclePhaseMenstrual => 'Menstrual';

  @override
  String get cyclePhaseFollicular => 'Folicular';

  @override
  String get cyclePhaseOvulation => 'Ovulación';

  @override
  String get cyclePhaseLuteal => 'Lútea';

  @override
  String get cycleDeleteEntry => 'Eliminar registro';

  @override
  String cycleNextPeriodIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Próximo periodo en $count días',
      one: 'Próximo periodo en 1 día',
      zero: 'Periodo esperado hoy',
    );
    return '$_temp0';
  }

  @override
  String cyclePeriodLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'El periodo lleva $count días de retraso',
      one: 'El periodo lleva 1 día de retraso',
    );
    return '$_temp0';
  }

  @override
  String cycleExpectedOn(String date) {
    return 'Esperado el $date';
  }

  @override
  String get cycleOvulationEstimate => 'Ovulación estimada';

  @override
  String get cycleFertileWindow => 'Ventana fértil';

  @override
  String get cycleLengthLabel => 'Duración del ciclo';

  @override
  String cycleLengthValue(int count) {
    return '$count días';
  }

  @override
  String cycleLengthLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Calculado a partir de tus últimos $count ciclos',
      one: 'Calculado a partir de 1 ciclo',
      zero: 'Valor por defecto hasta que registres dos periodos',
    );
    return '$_temp0';
  }

  @override
  String get cycleEstimateDisclaimer =>
      'Solo son estimaciones basadas en tus fechas registradas. No sirven como método anticonceptivo.';

  @override
  String get cycleDuplicateTitle => '¿El mismo periodo?';

  @override
  String cycleDuplicateContent(String date) {
    return '$date está a pocos días de un inicio de periodo que ya registraste. Las estimaciones lo cuentan como un solo periodo.';
  }

  @override
  String get cycleLogAnyway => 'Registrar igual';

  @override
  String get cycleEntryDeleted => 'Inicio de periodo eliminado';

  @override
  String get undo => 'Deshacer';

  @override
  String get cycleStaleData =>
      'Registra tu inicio de periodo más reciente para ver en qué punto estás';
}
