// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_shift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NonCashTenderLine _$NonCashTenderLineFromJson(Map<String, dynamic> json) =>
    _NonCashTenderLine(
      method: json['method'] as String,
      reference: json['reference'] as String?,
      amount: json['amount'] as num,
      saleNumber: json['sale_number'] as String,
    );

Map<String, dynamic> _$NonCashTenderLineToJson(_NonCashTenderLine instance) =>
    <String, dynamic>{
      'method': instance.method,
      'reference': instance.reference,
      'amount': instance.amount,
      'sale_number': instance.saleNumber,
    };

_ProductSalesLine _$ProductSalesLineFromJson(Map<String, dynamic> json) =>
    _ProductSalesLine(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as num,
      unitPrice: json['unit_price'] as num,
      total: json['total'] as num,
    );

Map<String, dynamic> _$ProductSalesLineToJson(_ProductSalesLine instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'product_name': instance.productName,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'total': instance.total,
    };

_ShiftSummaryResponse _$ShiftSummaryResponseFromJson(
  Map<String, dynamic> json,
) => _ShiftSummaryResponse(
  shiftId: json['shift_id'] as String,
  number: json['number'] as String,
  status: $enumDecodeNullable(
    _$ShiftStatusEnumMap,
    json['status'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  outletId: json['outlet_id'] as String,
  cashierId: json['cashier_id'] as String,
  cashierName: json['cashier_name'] as String?,
  outletName: json['outlet_name'] as String?,
  openedAt: json['opened_at'] as String,
  closedAt: json['closed_at'] as String?,
  notes: json['notes'] as String?,
  totalTransactions: (json['total_transactions'] as num).toInt(),
  totalSales: json['total_sales'] as num,
  openingCash: json['opening_cash'] as num,
  expectedCash: json['expected_cash'] as num,
  countedCash: json['counted_cash'] as num?,
  cashVariance: json['cash_variance'] as num?,
  cashIn: json['cash_in'] as num,
  cashOut: json['cash_out'] as num,
  cashDrop: json['cash_drop'] as num,
  salesByMethod:
      (json['sales_by_method'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as num),
      ) ??
      const <String, num>{},
  nonCashTenders:
      (json['non_cash_tenders'] as List<dynamic>?)
          ?.map((e) => NonCashTenderLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <NonCashTenderLine>[],
  productSales:
      (json['product_sales'] as List<dynamic>?)
          ?.map((e) => ProductSalesLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ProductSalesLine>[],
);

Map<String, dynamic> _$ShiftSummaryResponseToJson(
  _ShiftSummaryResponse instance,
) => <String, dynamic>{
  'shift_id': instance.shiftId,
  'number': instance.number,
  'status': _$ShiftStatusEnumMap[instance.status],
  'outlet_id': instance.outletId,
  'cashier_id': instance.cashierId,
  'cashier_name': instance.cashierName,
  'outlet_name': instance.outletName,
  'opened_at': instance.openedAt,
  'closed_at': instance.closedAt,
  'notes': instance.notes,
  'total_transactions': instance.totalTransactions,
  'total_sales': instance.totalSales,
  'opening_cash': instance.openingCash,
  'expected_cash': instance.expectedCash,
  'counted_cash': instance.countedCash,
  'cash_variance': instance.cashVariance,
  'cash_in': instance.cashIn,
  'cash_out': instance.cashOut,
  'cash_drop': instance.cashDrop,
  'sales_by_method': instance.salesByMethod,
  'non_cash_tenders': instance.nonCashTenders,
  'product_sales': instance.productSales,
};

const _$ShiftStatusEnumMap = {
  ShiftStatus.open: 'OPEN',
  ShiftStatus.closed: 'CLOSED',
};

_POSCashMovement _$POSCashMovementFromJson(Map<String, dynamic> json) =>
    _POSCashMovement(
      id: json['id'] as String,
      shiftId: json['shift_id'] as String,
      type: $enumDecode(_$CashMovementTypeEnumMap, json['type']),
      amount: json['amount'] as num,
      reason: json['reason'] as String,
      createdAt: json['created_at'] as String,
      creator: json['creator'] == null
          ? null
          : NamedRef.fromJson(json['creator'] as Map<String, dynamic>),
      product: json['product'] == null
          ? null
          : NamedRef.fromJson(json['product'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$POSCashMovementToJson(_POSCashMovement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shift_id': instance.shiftId,
      'type': _$CashMovementTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'reason': instance.reason,
      'created_at': instance.createdAt,
      'creator': instance.creator,
      'product': instance.product,
    };

const _$CashMovementTypeEnumMap = {
  CashMovementType.cashIn: 'CASH_IN',
  CashMovementType.cashOut: 'CASH_OUT',
  CashMovementType.drop: 'DROP',
};

_CashMovementDTO _$CashMovementDTOFromJson(Map<String, dynamic> json) =>
    _CashMovementDTO(
      type: $enumDecode(_$CashMovementTypeEnumMap, json['type']),
      amount: json['amount'] as num,
      reason: json['reason'] as String,
      accountId: json['account_id'] as String?,
      productId: json['product_id'] as String?,
    );

Map<String, dynamic> _$CashMovementDTOToJson(_CashMovementDTO instance) =>
    <String, dynamic>{
      'type': _$CashMovementTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'reason': instance.reason,
      'account_id': ?instance.accountId,
      'product_id': ?instance.productId,
    };

_OpenShiftDTO _$OpenShiftDTOFromJson(Map<String, dynamic> json) =>
    _OpenShiftDTO(
      outletId: json['outlet_id'] as String,
      openingCash: json['opening_cash'] as num,
      warehouseId: json['warehouse_id'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$OpenShiftDTOToJson(_OpenShiftDTO instance) =>
    <String, dynamic>{
      'outlet_id': instance.outletId,
      'opening_cash': instance.openingCash,
      'warehouse_id': ?instance.warehouseId,
      'notes': ?instance.notes,
    };

_CloseShiftDTO _$CloseShiftDTOFromJson(Map<String, dynamic> json) =>
    _CloseShiftDTO(
      countedCash: json['counted_cash'] as num,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$CloseShiftDTOToJson(_CloseShiftDTO instance) =>
    <String, dynamic>{
      'counted_cash': instance.countedCash,
      'notes': ?instance.notes,
    };

_POSShift _$POSShiftFromJson(Map<String, dynamic> json) => _POSShift(
  id: json['id'] as String,
  number: json['number'] as String,
  cashierId: json['cashier_id'] as String,
  outletId: json['outlet_id'] as String,
  openedAt: json['opened_at'] as String,
  openingCash: json['opening_cash'] as num,
  totalSales: json['total_sales'] as num,
  totalTransactions: (json['total_transactions'] as num).toInt(),
  status: $enumDecodeNullable(
    _$ShiftStatusEnumMap,
    json['status'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  closedAt: json['closed_at'] as String?,
  cashier: json['cashier'] == null
      ? null
      : NamedRef.fromJson(json['cashier'] as Map<String, dynamic>),
);

Map<String, dynamic> _$POSShiftToJson(_POSShift instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'cashier_id': instance.cashierId,
  'outlet_id': instance.outletId,
  'opened_at': instance.openedAt,
  'opening_cash': instance.openingCash,
  'total_sales': instance.totalSales,
  'total_transactions': instance.totalTransactions,
  'status': _$ShiftStatusEnumMap[instance.status],
  'closed_at': instance.closedAt,
  'cashier': instance.cashier,
};
