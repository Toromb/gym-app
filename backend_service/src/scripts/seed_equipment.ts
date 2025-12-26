import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';
import { Equipment } from '../exercises/entities/equipment.entity';

async function bootstrap() {
    const app = await NestFactory.createApplicationContext(AppModule);
    const dataSource = app.get(DataSource);
    const equipmentRepo = dataSource.getRepository(Equipment);

    const initialEquipments = [
        'Peso corporal',
        'Mancuerna',
        'Barra',
        'Discos',
        'Kettlebell',
        'Máquina',
        'Polea',
        'Smith',
        'Banco',
        'Rack / Jaula',
        'Banda elástica',
        'TRX / Suspensión',
        'Balón medicinal',
        'Colchoneta',
        'Step / Cajón',
    ];

    console.log('Seeding equipments...');

    for (const name of initialEquipments) {
        const exists = await equipmentRepo.findOne({ where: { name } });
        if (!exists) {
            await equipmentRepo.save(equipmentRepo.create({ name }));
            console.log(`Created: ${name}`);
        } else {
            console.log(`Exists: ${name}`);
        }
    }

    console.log('Equipment seeding complete.');
    await app.close();
}

bootstrap();
