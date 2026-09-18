// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NamedRef _$NamedRefFromJson(Map<String, dynamic> json) =>
    _NamedRef(id: json['id'] as String, name: json['name'] as String?);

Map<String, dynamic> _$NamedRefToJson(_NamedRef instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

_POSSalePayment _$POSSalePaymentFromJson(Map<String, dynamic> json) =>
    _POSSalePayment(
      id: json['id'] as String,
      method: json['method'] as String,
      amount: json['amount'] as num,
      reference: json['reference'] as String?,
    );

Map<String, dynamic> _$POSSalePaymentToJson(_POSSalePayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'method': instance.method,
      'amount': instance.amount,
      'reference': instance.reference,
    };

_SalesInvoiceItem _$SalesInvoiceItemFromJson(Map<String, dynamic> json) =>
    _SalesInvoiceItem(
      id: json['id'] as String,
      quantity: json['quantity'] as num,
      price: json['price'] as num,
      lineSubtotal: json['line_subtotal'] as num,
      lineTotal: json['line_total'] as num,
      description: json['description'] as String?,
      product: json['product'] == null
          ? null
          : NamedRef.fromJson(json['product'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SalesInvoiceItemToJson(_SalesInvoiceItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quantity': instance.quantity,
      'price': instance.price,
      'line_subtotal': instance.lineSubtotal,
      'line_total': instance.lineTotal,
      'description': instance.description,
      'product': instance.product?.toJson(),
    };

_SalesInvoice _$SalesInvoiceFromJson(Map<String, dynamic> json) =>
    _SalesInvoice(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => SalesInvoiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SalesInvoiceItem>[],
    );

Map<String, dynamic> _$SalesInvoiceToJson(_SalesInvoice instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

_POSSale _$POSSaleFromJson(Map<String, dynamic> json) => _POSSale(
  id: json['id'] as String,
  number: json['number'] as String,
  shiftId: json['shift_id'] as String,
  outletId: json['outlet_id'] as String,
  cashierId: json['cashier_id'] as String,
  transactionDate: json['transaction_date'] as String,
  subtotal: json['subtotal'] as num,
  discountAmount: json['discount_amount'] as num,
  taxAmount: json['tax_amount'] as num,
  grandTotal: json['grand_total'] as num,
  tenderedAmount: json['tendered_amount'] as num,
  changeAmount: json['change_amount'] as num,
  status: $enumDecodeNullable(
    _$POSSaleStatusEnumMap,
    json['status'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  createdAt: json['created_at'] as String,
  clientRef: json['client_ref'] as String?,
  paidAt: json['paid_at'] as String?,
  notes: json['notes'] as String?,
  tableNumber: json['table_number'] as String?,
  queueNumber: json['queue_number'] as String?,
  payments: (json['payments'] as List<dynamic>?)
      ?.map((e) => POSSalePayment.fromJson(e as Map<String, dynamic>))
      .toList(),
  invoice: json['invoice'] == null
      ? null
      : SalesInvoice.fromJson(json['invoice'] as Map<String, dynamic>),
  cashier: json['cashier'] == null
      ? null
      : NamedRef.fromJson(json['cashier'] as Map<String, dynamic>),
);

Map<String, dynamic> _$POSSaleToJson(_POSSale instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'shift_id': instance.shiftId,
  'outlet_id': instance.outletId,
  'cashier_id': instance.cashierId,
  'transaction_date': instance.transactionDate,
  'subtotal': instance.subtotal,
  'discount_amount': instance.discountAmount,
  'tax_amount': instance.taxAmount,
  'grand_total': instance.grandTotal,
  'tendered_amount': instance.tenderedAmount,
  'change_amount': instance.changeAmount,
  'status': _$POSSaleStatusEnumMap[instance.status],
  'created_at': instance.createdAt,
  'client_ref': instance.clientRef,
  'paid_at': instance.paidAt,
  'notes': instance.notes,
  'table_number': instance.tableNumber,
  'queue_number': instance.queueNumber,
  'payments': instance.payments,
  'invoice': instance.invoice,
  'cashier': instance.cashier,
};

const _$POSSaleStatusEnumMap = {
  POSSaleStatus.posted: 'POSTED',
  POSSaleStatus.voided: 'VOID',
};

_POSCheckoutItemDTO _$POSCheckoutItemDTOFromJson(Map<String, dynamic> json) =>
    _POSCheckoutItemDTO(
      productId: json['product_id'] as String,
      unitId: json['unit_id'] as String,
      quantity: json['quantity'] as num,
      price: json['price'] as num,
      discountPercent: json['discount_percent'] as num?,
      discountAmount: json['discount_amount'] as num?,
    );

Map<String, dynamic> _$POSCheckoutItemDTOToJson(_POSCheckoutItemDTO instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'unit_id': instance.unitId,
      'quantity': instance.quantity,
      'price': instance.price,
      'discount_percent': ?instance.discountPercent,
      'discount_amount': ?instance.discountAmount,
    };

_POSCheckoutDTO _$POSCheckoutDTOFromJson(Map<String, dynamic> json) =>
    _POSCheckoutDTO(
      outletId: json['outlet_id'] as String,
      transactionDate: json['transaction_date'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => POSCheckoutItemDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List<dynamic>)
          .map((e) => POSTenderDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      shiftId: json['shift_id'] as String?,
      customerId: json['customer_id'] as String?,
      discountAmount: json['discount_amount'] as num?,
      notes: json['notes'] as String?,
      tableNumber: json['table_number'] as String?,
      queueNumber: json['queue_number'] as String?,
      clientRef: json['client_ref'] as String?,
      paidAt: json['paid_at'] as String?,
    );

Map<String, dynamic> _$POSCheckoutDTOToJson(_POSCheckoutDTO instance) =>
    <String, dynamic>{
      'outlet_id': instance.outletId,
      'transaction_date': instance.transactionDate,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'payments': instance.payments.map((e) => e.toJson()).toList(),
      'shift_id': ?instance.shiftId,
      'customer_id': ?instance.customerId,
      'discount_amount': ?instance.discountAmount,
      'notes': ?instance.notes,
      'table_number': ?instance.tableNumber,
      'queue_number': ?instance.queueNumber,
      'client_ref': ?instance.clientRef,
      'paid_at': ?instance.paidAt,
    };

_POSPreferences _$POSPreferencesFromJson(Map<String, dynamic> json) =>
    _POSPreferences(
      requireShift: json['require_shift'] as bool,
      showTableNumber: json['show_table_number'] as bool? ?? false,
      showQueueNumber: json['show_queue_number'] as bool? ?? false,
      queueNumberAuto: json['queue_number_auto'] as bool? ?? false,
      showProductSalesSummary:
          json['show_product_sales_summary'] as bool? ?? false,
      cashAccountId: json['cash_account_id'] as String?,
      defaultCustomerId: json['default_customer_id'] as String?,
      receiptFooterText: json['receipt_footer_text'] as String?,
    );

Map<String, dynamic> _$POSPreferencesToJson(_POSPreferences instance) =>
    <String, dynamic>{
      'require_shift': instance.requireShift,
      'show_table_number': instance.showTableNumber,
      'show_queue_number': instance.showQueueNumber,
      'queue_number_auto': instance.queueNumberAuto,
      'show_product_sales_summary': instance.showProductSalesSummary,
      'cash_account_id': instance.cashAccountId,
      'default_customer_id': instance.defaultCustomerId,
      'receipt_footer_text': instance.receiptFooterText,
    };

_POSTenderDTO _$POSTenderDTOFromJson(Map<String, dynamic> json) =>
    _POSTenderDTO(
      method: $enumDecode(_$POSTenderMethodEnumMap, json['method']),
      amount: json['amount'] as num,
      accountId: json['account_id'] as String?,
      reference: json['reference'] as String?,
    );

Map<String, dynamic> _$POSTenderDTOToJson(_POSTenderDTO instance) =>
    <String, dynamic>{
      'method': _$POSTenderMethodEnumMap[instance.method]!,
      'amount': instance.amount,
      'account_id': ?instance.accountId,
      'reference': ?instance.reference,
    };

const _$POSTenderMethodEnumMap = {
  POSTenderMethod.cash: 'CASH',
  POSTenderMethod.transfer: 'TRANSFER',
  POSTenderMethod.edc: 'EDC',
  POSTenderMethod.qris: 'QRIS',
  POSTenderMethod.komplimen: 'KOMPLIMEN',
};
