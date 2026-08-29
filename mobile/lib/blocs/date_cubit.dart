import 'package:flutter_bloc/flutter_bloc.dart';

class DateTimeCubit extends Cubit<DateTime?> {
  DateTimeCubit() : super(null);

  void select(DateTime? value) {
    emit(value);
  }
}

