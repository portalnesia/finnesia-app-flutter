// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_pending_sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingSaleReceipt _$PendingSaleReceiptFromJson(Map<String, dynamic> json) =>
    _PendingSaleReceipt(
      outletName: json['outletName'] as String?,
      cashierName: json['cashierName'] as String?,
      subtotal: json['subtotal'] as num,
      discountAmount: json['discountAmount'] as num,
      taxAmount: json['taxAmount'] as num,
      grandTotal: json['grandTotal'] as num,
      tenderedAmount: json['tenderedAmount'] as num,
      changeAmount: json['changeAmount'] as num,
      items: (json['items'] as List<dynamic>)
          .map((e) => SalesInvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PendingSaleReceiptToJson(_PendingSaleReceipt instance) =>
    <String, dynamic>{
      'outletName': instance.outletName,
      'cashierName': instance.cashierName,
      'subtotal': instance.subtotal,
      'discountAmount': instance.discountAmount,
      'taxAmount': instance.taxAmount,
      'grandTotal': instance.grandTotal,
      'tenderedAmount': instance.tenderedAmount,
      'changeAmount': instance.changeAmount,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

_PendingSale _$PendingSaleFromJson(Map<String, dynamic> json) => _PendingSale(
      clientRef: json['clientRef'] as String,
      companyId: json['companyId'] as String,
      outletId: json['outletId'] as String,
      cashierId: json['cashierId'] as String,
      shiftId: json['shiftId'] as String?,
      status: $enumDecode(_$PendingSaleStatusEnumMap, json['status']),
      error: json['error'] as String?,
      paidAt: json['paidAt'] as String,
      createdAt: json['createdAt'] as String,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      payload: POSCheckoutDTO.fromJson(json['payload'] as Map<String, dynamic>),
      receipt:
          PendingSaleReceipt.fromJson(json['receipt'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PendingSaleToJson(_PendingSale instance) =>
    <String, dynamic>{
      'clientRef': instance.clientRef,
      'companyId': instance.companyId,
      'outletId': instance.outletId,
      'cashierId': instance.cashierId,
      'shiftId': instance.shiftId,
      'status': _$PendingSaleStatusEnumMap[instance.status]!,
      'error': instance.error,
      'paidAt': instance.paidAt,
      'createdAt': instance.createdAt,
      'attempts': instance.attempts,
      'payload': instance.payload.toJson(),
      'receipt': instance.receipt.toJson(),
    };

const _$PendingSaleStatusEnumMap = {
  PendingSaleStatus.pending: 'pending',
  PendingSaleStatus.failed: 'failed',
};
