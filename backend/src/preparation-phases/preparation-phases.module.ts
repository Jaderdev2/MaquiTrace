import { Module } from '@nestjs/common';
import { PreparationPhasesService } from './preparation-phases.service';
import { PreparationPhasesController } from './preparation-phases.controller';

@Module({
  controllers: [PreparationPhasesController],
  providers: [PreparationPhasesService],
  exports: [PreparationPhasesService],
})
export class PreparationPhasesModule {}
