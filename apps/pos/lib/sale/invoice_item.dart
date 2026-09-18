/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_pos/src/pos_receipt.dart';
import 'package:pn_types/src/pos.dart';

/// A line of a recorded sale, as the receipt logic in `pn_pos` reads it. Shared by the sale
/// detail sheet and the printed receipt, so the two cannot disagree about what a sale sold.
InvoiceItem toInvoiceItem(SalesInvoiceItem item) => (
  id: item.id,
  productName: item.product?.name,
  description: item.description,
  quantity: item.quantity,
  price: item.price,
  lineSubtotal: item.lineSubtotal,
  lineTotal: item.lineTotal,
  // The customer receipt ignores the category; only the kitchen ticket reads it, and that is not
  // built (README D3).
  category: null,
);
