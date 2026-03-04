// Hardcoded column alias mappings for Excel column matching.
//
// Each list maps a payment field to its possible Excel column header names.
// The user can update these lists to match their specific Excel file formats.
// Matching is case-insensitive and whitespace-trimmed.

/// Aliases for account number column (REQUIRED)
const List<String> accountAliases = ['acctno', 'o_accountno'];

/// Aliases for amount column (REQUIRED)
const List<String> amountAliases = ['amnt', 'o_amount'];

/// Aliases for date column (REQUIRED)
const List<String> dateAliases = ['dater', 'o_date'];

/// Aliases for subscriber name column (OPTIONAL)
const List<String> subscriberNameAliases = ['subscriber_name'];

/// Aliases for stamp number column (OPTIONAL)
const List<String> stampAliases = ['stamp_number', 'o_txtusern'];

/// Aliases for type column (OPTIONAL)
const List<String> typeAliases = ['type'];

/// Aliases for address column (OPTIONAL)
const List<String> addressAliases = ['address'];
