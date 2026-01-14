import {
    IsEnum,
    IsNotEmpty,
    IsOptional,
    IsString,
    ValidateNested,
    IsArray,
    IsNumber,
    IsUUID,
} from 'class-validator';
import { Type } from 'class-transformer';
import {
    FreeTrainingType,
    TrainingLevel,
    BodySector,
    CardioLevel,
} from '../entities/free-training-definition.entity';

export class CreateFreeTrainingDefinitionExerciseDto {
    @IsUUID()
    @IsNotEmpty()
    exerciseId: string;

    @IsNumber()
    @IsOptional()
    order?: number;

    @IsNumber()
    @IsOptional()
    sets?: number;

    @IsString()
    @IsOptional()
    reps?: string;

    @IsString()
    @IsOptional()
    suggestedLoad?: string;

    @IsString()
    @IsOptional()
    rest?: string;

    @IsString()
    @IsOptional()
    notes?: string;

    @IsString()
    @IsOptional()
    videoUrl?: string;

    // Optional equipment IDs override? Usually not needed for free definitions unless specific
    @IsArray()
    @IsOptional()
    equipmentIds?: string[];
}

export class CreateFreeTrainingDefinitionDto {
    @IsString()
    @IsNotEmpty()
    name: string;

    @IsEnum(FreeTrainingType)
    @IsNotEmpty()
    type: FreeTrainingType;

    @IsEnum(TrainingLevel)
    @IsNotEmpty()
    level: TrainingLevel;

    @IsEnum(BodySector)
    @IsOptional()
    sector?: BodySector;

    @IsEnum(CardioLevel)
    @IsOptional()
    cardioLevel?: CardioLevel;

    @IsArray()
    @ValidateNested({ each: true })
    @Type(() => CreateFreeTrainingDefinitionExerciseDto)
    exercises: CreateFreeTrainingDefinitionExerciseDto[];
}
