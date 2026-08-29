import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/data/models/account.dart';
import 'package:family_expense_management/data/models/category.dart';
import 'package:family_expense_management/data/models/transaction.dart';

/// SEED DATA ONLY — the starting state of the fake dataset.
///
/// ---------------------------------------------------------------------------
/// The backend is real now — `origin/souad-backend` has the routes, the auth
/// middleware and the scoping — so this is no longer a stand-in for something
/// missing. It is the app's offline dataset, and `kUseMockData` switches
/// between the two.
///
/// This file is **immutable seed data, not the runtime collection**. Exactly one
/// consumer reads it: `MockStore`, which copies it once at construction and owns
/// every mutation from then on. Repositories must go through `MockStore` and
/// must never call [transactions] again — doing so would rebuild the original
/// list and silently discard everything added or edited during the session.
///
///     DashboardMockSource  ->  MockStore  ->  DashboardRepo / TransactionsRepo
///
/// To run against the real API: build with `--dart-define=USE_MOCK=false` and
/// an `API_BASE_URL`. Nothing here has to be deleted for that, and nothing here
/// is imported by a widget, a bloc or a model.
///
/// The one exception is `maskedAccountNumber`, which `HomeScreen` reads
/// directly so that the fabricated value disappears the moment the repo stops
/// being mocked.
/// ---------------------------------------------------------------------------
///
/// The amounts reproduce the design exactly
/// (`docs/stitch_family_finance_tracker/dashboard_screen_minimal_redesign`):
///
///   total balance  9,450.00 + 3,000.00                        = 12,450.00
///   income         1,200.00 + 7,300.00                        =  8,500.00
///   expenses       245.50 + 32 + 468 + 800 + 800 + 175
///                  + 250 + 400 + 79.50                        =  3,250.00
///   remaining      8,500.00 - 3,250.00                        =  5,250.00
///
///   المطاعم  32 + 468 + 800   = 1,300.00  → 40%
///   السكن    800 + 175        =   975.00  → 30%
///   النقل    250 + 400        =   650.00  → 20%
///   التسوق   245.50 + 79.50   =   325.00  → 10%  (folded into "أخرى")
///
/// Every amount below is an explicit literal so these sums stay verifiable by
/// reading the file.
class DashboardMockSource {
  const DashboardMockSource._();

  /// Category rows. `categories` only has (id, name) — no colour, no icon.
  static const Category _restaurants = Category(id: 1, name: 'المطاعم');
  static const Category _housing = Category(id: 2, name: 'السكن');
  static const Category _transport = Category(id: 3, name: 'النقل');
  static const Category _shopping = Category(id: 4, name: 'التسوق');
  static const Category _salary = Category(id: 5, name: 'الراتب');

  static const List<Category> categories = [
    _restaurants,
    _housing,
    _transport,
    _shopping,
    _salary,
  ];

  /// Σ balance = 12,450.00, matching the design's total.
  static const List<Account> accounts = [
    Account(id: 1, name: 'الحساب الجاري', balance: 9450.00, userId: 1),
    Account(id: 2, name: 'التوفير', balance: 3000.00, userId: 1),
  ];

  /// Placeholder for the masked family account number in the balance card.
  ///
  /// TODO(backend): entirely invented — `accounts` has no account-number column
  /// and there is no `families` table, so nothing in the schema can produce
  /// this. Needs both a new column (e.g. `accounts.number`) and a decision on
  /// how a family's shared account is identified. Must not be mistaken for real
  /// data.
  static const String maskedAccountNumber = '**** 4421';

