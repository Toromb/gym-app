import { DataSource } from 'typeorm';

/**
 * Limpia todas las tablas de la BD de test en el orden correcto,
 * respetando las restricciones de Foreign Key.
 *
 * Se llama en `beforeEach` o `beforeAll` de cada suite para garantizar
 * que cada test comienza con un estado absolutamente limpio y predecible.
 *
 * Filosofía:
 * - TRUNCATE con CASCADE es más rápido que DELETE en tablas grandes.
 * - Deshabilitar FK checks temporalmente permite truncar en cualquier orden.
 * - El orden explícito aquí es una red de seguridad adicional.
 *
 * Regla de negocio relacionada:
 * - Regla 10: Nada de los tests debe filtrarse a datos reales.
 *   El aislamiento entre tests garantiza que un test no contamine al siguiente.
 */
export async function cleanDatabase(dataSource: DataSource): Promise<void> {
  // Deshabilitar FK constraints temporalmente para poder truncar en cualquier orden
  await dataSource.query('SET session_replication_role = replica;');

  try {
    // Orden: tablas más dependientes primero → tablas base al final
    const tablesToClean = [
      // Plans - Sesiones y progreso (más específico)
      'session_exercises',
      'training_sessions',

      // Plans - Asignaciones snapshot (AssignedPlan y su árbol)
      'assigned_plan_exercises',
      'assigned_plan_days',
      'assigned_plan_weeks',
      'student_plans',
      'assigned_plans',
      'completed_plans',

      // Plans - Template (árbol del plan maestro)
      'plan_exercise_equipments',
      'plan_exercises',
      'plan_days',
      'plan_weeks',
      'plans',

      // Free trainings
      'free_training_definition_exercises',
      'free_training_definitions',

      // Payments
      'payment_records',

      // Auth
      'refresh_tokens',

      // Notifications & Schedule
      'notifications',
      'gym_schedule_blocks',

      // Gym leads
      'gym_leads',

      // Users & Onboarding
      'onboarding_profiles',
      'users',

      // Gyms (tabla base)
      'gyms',

      // Catálogo de ejercicios (generado por seed en tests que lo necesitan)
      'exercise_muscles',
      'muscles',
      'plan_exercise_equipments',
      'equipments',
      'exercises',
    ];

    for (const table of tablesToClean) {
      // TRUNCATE con IF EXISTS para no fallar si alguna tabla no se creó aún
      await dataSource
        .query(`TRUNCATE TABLE "${table}" CASCADE`)
        .catch(() => {
          // Si la tabla no existe en este estado, ignorar silenciosamente
        });
    }
  } finally {
    // Re-habilitar FK constraints siempre, incluso si hay error
    await dataSource.query('SET session_replication_role = DEFAULT;');
  }

  console.log('[TestSetup] Base de datos limpiada correctamente.');
}

/**
 * Inserta un gym de base para usar como punto de partida en suites
 * que requieren un contexto de gimnasio (casi todas).
 *
 * Retorna el gym recién insertado con su ID generado.
 */
export async function seedBaseGym(
  dataSource: DataSource,
  overrides: Partial<{
    businessName: string;
    address: string;
  }> = {},
): Promise<{ id: string; businessName: string }> {
  const businessName = overrides.businessName ?? 'Gym Test Central';
  const address = overrides.address ?? 'Av. Test 123';

  const result = await dataSource.query(
    `INSERT INTO gyms ("businessName", address, status, "subscriptionPlan", "maxProfiles")
     VALUES ($1, $2, 'active', 'basic', 50)
     RETURNING id, "businessName"`,
    [businessName, address],
  );

  return result[0];
}

/**
 * Inserta un set mínimo de músculos globales en la BD de test.
 *
 * Los músculos son datos maestros que en producción vienen de una migración seed.
 * En la BD de test, cleanDatabase los elimina junto con todo, por lo que algunas
 * suites (ej. exercises) necesitan re-sembrarlos antes de correr sus tests.
 *
 * Retorna el ID del primer músculo insertado para uso inmediato en tests.
 */
export async function seedMuscles(
  dataSource: DataSource,
): Promise<{ id: string; name: string }[]> {
  const muscleData = [
    { name: 'Bíceps',          region: 'UPPER', bodySide: 'FRONT' },
    { name: 'Tríceps',         region: 'UPPER', bodySide: 'BACK'  },
    { name: 'Pecho',           region: 'UPPER', bodySide: 'FRONT' },
    { name: 'Espalda',         region: 'UPPER', bodySide: 'BACK'  },
    { name: 'Hombros',         region: 'UPPER', bodySide: 'FRONT' },
    { name: 'Cuádriceps',      region: 'LOWER', bodySide: 'FRONT' },
    { name: 'Isquiotibiales',  region: 'LOWER', bodySide: 'BACK'  },
    { name: 'Abdominales',     region: 'CORE',  bodySide: 'FRONT' },
  ];

  const muscles: { id: string; name: string }[] = [];

  for (const m of muscleData) {
    const result = await dataSource.query(
      `INSERT INTO muscles (name, region, "bodySide")
       VALUES ($1, $2, $3)
       ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
       RETURNING id, name`,
      [m.name, m.region, m.bodySide],
    );
    muscles.push(result[0]);
  }

  return muscles;
}
