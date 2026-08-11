// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:easy_localization/easy_localization.dart';

abstract class Failure {
  final String message;

  Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure implements Failure {
  @override
  String get message => "server_error".tr();
}

class ConnectionFailure implements Failure {
  @override
  String get message => "connection_error".tr();
}

class GlobalFailure implements Failure {
  @override
  String get message => "errorglobal".tr();
}

class ResultFailure implements Failure {
  @override
  final String message;

  ResultFailure(this.message);

  @override
  String toString() => message;
}

class NumFailure implements Failure {
  @override
  final String message;
  final int code;

  NumFailure(this.message, this.code);

  @override
  String toString() => message;
}
