import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'es': {
      // --- Auth & Common ---
      'appTitle': 'GymFlow',
      'loginTitle': 'Iniciar Sesión',
      'emailLabel': 'Correo electrónico',
      'passwordLabel': 'Contraseña',
      'loginButton': 'Ingresar',
      'registerButton': 'Registrarse',
      'logoutButton': 'Cerrar Sesión',
      'logoutConfirmTitle': '¿Cerrar Sesión?',
      'logoutConfirmContent': '¿Estás seguro que deseas salir?',
      'cancel': 'Cancelar',
      'confirm': 'Confirmar',
      'save': 'Guardar',
      'error': 'Error',
      'success': 'Éxito',
      'loading': 'Cargando...',

      // --- Navigation / Tabs ---
      'navHome': 'Inicio',
      'navPlans': 'Planes',
      'navProfile': 'Perfil',
      'navUsers': 'Usuarios',

      // --- Home Screen ---
      'welcome': 'Bienvenido',
      'welcomeBack': 'Bienvenido de nuevo,',
      'dashboardTitle': 'Panel de Alumno',
      'workoutHistory': 'Historial',
      'workoutHistorySub': 'Calendario y Progreso',
      'myPlansSub': 'Ver planes activos y pasados',
      'profileSub': 'Actualizar metas y peso',
      'gymSchedule': 'Horarios',
      'gymScheduleSub': 'Ver horarios de apertura',
      'userRole_admin': 'Administrador',
      'userRole_profe': 'Profesor',
      'userRole_alumno': 'Alumno',

      // --- Profile ---
      'profileTitle': 'Mi Perfil',
      'personalInfo': 'Información Personal',
      'age': 'Edad',
      'gender': 'Género',
      'genderM': 'Masculino',
      'genderF': 'Femenino',
      'genderO': 'Otro',

      // --- Plans ---
      'myPlan': 'Mi Plan',
      'noPlan': 'No tienes plan asignado',
      'noPlans': 'No tienes planes asignados aún.',
      'statusActive': 'ACTIVO',
      'objective': 'Objetivo:',
      'assignedOn': 'Asignado el:',
      'week': 'Semana',
      'day': 'Día',
      'exercises': 'Ejercicios',
      'exercisesCount': 'Ejercicios', // Context: "3 Ejercicios"
      'weeklySchedule': 'Cronograma Semanal',
      'planOverview': 'Resumen del Plan',
      'durationWeeks': 'Duración: {weeks} Semanas', // Needs manual format or just "Duración:"
      'selectDate': 'Seleccionar Fecha de Finalización',
      'errorUpdateProgress': 'Error al actualizar progreso',
      'exercisesToComplete': 'Ejercicios por completar',
      'confirmCompletion': 'Confirmar Fecha de Finalización',
      'workoutFinished': '¡Entrenamiento Finalizado!',
      'errorFinish': 'Error al finalizar entrenamiento',
      'errorDateConflict': '¡Ya existe un entrenamiento completado en esta fecha!',
      'errorLoadExecution': 'No se pudo cargar el entrenamiento.',
      'retry': 'Reintentar',
      'errorUpdate': 'Error al actualizar',
      'errorVideo': 'No se pudo abrir el enlace del video',
      'sets': 'Series',
      'reps': 'Reps',
      'load': 'Carga',
      'completedOn': 'Completado:',
      'startWorkout': 'Empezar Entrenamiento',
      'finishWorkout': 'Finalizar Entrenamiento',
      'trainingSession': 'Sesión de Entrenamiento',
      'workoutCompleted': 'Entrenamiento Completado',
      'noWorkoutsOn': 'No hay entrenamientos el',
      'selectDay': 'Selecciona un día',
      'mon': 'Lun',
      'tue': 'Mar',
      'wed': 'Mié',
      'thu': 'Jue',
      'fri': 'Vie',
      'sat': 'Sáb',
      'sun': 'Dom',
      'closed': 'Cerrado',
      'openAM': 'Abre AM',
      'closeAM': 'Cierra AM',
      'openPM': 'Abre PM',
      'closePM': 'Cierra PM',
      'notes': 'Notas',
      'scheduleUpdated': '¡Horario actualizado!',
      'save': 'Guardar',
      'trainingSession': 'Sesión de Entrenamiento',
      'completed': 'Completado',
      'inProgress': 'En Progreso',
      'day_monday': 'Lunes',
      'day_tuesday': 'Martes',
      'day_wednesday': 'Miércoles',
      'day_thursday': 'Jueves',
      'day_friday': 'Viernes',
      'day_saturday': 'Sábado',
      'day_sunday': 'Domingo',

      // --- Exercises ---
      'sets': 'Series',
      'reps': 'Reps',
      'load': 'Carga',
      'watchVideo': 'Ver Video',
      'notes': 'Notas',
      
      // --- Admin / Management ---
      'manageUsers': 'Gestionar Usuarios',
      'managePlans': 'Gestionar Planes',
      'createPlan': 'Crear Plan',
      'createUser': 'Crear Usuario',
      'assignPlan': 'Asignar Plan',
      'delete': 'Eliminar',
      'dashboardTitleProfe': 'Panel de Profesor',
      'manageStudents': 'Gestionar Alumnos',
      'plansLibrary': 'Biblioteca de Planes',
      'noPlansFound': 'No se encontraron planes.',
      'withoutAuthor': 'Sin Autor',
      'created': 'Creado:',
      'viewDetails': 'Ver Detalles',
      'deletePlanTitle': 'Eliminar Plan',
      'deletePlanConfirm': '¿Estás seguro que deseas eliminar este plan? Esta acción no se puede deshacer.',
      'deletePlanSuccess': 'Plan eliminado',
      'deletePlanError': 'Error al eliminar plan. Solo puedes eliminar tus propios planes.',
      
      // --- Placeholders / Errors ---
      'fieldRequired': 'Campo requerido',
      'invalidEmail': 'Email inválido',
      'invalidCredentials': 'Email o contraseña incorrecta',
    },
    'en': {
      // English Fallback
      'appTitle': 'GymFlow',
      'loginTitle': 'Login',
      // ... (Can populate later if needed, primarily focused on ES)
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
  
  // Getters for Type Safety (Partial List for critical items)
  String get loginTitle => get('loginTitle');
  String get emailLabel => get('emailLabel');
  String get passwordLabel => get('passwordLabel');
  String get loginButton => get('loginButton');
  String get welcome => get('welcome');
  String get error => get('error');
  String get invalidEmail => get('invalidEmail');
  String get invalidCredentials => get('invalidCredentials');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['es', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
