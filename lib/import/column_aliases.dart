// Hardcoded column alias mappings for Excel column matching.
//
// Each list maps a payment field to its possible Excel column header names.
// The user can update these lists to match their specific Excel file formats.
// Matching is case-insensitive and whitespace-trimmed.

/// Aliases for account number column (REQUIRED)
const List<String> accountAliases = [
  'رقم الحساب',
  'حساب',
  'رقم المشترك',
  'account',
  'account_number',
  'رقم الاشتراك',
];

/// Aliases for amount column (REQUIRED)
const List<String> amountAliases = [
  'المبلغ',
  'مبلغ',
  'amount',
  'قيمة',
  'المبلغ المسدد',
];

/// Aliases for date column (REQUIRED)
const List<String> dateAliases = [
  'التاريخ',
  'تاريخ',
  'date',
  'تاريخ التسديد',
  'payment_date',
];

/// Aliases for subscriber name column (OPTIONAL)
const List<String> subscriberNameAliases = [
  'اسم المشترك',
  'الاسم',
  'المشترك',
  'subscriber',
  'name',
  'اسم',
];

/// Aliases for stamp number column (OPTIONAL)
const List<String> stampAliases = [
  'رقم الختم',
  'ختم',
  'stamp',
  'stamp_number',
  'الطابع',
  'رقم الطابع',
];

/// Aliases for type column (OPTIONAL)
const List<String> typeAliases = [
  'النوع',
  'نوع',
  'type',
];

/// Aliases for address column (OPTIONAL)
const List<String> addressAliases = [
  'العنوان',
  'عنوان',
  'address',
];
