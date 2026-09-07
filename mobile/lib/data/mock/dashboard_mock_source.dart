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

  // The rows the seeded transactions are filed under, resolved out of the tree
  // below so the two cannot drift apart.
  static Category _byId(int id) => categories.firstWhere((c) => c.id == id);

  static Category get _restaurants => _byId(13);   // الغذاء > المطاعم
  static Category get _housing => _byId(35);       // فواتير > الإيجار
  static Category get _transport => _byId(23);     // المواصلات (group)
  static Category get _shopping => _byId(16);      // التسوق (group)
  static Category get _salary => _byId(1);        // الراتب (income)

  /// The default category tree, identical to what `CategorySeeder` plants on
  /// the server: 7 income, 59 expense across 19 groups, 4 debt.
  ///
  /// Ids follow the seeder's planting order — income, then each group with its
  /// children, then debt — so both sources hand the screen the same sequence
  /// and it never has to sort a tree back into shape.
  ///
  /// The five flat rows that used to live here (المطاعم، السكن، النقل، التسوق،
  /// الراتب) are gone. Two of them survive by name inside the tree; السكن and
  /// النقل do not, so the seeded transactions were re-pointed — see
  /// [_restaurants] and friends below.
  static const List<Category> categories = [
    Category(id: 1, name: 'الراتب', type: Category.typeIncome, parentId: null, icon: 'salary'),
    Category(id: 2, name: 'المكافآت', type: Category.typeIncome, parentId: null, icon: 'bonus'),
    Category(id: 3, name: 'الهدايا', type: Category.typeIncome, parentId: null, icon: 'gift'),
    Category(id: 4, name: 'المبيعات', type: Category.typeIncome, parentId: null, icon: 'sale'),
    Category(id: 5, name: 'الإضافي', type: Category.typeIncome, parentId: null, icon: 'extra'),
    Category(id: 6, name: 'أخرى', type: Category.typeIncome, parentId: null, icon: 'other'),
    Category(id: 7, name: 'إضافة رصيد', type: Category.typeIncome, parentId: null, icon: 'top_up'),
    Category(id: 8, name: 'سحب رصيد', type: Category.typeExpense, parentId: null, icon: 'cash_out'),
    Category(id: 9, name: 'تحويل رصيد', type: Category.typeExpense, parentId: null, icon: 'transfer'),
    Category(id: 10, name: 'دفعة الكريديت', type: Category.typeExpense, parentId: 9, icon: 'credit_payment'),
    Category(id: 11, name: 'الغذاء', type: Category.typeExpense, parentId: null, icon: 'food'),
    Category(id: 12, name: 'المقاهي', type: Category.typeExpense, parentId: 11, icon: 'cafe'),
    Category(id: 13, name: 'المطاعم', type: Category.typeExpense, parentId: 11, icon: 'restaurant'),
    Category(id: 14, name: 'طبخة', type: Category.typeExpense, parentId: 11, icon: 'home_cooking'),
    Category(id: 15, name: 'اكل جاهز', type: Category.typeExpense, parentId: 11, icon: 'fast_food'),
    Category(id: 16, name: 'التسوق', type: Category.typeExpense, parentId: null, icon: 'shopping'),
    Category(id: 17, name: 'اكسسوارات', type: Category.typeExpense, parentId: 16, icon: 'accessories'),
    Category(id: 18, name: 'ملابس', type: Category.typeExpense, parentId: 16, icon: 'clothes'),
    Category(id: 19, name: 'الكترونيات', type: Category.typeExpense, parentId: 16, icon: 'electronics'),
    Category(id: 20, name: 'أحذية', type: Category.typeExpense, parentId: 16, icon: 'shoes'),
    Category(id: 21, name: 'مستحضرات تجميل', type: Category.typeExpense, parentId: 16, icon: 'cosmetics'),
    Category(id: 22, name: 'اكل', type: Category.typeExpense, parentId: 16, icon: 'groceries'),
    Category(id: 23, name: 'المواصلات', type: Category.typeExpense, parentId: null, icon: 'transport'),
    Category(id: 24, name: 'البنزين', type: Category.typeExpense, parentId: 23, icon: 'fuel'),
    Category(id: 25, name: 'الصيانة', type: Category.typeExpense, parentId: 23, icon: 'car_service'),
    Category(id: 26, name: 'الجراج', type: Category.typeExpense, parentId: 23, icon: 'parking'),
    Category(id: 27, name: 'الأجرة', type: Category.typeExpense, parentId: 23, icon: 'taxi'),
    Category(id: 28, name: 'تكسي للشركة', type: Category.typeExpense, parentId: 23, icon: 'company_taxi'),
    Category(id: 29, name: 'نول', type: Category.typeExpense, parentId: 23, icon: 'public_transport'),
    Category(id: 30, name: 'فواتير', type: Category.typeExpense, parentId: null, icon: 'bills'),
    Category(id: 31, name: 'الكهرباء', type: Category.typeExpense, parentId: 30, icon: 'electricity'),
    Category(id: 32, name: 'الغاز', type: Category.typeExpense, parentId: 30, icon: 'gas'),
    Category(id: 33, name: 'الإنترنت', type: Category.typeExpense, parentId: 30, icon: 'internet'),
    Category(id: 34, name: 'الإتصالات', type: Category.typeExpense, parentId: 30, icon: 'phone'),
    Category(id: 35, name: 'الإيجار', type: Category.typeExpense, parentId: 30, icon: 'rent'),
    Category(id: 36, name: 'الماء', type: Category.typeExpense, parentId: 30, icon: 'water'),
    Category(id: 37, name: 'أخرى', type: Category.typeExpense, parentId: null, icon: 'other'),
    Category(id: 38, name: 'دين', type: Category.typeExpense, parentId: 37, icon: 'debt'),
    Category(id: 39, name: 'غيث', type: Category.typeExpense, parentId: 37, icon: 'misc'),
    Category(id: 40, name: 'الأسرة', type: Category.typeExpense, parentId: null, icon: 'family'),
    Category(id: 41, name: 'الأطفال', type: Category.typeExpense, parentId: 40, icon: 'children'),
    Category(id: 42, name: 'الصيانة المنزلية', type: Category.typeExpense, parentId: 40, icon: 'home_repair'),
    Category(id: 43, name: 'الخدمات', type: Category.typeExpense, parentId: 40, icon: 'services'),
    Category(id: 44, name: 'الحيوانات الأليفة', type: Category.typeExpense, parentId: 40, icon: 'pets'),
    Category(id: 45, name: 'مصاريف شغل', type: Category.typeExpense, parentId: null, icon: 'work'),
    Category(id: 46, name: 'دين', type: Category.typeExpense, parentId: null, icon: 'debt'),
    Category(id: 47, name: 'التعليم', type: Category.typeExpense, parentId: null, icon: 'education'),
    Category(id: 48, name: 'كتب دراسية', type: Category.typeExpense, parentId: 47, icon: 'books'),
    Category(id: 49, name: 'الدورات التدريبية', type: Category.typeExpense, parentId: 47, icon: 'courses'),
    Category(id: 50, name: 'إستثمار', type: Category.typeExpense, parentId: null, icon: 'investment'),
    Category(id: 51, name: 'الترفيه', type: Category.typeExpense, parentId: null, icon: 'entertainment'),
    Category(id: 52, name: 'العاب', type: Category.typeExpense, parentId: 51, icon: 'games'),
    Category(id: 53, name: 'أفلام و صوتيات', type: Category.typeExpense, parentId: 51, icon: 'movies'),
    Category(id: 54, name: 'الرسوم و الإشتراكات', type: Category.typeExpense, parentId: null, icon: 'subscriptions'),
    Category(id: 55, name: 'التبرعات و الهدايا', type: Category.typeExpense, parentId: null, icon: 'donations'),
    Category(id: 56, name: 'الصدقة', type: Category.typeExpense, parentId: 55, icon: 'charity'),
    Category(id: 57, name: 'الزكاة', type: Category.typeExpense, parentId: 55, icon: 'zakat'),
    Category(id: 58, name: 'الهدايا', type: Category.typeExpense, parentId: 55, icon: 'gift'),
    Category(id: 59, name: 'الصحة و اللياقة البدنيه', type: Category.typeExpense, parentId: null, icon: 'health'),
    Category(id: 60, name: 'الأطباء', type: Category.typeExpense, parentId: 59, icon: 'doctor'),
    Category(id: 61, name: 'الأدوية', type: Category.typeExpense, parentId: 59, icon: 'medicine'),
    Category(id: 62, name: 'العناية الشخصية', type: Category.typeExpense, parentId: 59, icon: 'personal_care'),
    Category(id: 63, name: 'الانشطة الرياضية', type: Category.typeExpense, parentId: 59, icon: 'sports'),
    Category(id: 64, name: 'التأمينات', type: Category.typeExpense, parentId: null, icon: 'insurance'),
    Category(id: 65, name: 'السفر', type: Category.typeExpense, parentId: null, icon: 'travel'),
    Category(id: 66, name: 'السحب النقدي', type: Category.typeExpense, parentId: null, icon: 'atm'),
    Category(id: 67, name: 'سلفة', type: Category.typeDebt, parentId: null, icon: 'borrow'),
    Category(id: 68, name: 'تسديد سلفة', type: Category.typeDebt, parentId: null, icon: 'repay'),
    Category(id: 69, name: 'دين لي', type: Category.typeDebt, parentId: null, icon: 'lent'),
    Category(id: 70, name: 'دين عليّ', type: Category.typeDebt, parentId: null, icon: 'owed'),
  ];

  /// Σ balance = 14,450.00 for the parent, who sees the family's accounts and
  /// the children's wallets; 1,200.00 for نور and 800.00 for سعاد, who each see
  /// only their own. The design's 12,450.00 was the parent's two accounts alone,
  /// before the children had wallets.
  ///
  /// Each child has a wallet of their own. Accounts are scoped by role now — a
  /// member sees only what they own — so without these the two seeded children
  /// would open the app on an empty account list and be unable to record
  /// anything, since every transaction needs an account. The server does the
  /// same: `AuthController::createMember` opens a wallet with each child, and a
  /// migration backfills the ones created before the rule changed.
  static const List<Account> accounts = [
    Account(id: 1, name: 'الحساب الجاري', balance: 9450.00, userId: 1),
    Account(id: 2, name: 'التوفير', balance: 3000.00, userId: 1),
    Account(id: 3, name: 'محفظة نور', balance: 1200.00, userId: 2),
    Account(id: 4, name: 'محفظة سعاد', balance: 800.00, userId: 3),
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
