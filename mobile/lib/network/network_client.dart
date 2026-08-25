// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/network/failure.dart';
import 'package:family_expense_management/network/global_api_endpoint.dart';
import 'package:family_expense_management/network/network_connection.dart';

enum RequestType { get, post, delete, put, patch }

class DioClient {
  static final String _baseUrl = GlobalApiEndpoint.base.endpoint;

  /// Request bodies are printed to the console for debugging. Credentials must
  /// not be, because `adb logcat` is readable by anything with USB debugging
  /// enabled and crash reporters capture console output verbatim.
  static const _sensitiveKeys = {
    'password',
    'password_confirmation',
    'token',
    'secret_token',
    'otp',
  };

  static Object? _redact(Object? body) {
    if (body is! Map) return body;
    return {
      for (final entry in body.entries)
        entry.key: _sensitiveKeys.contains(entry.key) ? '***' : entry.value,
    };
  }

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.plain,
      validateStatus: (statusCode) {
        if (statusCode == null) {
          return false;
        }
        // else if (statusCode == 401) {
        //   EasyLoading.dismiss();
        //   LocalStorage().removeUser();
        //   LocalsApp.user = null;
        //   MyApp.restartApp(DefaultSettings.mainNavigatorKey.currentContext!);
        //   return true;
        // }
        else {
          return true;
        }
      },
    ),
  );

  Future<Response> request({
    required RequestType requestType,
    required String path,
    Map<String, dynamic>? body,
    FormData? formData,
    Map<String, dynamic>? queryParameters,
    int? timeOut,
    String? Hmac,
  }) async {
    final connected = await NetworkConnection.isConnected();
    if (connected) {
      log("$_baseUrl/$path", name: requestType.name);
      debugPrint(queryParameters.toString());
      debugPrint(json.encode(_redact(body)));

      _dio.options.headers['Content-Type'] = 'application/json';
      _dio.options.headers['Accept'] = 'application/json';
      _dio.options.headers['X-Lang'] = LocalsApp.locale?.languageCode;
      _dio.options.headers['X-OS'] = LocalsApp.deviceOS;

      if (LocalsApp.user?.token != null) {
        _dio.options.headers['Authorization'] =
            "Bearer ${LocalsApp.user!.token}";
      } else {
        _dio.options.headers.removeWhere(
          (key, value) => key == "Authorization",
        );
      }

      switch (requestType) {
        case RequestType.get:
          return _dio.get(
            "$_baseUrl/$path",
            queryParameters: queryParameters,
            data: json.encode(body),
          );

        case RequestType.delete:
          return _dio.delete(
            "$_baseUrl/$path",
            queryParameters: queryParameters,
          );

        case RequestType.post:
          if (formData != null) {
            return _dio.post(
              "$_baseUrl/$path",
              data: formData,
              queryParameters: queryParameters,
              options: timeOut != null
                  ? Options(
                      sendTimeout: Duration(seconds: timeOut),
                      receiveTimeout: Duration(seconds: timeOut),
                    )
                  : null,
            );
          } else {
            return _dio.post(
              "$_baseUrl/$path",
              data: json.encode(body),
              queryParameters: queryParameters,
              options: timeOut != null
                  ? Options(
                      sendTimeout: Duration(seconds: timeOut),
                      receiveTimeout: Duration(seconds: timeOut),
                    )
                  : null,
            );
          }

        case RequestType.put:
          if (formData != null) {
            return _dio.put(
              "$_baseUrl/$path",
              data: formData,
              queryParameters: queryParameters,
            );
          } else {
            return _dio.put(
              "$_baseUrl/$path",
              data: json.encode(body),
              queryParameters: queryParameters,
            );
          }
        case RequestType.patch:
          if (formData != null) {
            return _dio.patch(
              "$_baseUrl/$path",
              data: formData,
              queryParameters: queryParameters,
            );
          } else {
            return _dio.patch(
              "$_baseUrl/$path",
              data: json.encode(body),
              queryParameters: queryParameters,
            );
          }
      }
    } else {
      throw ConnectionFailure();
    }
  }
}
