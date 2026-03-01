class UserCreate {
  String email;
  String password;

  UserCreate.required({required this.email, required this.password});
}