  /// Transactions for the current period, newest first.
  ///
  /// `date` is date-only in the schema, so `createdAt` carries the time that the
  /// "اليوم، 10:30 ص" subtitle renders. Dates are relative to now so the
  /// "اليوم / أمس" labels stay correct whenever the app runs — which also makes
  /// the three newest rows exactly the three the design shows, in its order.
  static List<TransactionModel> transactions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return [
      // ---- Visible in "آخر المعاملات" (the three rows in the design) --------
      TransactionModel(
        id: 1,
        amount: 245.50,
        type: TransactionType.expense,
        description: 'بنده للتجزئة',
        date: today,
        createdAt: today.add(const Duration(hours: 10, minutes: 30)),
        userId: 1,
        accountId: 1,
        categoryId: 4,
        category: _shopping,
      ),
      TransactionModel(
        id: 2,
        amount: 32.00,
        type: TransactionType.expense,
        description: 'ستاربكس',
        date: yesterday,
        createdAt: yesterday.add(const Duration(hours: 16, minutes: 15)),
        userId: 1,
        accountId: 1,
        categoryId: 1,
        category: _restaurants,
      ),
      TransactionModel(
        id: 3,
        amount: 1200.00,
        type: TransactionType.income,
        description: 'تحويل من أحمد',
        date: yesterday,
        createdAt: yesterday.add(const Duration(hours: 9)),
        userId: 1,
        accountId: 1,
        categoryId: 5,
        category: _salary,
      ),

      // ---- Older rows: feed the totals and the donut, not the visible list --
      TransactionModel(
        id: 4,
        amount: 468.00,
        type: TransactionType.expense,
        description: 'مطعم عائلي',
        date: today.subtract(const Duration(days: 3)),
        createdAt: today.subtract(const Duration(days: 3)),
        userId: 1,
        accountId: 1,
        categoryId: 1,
        category: _restaurants,
      ),
      TransactionModel(
        id: 5,
        amount: 800.00,
        type: TransactionType.expense,
        description: 'طلبات توصيل',
        date: today.subtract(const Duration(days: 5)),
        createdAt: today.subtract(const Duration(days: 5)),
        userId: 1,
        accountId: 1,
        categoryId: 1,
        category: _restaurants,
      ),
      TransactionModel(
        id: 6,
        amount: 800.00,
        type: TransactionType.expense,
        description: 'إيجار الشقة',
        date: today.subtract(const Duration(days: 6)),
        createdAt: today.subtract(const Duration(days: 6)),
        userId: 1,
        accountId: 1,
        categoryId: 2,
        category: _housing,
      ),
      TransactionModel(
        id: 7,
        amount: 175.00,
        type: TransactionType.expense,
        description: 'فاتورة الكهرباء',
        date: today.subtract(const Duration(days: 7)),
        createdAt: today.subtract(const Duration(days: 7)),
        userId: 1,
        accountId: 1,
        categoryId: 2,
        category: _housing,
      ),
      TransactionModel(
        id: 8,
        amount: 250.00,
        type: TransactionType.expense,
        description: 'بنزين',
        date: today.subtract(const Duration(days: 8)),
        createdAt: today.subtract(const Duration(days: 8)),
        userId: 1,
        accountId: 1,
        categoryId: 3,
        category: _transport,
      ),
      TransactionModel(
        id: 9,
        amount: 400.00,
        type: TransactionType.expense,
        description: 'صيانة السيارة',
        date: today.subtract(const Duration(days: 9)),
        createdAt: today.subtract(const Duration(days: 9)),
        userId: 1,
        accountId: 1,
        categoryId: 3,
        category: _transport,
      ),
      TransactionModel(
        id: 10,
        amount: 79.50,
        type: TransactionType.expense,
        description: 'ملابس وأحذية',
        date: today.subtract(const Duration(days: 10)),
        createdAt: today.subtract(const Duration(days: 10)),
        userId: 1,
        accountId: 1,
        categoryId: 4,
        category: _shopping,
      ),
      TransactionModel(
        id: 11,
        amount: 7300.00,
        type: TransactionType.income,
        description: 'الراتب الشهري',
        date: today.subtract(const Duration(days: 12)),
        createdAt: today.subtract(const Duration(days: 12)),
        userId: 1,
        accountId: 1,
        categoryId: 5,
        category: _salary,
      ),
    ];
  }
}
