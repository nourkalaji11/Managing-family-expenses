import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:family_expense_management/data/models/user.dart';

class LocalUserCubit extends Cubit<User?> {
  LocalUserCubit() : super(null);

  void updateUser(User? value) {
    emit(value);
  }
}
