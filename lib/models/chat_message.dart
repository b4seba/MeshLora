import 'package:flutter/material.dart';

enum MessageDeliveryState { created, queued, transmitting, acknowledged, failed, unconfirmed }

class ChatMessage {
  final String id;
  final int senderNodeNum;
  final String name;
  final String initials;
  final String text;
  final DateTime timestamp;
  final bool fromMe;
  final Color avatarColor;
  final bool isUrgent;
  final int? rssiDbm;
  final double? snr;
  final int hops;
  final MessageDeliveryState deliveryState;
  final int? packetId;
  final int attempts;
  final int? destinationNodeNum;

  ChatMessage({
    required this.id,
    this.senderNodeNum = 0,
    required this.name,
    required this.initials,
    required this.text,
    required this.timestamp,
    required this.fromMe,
    required this.avatarColor,
    this.isUrgent = false,
    this.rssiDbm,
    this.snr,
    this.hops = 0,
    this.deliveryState = MessageDeliveryState.acknowledged,
    this.packetId,
    this.attempts = 0,
    this.destinationNodeNum,
  });

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  ChatMessage copyWith({MessageDeliveryState? deliveryState, int? attempts}) {
    return ChatMessage(
      id: id,
      senderNodeNum: senderNodeNum,
      name: name,
      initials: initials,
      text: text,
      timestamp: timestamp,
      fromMe: fromMe,
      avatarColor: avatarColor,
      isUrgent: isUrgent,
      rssiDbm: rssiDbm,
      snr: snr,
      hops: hops,
      deliveryState: deliveryState ?? this.deliveryState,
      packetId: packetId,
      attempts: attempts ?? this.attempts,
      destinationNodeNum: destinationNodeNum,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderNodeNum': senderNodeNum,
      'name': name,
      'initials': initials,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'fromMe': fromMe,
      'avatarColorValue': avatarColor.toARGB32(),
      'isUrgent': isUrgent,
      'rssiDbm': rssiDbm,
      'snr': snr,
      'hops': hops,
      'deliveryState': deliveryState.name,
      'packetId': packetId,
      'attempts': attempts,
      'destinationNodeNum': destinationNodeNum,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderNodeNum: json['senderNodeNum'] as int? ?? 0,
      name: json['name'] as String,
      initials: json['initials'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      fromMe: json['fromMe'] as bool,
      avatarColor: Color(json['avatarColorValue'] as int? ?? 0xFF0A1F44),
      isUrgent: json['isUrgent'] as bool? ?? false,
      rssiDbm: json['rssiDbm'] as int?,
      snr: (json['snr'] as num?)?.toDouble(),
      hops: json['hops'] as int? ?? 0,
      deliveryState: MessageDeliveryState.values.firstWhere(
        (state) => state.name == json['deliveryState'],
        orElse: () => MessageDeliveryState.acknowledged,
      ),
      packetId: json['packetId'] as int?,
      attempts: json['attempts'] as int? ?? 0,
      destinationNodeNum: json['destinationNodeNum'] as int?,
    );
  }
}
