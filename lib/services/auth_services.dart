class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2)); // simulate API call
    if (email == 'test@gmail.com' && password == '123456') {
      return {
        'status': 'success',
        'user': {'email': email},
        'access': 'dummyAccessToken',
        'refresh': 'dummyRefreshToken',
      };
    } else {
      return {'status': 'error', 'message': 'Invalid credentials'};
    }
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    return {'status': 'success', 'user': {'email': email}};
  }
}
