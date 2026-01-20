import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { UserRole } from '../../users/entities/user.entity';

@Injectable()
export class RolesGuard implements CanActivate {
    constructor(private reflector: Reflector) { }

    canActivate(context: ExecutionContext): boolean {
        const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
            context.getHandler(),
            context.getClass(),
        ]);

        // If no roles are required, allow access
        if (!requiredRoles) {
            return true;
        }

        const { user } = context.switchToHttp().getRequest();
        // Assuming user is populated by AuthGuard('jwt') before this runs
        if (!user) {
            return false;
        }

        if (user.role === UserRole.SUPER_ADMIN) {
            return true; // Super Admin bypasses role checks (but tenancy checks still apply in logic)
        }

        return requiredRoles.some((role) => user.role === role);
    }
}
