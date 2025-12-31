
import { SessionSynchronizer } from './session-synchronizer';
import { TrainingSession, ExecutionStatus } from '../entities/training-session.entity';
import { PlanDay, PlanExercise } from '../entities/plan.entity';
import { SessionExercise } from '../entities/session-exercise.entity';
import { Exercise } from '../../exercises/entities/exercise.entity';

describe('SessionSynchronizer', () => {
    // Helper to create basic objects
    const createMockExercise = (id: string, name: string): Exercise => ({
        id,
        name,
        videoUrl: 'http://video.com',
        description: '',
        muscles: [],
        exerciseMuscles: [],
        createdAt: new Date(),
        updatedAt: new Date(),
    } as Exercise);

    const createMockPlanExercise = (id: string, exercise: Exercise, order: number): PlanExercise => ({
        id,
        exercise,
        order,
        sets: 3,
        reps: '10',
        suggestedLoad: '20kg',
        equipments: [],
        day: {} as PlanDay,
        videoUrl: null, // Override if needed
    } as PlanExercise);

    const createMockSessionExercise = (id: string, planExId: string | null, order: number): SessionExercise => ({
        id,
        planExerciseId: planExId,
        order,
        targetSetsSnapshot: 3,
        targetRepsSnapshot: '10',
        targetWeightSnapshot: '20kg',
        exerciseNameSnapshot: 'Test Ex',
        exercise: {} as Exercise,
        session: {} as TrainingSession,
        sets: [],
        isCompleted: false,
        equipmentsSnapshot: [],
        videoUrl: null,
        createdAt: new Date(),
        updatedAt: new Date(),
    } as SessionExercise);

    it('should identify new exercises to create', () => {
        // Arrange
        const ex1 = createMockExercise('ex1', 'Pushups');
        const day = {
            exercises: [createMockPlanExercise('pex1', ex1, 1)]
        } as PlanDay;

        const session = {
            exercises: [],
            status: ExecutionStatus.IN_PROGRESS
        } as TrainingSession;

        // Act
        const result = SessionSynchronizer.calculateDiff(session, day);

        // Assert
        expect(result.toCreate).toHaveLength(1);
        expect(result.toCreate[0].planExerciseId).toBe('pex1');
        expect(result.toCreate[0].exerciseNameSnapshot).toBe('Pushups');
        expect(result.hasChanges).toBe(true);
    });

    it('should identify exercises to delete (orphans)', () => {
        // Arrange
        // Session has an exercise linked to a plan exercise that is NO LONGER in the day
        const sessionEx = createMockSessionExercise('sex1', 'pex_old', 1);
        const session = {
            exercises: [sessionEx],
            status: ExecutionStatus.IN_PROGRESS
        } as TrainingSession;

        const day = {
            exercises: [] // Empty plan day
        } as PlanDay;

        // Act
        const result = SessionSynchronizer.calculateDiff(session, day);

        // Assert
        expect(result.toDelete).toHaveLength(1);
        expect(result.toDelete[0].id).toBe('sex1');
        expect(result.toCreate).toHaveLength(0);
        expect(result.hasChanges).toBe(true);
    });

    it('should identify updates for changed parameters', () => {
        // Arrange
        const ex1 = createMockExercise('ex1', 'Pushups');

        // Plan has updated reps
        const planEx = createMockPlanExercise('pex1', ex1, 1);
        planEx.reps = '15'; // Changed from default 10

        // Session has old Reps
        const sessionEx = createMockSessionExercise('sex1', 'pex1', 1);
        sessionEx.targetRepsSnapshot = '10';

        const session = {
            exercises: [sessionEx],
            status: ExecutionStatus.IN_PROGRESS
        } as TrainingSession;

        const day = {
            exercises: [planEx]
        } as PlanDay;

        // Act
        const result = SessionSynchronizer.calculateDiff(session, day);

        // Assert
        expect(result.toUpdate).toHaveLength(1);
        expect(result.toUpdate[0].targetRepsSnapshot).toBe('15'); // Should be updated in the object reference
        expect(result.hasChanges).toBe(true);
    });

    it('should preserve manual extra exercises', () => {
        // Arrange
        // Session has an exercise with NO planExerciseId (Manual)
        const manualEx = createMockSessionExercise('sex_manual', null, 2);

        const session = {
            exercises: [manualEx],
            status: ExecutionStatus.IN_PROGRESS
        } as TrainingSession;

        const day = {
            exercises: []
        } as PlanDay;

        // Act
        const result = SessionSynchronizer.calculateDiff(session, day);

        // Assert
        expect(result.toDelete).toHaveLength(0); // Should NOT delete manual
        expect(result.toCreate).toHaveLength(0);
        expect(result.hasChanges).toBe(false);
    });

    it('should NOT update snapshots if session is COMPLETED', () => {
        // Arrange
        const ex1 = createMockExercise('ex1', 'Pushups');
        const planEx = createMockPlanExercise('pex1', ex1, 1);
        planEx.sets = 5; // Plan changed

        const sessionEx = createMockSessionExercise('sex1', 'pex1', 1);
        sessionEx.targetSetsSnapshot = 3; // Old value

        const session = {
            exercises: [sessionEx],
            status: ExecutionStatus.COMPLETED // IMPORTANT
        } as TrainingSession;

        const day = {
            exercises: [planEx]
        } as PlanDay;

        // Act
        const result = SessionSynchronizer.calculateDiff(session, day);

        // Assert
        expect(result.toUpdate).toHaveLength(0); // Should ignored updates
        expect(sessionEx.targetSetsSnapshot).toBe(3); // Should remain unchanged
    });

    it('should update videoUrl', () => {
        // Arrange
        const ex1 = createMockExercise('ex1', 'Pushups');
        const planEx = createMockPlanExercise('pex1', ex1, 1);
        planEx.videoUrl = 'http://new-video.com';

        const sessionEx = createMockSessionExercise('sex1', 'pex1', 1);
        sessionEx.videoUrl = null;

        const session = {
            exercises: [sessionEx],
            status: ExecutionStatus.IN_PROGRESS
        } as TrainingSession;

        const day = {
            exercises: [planEx]
        } as PlanDay;

        // Act
        const result = SessionSynchronizer.calculateDiff(session, day);

        // Assert
        expect(result.toUpdate).toHaveLength(1);
        expect(result.toUpdate[0].videoUrl).toBe('http://new-video.com');
    });

    it('should update targetTime and targetDistance', () => {
        // Arrange
        const ex1 = createMockExercise('ex1', 'Plank');

        // Plan has time and distance
        const planEx = createMockPlanExercise('pex1', ex1, 1);
        planEx.targetTime = 60; // 60 seconds
        planEx.targetDistance = 1000; // 1km

        // Session has old/null values
        const sessionEx = createMockSessionExercise('sex1', 'pex1', 1);
        sessionEx.targetTimeSnapshot = null;
        sessionEx.targetDistanceSnapshot = null;

        const session = {
            exercises: [sessionEx],
            status: ExecutionStatus.IN_PROGRESS
        } as TrainingSession;

        const day = {
            exercises: [planEx]
        } as PlanDay;

        // Act
        const result = SessionSynchronizer.calculateDiff(session, day);

        // Assert
        expect(result.toUpdate).toHaveLength(1);
        expect(result.toUpdate[0].targetTimeSnapshot).toBe(60);
        expect(result.toUpdate[0].targetDistanceSnapshot).toBe(1000);
        expect(result.hasChanges).toBe(true);
    });
});
