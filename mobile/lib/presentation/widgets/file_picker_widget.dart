// import 'dart:developer';

// import 'package:cash_for_chat/blocs/file_cubit.dart';
// import 'package:cash_for_chat/data/models/custom_file.dart';
// import 'package:cash_for_chat/style/colors.dart';
// import 'package:cash_for_chat/style/decorations.dart';
// import 'package:cash_for_chat/style/padding.dart';
// import 'package:cash_for_chat/style/text_style.dart';
// import 'package:cash_for_chat/utils/service_locator.dart';
// import 'package:cash_for_chat/utils/system_func.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';

// class FilePickerWidget extends StatefulWidget {
//   final void Function(CustomFile file) onPick;

//   const FilePickerWidget({super.key, required this.onPick});

//   @override
//   State<FilePickerWidget> createState() => _FilePickerWidgetState();
// }

// class _FilePickerWidgetState extends State<FilePickerWidget> {
//   final fileBloc = getIt<FileManagerCubit>();
//   CustomFile? f;

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: GestureDetector(
//           onTap: () async {
//             try {
//               SystemFunc.requestPhotoPermission().then((value) async {
//                 if (value) {
//                   FilePickerResult? pickedFile =
//                       await FilePicker.platform.pickFiles();

//                   if (pickedFile != null && pickedFile.files.isNotEmpty) {
//                     final int sizeInBytes = pickedFile.files.first.size;

//                     f = await fileBloc.uploadFile(
//                         pickedFile.files.first.path!, sizeInBytes);
//                     if (f != null) {
//                       widget.onPick(f!);
//                       setState(() {});
//                       log("${f!.id} - ${pickedFile.files.first.path}",
//                           name: "File Info");
//                     }
//                   }
//                 }
//               }).onError(
//                 (error, stackTrace) {
//                   if (error is PlatformException &&
//                       error.code == 'photo_access_denied') {
//                     EasyLoading.showError("photo_access_denied".tr());
//                   } else {
//                     EasyLoading.showError("errorglobal".tr());
//                   }
//                 },
//               );
//             } catch (e) {
//               print(e);
//               EasyLoading.showError("errorglobal".tr());
//             }
//           },
//           child: Container(
//             padding: EdgeInsetsApp.symmetricV10H20,
//             decoration: Decorations.white,
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     f == null ? "pick_file".tr() : f?.name ?? "",
//                     style: TextStyleApp.grey14500,
//                   ),
//                 ),
//                 const Icon(
//                   Icons.upload,
//                   color: ColorsApp.grey,
//                 )
//               ],
//             ),
//           )),
//     );
//   }
// }
