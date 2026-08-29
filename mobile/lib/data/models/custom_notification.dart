// To parse this JSON data, do
//
//     final customNotification = customNotificationFromJson(jsonString);

import 'dart:convert';

CustomNotification customNotificationFromJson(String str) =>
    CustomNotification.fromJson(json.decode(str));

class CustomNotification {
  int? id;
  String? type;
  String? title;
  String? message;
  AdditionalData? additionalData;
  bool? seen;
  DateTime? createdAt;
  DateTime? updatedAt;

  CustomNotification({
    this.id,
    this.type,
    this.title,
    this.message,
    this.additionalData,
    this.seen,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomNotification.fromJson(Map<String, dynamic> json) =>
      CustomNotification(
        id: json["id"],
        type: json["type"],
        title: json["title"],
        message: json["message"],
        additionalData: json["additional_data"] == null
            ? null
            : AdditionalData.fromJson(json["additional_data"]),
        seen: json["seen"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );
}

class AdditionalData {
  String? category;
  int? bookingId;
  int? postId;
  String? expertName;
  String? followerId;
  String? followerName;
  String? likerId;
  String? likerName;
  String? userName;
  String? startTime;
  DateTime? bookingDate;
  String? amount;
  String? balance;
  String? currency;
  String? description;
  int? transactionId;
  int? withdrawalId;
  int? broadcastId;
  int? broadcasterId;

  AdditionalData({
    this.category,
    this.bookingId,
    this.postId,
    this.expertName,
    this.userName,
    this.startTime,
    this.bookingDate,
    this.followerId,
    this.followerName,
    this.likerId,
    this.likerName,
    this.amount,
    this.balance,
    this.currency,
    this.description,
    this.transactionId,
    this.withdrawalId,
    this.broadcasterId,
    this.broadcastId,
  });

  factory AdditionalData.fromJson(Map<String, dynamic> json) => AdditionalData(
      category: json["category"],
      bookingId: json["booking_id"],
      postId: json['post_id'],
      expertName: json["expert_name"],
      followerId: json["follower_id"],
      followerName: json["follower_name"],
      likerId: json["liker_id"],
      likerName: json["liker_name"],
      userName: json["user_name"],
      startTime: json["start_time"],
      bookingDate: json["booking_date"] == null
          ? null
          : DateTime.parse(json["booking_date"]),
      amount: json["amount"],
      balance: json["balance"],
      currency: json["currency"],
      description: json["description"],
      transactionId: json["transaction_id"],
      withdrawalId: json['withdrawal_id'],
      broadcasterId: json['creator_id'],
      broadcastId: json['broadcast_id']);
}
