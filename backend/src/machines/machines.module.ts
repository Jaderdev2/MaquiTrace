import { Module } from '@nestjs/common';
import { MachinesService } from './machines.service';
import { MachinesController } from './machines.controller';
import { EvidenceModule } from '../evidence/evidence.module';

@Module({
  imports: [EvidenceModule],
  controllers: [MachinesController],
  providers: [MachinesService],
  exports: [MachinesService],
})
export class MachinesModule {}
