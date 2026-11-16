# مطابقة التطبيق مع التصميم

المرجع البصري: صور PNG في `docs/design/png/` (عرض 390px × 2). الألوان والقواعد: `docs/DESIGN.md`.
**صورة الـ PNG هي الحكم** عند أي اختلاف بين الكود والتصميم.

| الصورة | ملف Flutter |
| --- | --- |
| `Main.png` | `features/auth/login_screen.dart` |
| `Lock.png` | `features/lock/lock_screen.dart` + `pin_pad.dart` |
| `Home.png` | `features/home/dashboard_screen.dart` |
| `Customers.png` | `features/customers/customers_screen.dart` |
| `Customer.png` | `features/customers/customer_screen.dart` |
| `AddDebt.png` | `features/tx/add_tx_screen.dart` (وضع الدين؛ السداد بنفس الشكل بالأخضر) |
| `Promise.png` | `features/promises/promise_screen.dart` |
| `Reminders.png` | `features/settings/reminders_screen.dart` |
| `Reports.png` | `features/reports/reports_screen.dart` — العرض الشهري (الافتراضي) |
| `ReportsPicker.png` | نافذة اختيار الفترة (BottomSheet) |
| `ReportsDay.png` | التقارير — عرض يوم |
| `ReportsYear.png` | التقارير — عرض سنة |

## طريقة العمل لكل شاشة
1. افتح الصورة واقرأ ملف `.dc.html` المقابل: فيه القيم الدقيقة (أحجام الخط، المسافات، الزوايا، الألوان، الارتفاعات).
2. قارن مع الشاشة على الجوال: خذ لقطة بـ `adb exec-out screencap -p > shot.png` وضعها بجانب صورة التصميم.
3. صحّح: الترتيب، الأحجام، الألوان، الزوايا، الأيقونات، الخط (IBM Plex Sans Arabic محمّل فعلاً من assets؟).
4. كرر حتى تتطابق. البيانات في التصميم وهمية — المهم الشكل.

## قواعد لا تُكسر
- كل الألوان من `core/theme.dart` (`AjilColors`) — لا ألوان مكتوبة مباشرة في الشاشات. إن نقص لون في theme أضفه هناك.
- الأحمر `#B03224` للمبالغ وزر الدين فقط.
- `ThemeData`: الخط، `scaffoldBackgroundColor #F5F7F6`، حقول بزوايا 12، بطاقات 16، أزرار رئيسية ارتفاع 54–56 وزوايا 14، بدون ظلال ثقيلة (Material 3 مع `surfaceTint` شفاف حتى لا تتلون البطاقات).
- RTL كامل، والأرقام بالإنجليزية كما في التصميم.
- الشاشات غير المصممة (السداد، إضافة زبون، التقارير، الإعدادات، الإشعار، إرسال الأرصدة) تُعدَّل لتتبع نفس الهوية.
