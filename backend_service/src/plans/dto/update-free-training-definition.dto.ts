import { PartialType } from '@nestjs/swagger'; // Or mapped-types if swagger not installed, but package.json showed nestjs/swagger
import { CreateFreeTrainingDefinitionDto } from './create-free-training-definition.dto';

export class UpdateFreeTrainingDefinitionDto extends PartialType(CreateFreeTrainingDefinitionDto) { }
