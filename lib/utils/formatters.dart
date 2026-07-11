// Inside lib/utils/formatters.dart

// 1. Define your global currency configuration toggle
String globalCurrencySymbol = "NPR"; // Change to "Rs.", "\$", "€", etc.

// 2. Update your formatting function to look at the global setting
String formatCurrency(int amount) {
  // If your country places symbols AFTER the amount (like Nepal often does: 500 NPR)
  if (globalCurrencySymbol == "NPR") {
    return "$amount NPR";
  }

  // Standard prefix formatting for symbols like $, ₹, £ (e.g., $500)
  return "$globalCurrencySymbol$amount";
}