import 'lib/src/models/user_model.dart';

void main() {
  final user = User(
    id: '1',
    email: 'test@test.com',
    role: 'student',
    firstName: 'Test',
    lastName: 'User',
  );
  
  print('User name: ${user.name}');
  print('User first name: ${user.firstName}');
  print('User email: ${user.email}');
}
