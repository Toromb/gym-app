import * as crypto from 'crypto';

if (!global.crypto) {
    console.log('Polyfilling global.crypto');
    (global as any).crypto = crypto;
}
