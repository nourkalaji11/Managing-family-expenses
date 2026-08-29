import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/data/local_storage.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(LocalsApp.locale!);

  void changeLang(context, Locale lo) {
    LocalsApp.locale = lo;
    emit(lo);
    LocalStorage().saveLanguage(lo);
  }
}
