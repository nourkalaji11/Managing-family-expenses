// import 'dart:developer';
// import 'dart:io';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cash_for_chat/blocs/file_cubit.dart';
// import 'package:cash_for_chat/data/models/custom_file.dart';
// import 'package:cash_for_chat/style/colors.dart';
// import 'package:cash_for_chat/style/spaces.dart';
// import 'package:cash_for_chat/style/text_style.dart';
// import 'package:cash_for_chat/utils/service_locator.dart';
// import 'package:cash_for_chat/utils/system_func.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:image_picker/image_picker.dart';

// class ImagePickerWidget extends StatefulWidget {
//   final String initImage;
//   final bool showRequiredError;
//   final void Function(CustomFile image) onPick;

//   const ImagePickerWidget(
//       {super.key,
//       required this.initImage,
//       required this.onPick,
//       required this.showRequiredError});

//   @override
//   State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
// }

// class _ImagePickerWidgetState extends State<ImagePickerWidget> {
//   late String image;

//   final fileBloc = getIt<FileManagerCubit>();

//   @override
//   void initState() {
//     image = widget.initImage;
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Center(
//           child: GestureDetector(
//               onTap: () async {
//                 try {
//                   SystemFunc.requestPhotoPermission().then((value) async {
//                     if (value) {
//                       XFile? pickedFile = await ImagePicker().pickImage(
//                         source: ImageSource.gallery,
//                         maxWidth: 1800,
//                         maxHeight: 1800,
//                       );
//                       if (pickedFile != null) {
//                         File file = File(pickedFile.path);
//                         final int sizeInBytes = await file.length();

//                         CustomFile? f = await fileBloc.uploadFile(
//                             pickedFile.path, sizeInBytes);
//                         if (f != null) {
//                           widget.onPick(f);
//                           image = f.url ?? "";
//                           setState(() {});
//                           log("${f.id} - $image", name: "File Info");
//                         }
//                       }
//                     }
//                   }).onError(
//                     (error, stackTrace) {
//                       if (error is PlatformException &&
//                           error.code == 'photo_access_denied') {
//                         EasyLoading.showError("photo_access_denied".tr());
//                       } else {
//                         EasyLoading.showError("errorglobal".tr());
//                       }
//                     },
//                   );
//                 } catch (e) {
//                   print(e);
//                   EasyLoading.showError("errorglobal".tr());
//                 }
//               },
//               child: SizedBox(
//                 width: 120.r,
//                 height: 104.r,
//                 child: Stack(
//                   alignment: Alignment.topCenter,
//                   children: [
//                     CachedNetworkImage(
//                         imageUrl: image,
//                         placeholder: (context, url) => Container(
//                               height: 200.r,
//                               width: 200.r,
//                               clipBehavior: Clip.hardEdge,
//                               decoration: const BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: ColorsApp.grey200),
//                               child:
//                                   SvgPicture.asset("assets/images/avatar.svg"),
//                             ),
//                         errorWidget: (context, url, error) {
//                           return Container(
//                             height: 200.r,
//                             width: 200.r,
//                             clipBehavior: Clip.hardEdge,
//                             decoration: const BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: ColorsApp.grey200),
//                             child: SvgPicture.asset("assets/images/avatar.svg"),
//                           );
//                         },
//                         imageBuilder: (context, imageProvider) => Container(
//                               height: 200.r,
//                               width: 200.r,
//                               clipBehavior: Clip.hardEdge,
//                               decoration: BoxDecoration(
//                                   image: DecorationImage(
//                                       fit: BoxFit.cover, image: imageProvider),
//                                   shape: BoxShape.circle,
//                                   color: ColorsApp.grey200),
//                             )),
//                     Positioned(
//                       bottom: 0.h,
//                       right: 10.w,
//                       child: GestureDetector(
//                         child: SvgPicture.asset("assets/icons/edit.svg"),
//                       ),
//                     )
//                   ],
//                 ),
//               )),
//         ),
//         if (widget.initImage.isEmpty &&
//             (image == null || image.isEmpty) &&
//             widget.showRequiredError) ...[
//           Spaces.height20,
//           Center(
//             child: Text(
//               "photo_req_message".tr(),
//               style: TextStyleApp.red12700,
//             ),
//           )
//         ],
//       ],
//     );
//   }
// }
