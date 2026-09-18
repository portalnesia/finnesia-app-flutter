/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import '../../category.dart';
import '../../master_data.dart';
import '../endpoint.dart';
import '../http_method.dart';
import '../parsers.dart';

/// `finnesia-monorepo/packages/shared/src/api/all-endpoints/master.ts`
abstract final class MasterApi {
  static final categoriesList = ReadEndpoint<List<Category>>(
    '/api/v1/master/categories',
    parseList(Category.fromJson),
  );

  static final coaList = ReadEndpoint<List<ChartOfAccount>>(
    '/api/v1/master/coa',
    parseList(ChartOfAccount.fromJson),
  );

  static final contactsList = ReadEndpoint<List<Contact>>(
    '/api/v1/master/contacts',
    parseList(Contact.fromJson),
  );

  static final contactsCreate = WriteEndpoint<CreateContactDTO, Contact>(
    HttpMethod.post,
    '/api/v1/master/contacts',
    parseObject(Contact.fromJson),
    (dto) => dto.toJson(),
  );

  static final contactsGet = ReadEndpointP<ById, Contact>(
    (p) => '/api/v1/master/contacts/${Uri.encodeComponent(p.id)}',
    parseObject(Contact.fromJson),
  );
}
