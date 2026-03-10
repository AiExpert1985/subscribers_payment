/// Default column alias values used to seed the database on first run and on reset.
///
/// Structure: section → field → list of default alias strings.
/// - 'payment' section covers payment import (Excel / CSV).
/// - 'account' section covers account import (Excel / CSV).
const Map<String, Map<String, List<String>>> kDefaultAliases = {
  'payment': {
    'account_number': ['رقم الحساب'],
    'amount': ['المبلغ'],
    'date': ['التاريخ'],
    'subscriber_name': ['اسم المشترك'],
    'stamp_number': ['رقم الختم'],
    'type': ['النوع'],
    'address': ['العنوان'],
  },
  'account': {
    'account': ['الحساب'],
    'subscriber_name': ['اسم المشترك'],
  },
};

/// Payment import fields that must always have at least one alias.
const Set<String> kPaymentRequiredFields = {'account_number', 'amount', 'date'};

/// Account import fields that must always have at least one alias.
const Set<String> kAccountRequiredFields = {'account'};
