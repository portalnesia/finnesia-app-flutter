/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

// ignore_for_file: invalid_annotation_target (freezed reads json_serializable's options from the factory constructor, which is the pattern its docs prescribe)

import 'package:freezed_annotation/freezed_annotation.dart';

part 'master_data.freezed.dart';
part 'master_data.g.dart';

/// Whose record a contact is.
///
/// Ported from `ContactType` in `finnesia-monorepo/packages/types/src/master-data.ts`. The
/// till only ever creates and lists [customer]; the other two exist because the endpoint
/// returns them and the enum must be able to name what it reads.
@JsonEnum(valueField: 'wire')
enum ContactType {
  customer('CUSTOMER'),
  supplier('SUPPLIER'),
  sales('SALES');

  const ContactType(this.wire);

  /// The exact string the API sends and expects.
  final String wire;
}

/// A customer, as the till's picker reads it.
///
/// Ported from `Contact` in `master-data.ts`, partially (`project.md` §2.2): the fields the
/// picker labels a row with. The record also carries credit limit, tax number, three
/// addresses and the receivable/payable accounts, none of which a cashier sees. Every
/// nullable field is `string | null` in the source, and the API sends an explicit `null`.
@freezed
abstract class Contact with _$Contact {
  const factory Contact({
    required String id,
    required String name,

    /// A type this build does not know reads as `null`, like `ProductType`.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    ContactType? type,
    @JsonKey(name: 'company_name') String? companyName,
    String? email,
    String? phone,
  }) = _Contact;

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);
}

/// What `POST /master/contacts` takes when the till adds a customer on the spot.
///
/// The source (`quick-add-contact-dialog.tsx`) sends `type: 'CUSTOMER'` and `is_active: true`
/// with the name and whichever of phone, email, company and address the cashier filled in.
/// [type] is a parameter rather than a constant so this class is not a second, thinner
/// definition of "a customer only": the till passes [ContactType.customer].
@freezed
abstract class CreateContactDTO with _$CreateContactDTO {
  @JsonSerializable(includeIfNull: false)
  const factory CreateContactDTO({
    required String name,
    required ContactType type,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    String? phone,
    String? email,
    @JsonKey(name: 'company_name') String? companyName,
    String? address,
  }) = _CreateContactDTO;

  factory CreateContactDTO.fromJson(Map<String, dynamic> json) =>
      _$CreateContactDTOFromJson(json);
}

/// One account in the chart of accounts, as the cash-movement dialog's picker labels it.
///
/// Ported from `ChartOfAccount` in `master-data.ts`, partially: the picker shows
/// `code - name` and returns the id. Type, normal balance, balances and the tree relations
/// are the ledger's, not the till's.
@freezed
abstract class ChartOfAccount with _$ChartOfAccount {
  const factory ChartOfAccount({
    required String id,
    required String code,
    required String name,
  }) = _ChartOfAccount;

  factory ChartOfAccount.fromJson(Map<String, dynamic> json) =>
      _$ChartOfAccountFromJson(json);
}
