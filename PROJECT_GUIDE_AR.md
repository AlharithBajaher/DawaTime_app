# دليل مشروع دواء تايم

آخر تحديث: 2026-06-04

هذا الملف يشرح مشروع `dawatime_app` من البداية إلى النهاية: الفكرة العامة، هيكل الملفات، طريقة تشغيل التطبيق، مسار الدخول، أدوار المستخدمين، الخدمات، قواعد Firebase، الإشعارات، واجهات المريض والصيدلي والأدمن، وكيف تعرف أين تعدل أي جزء.

---

## 1. فكرة المشروع باختصار

`دواء تايم` هو تطبيق Flutter مرتبط بـ Firebase هدفه تنظيم الأدوية والجرعات، ومساعدة المرضى على تذكر مواعيد الدواء، وتمكين الصيدلي من إدارة المخزون ونشر أدوية للمرضى، وتمكين الإدارة من التحكم بالمستخدمين واعتماد الصيادلة وإدارة طلبات استعادة كلمة المرور.

الأدوار الرئيسية:

| الدور | ماذا يرى؟ | أهم الملفات |
|---|---|---|
| مريض `patient` | جدول الجرعات، الأدوية، التقارير، سوق الأدوية، المزيد | `lib/features/patient/` |
| صيدلي `pharmacist` | لوحة صيدلي، مخزون، أدوية منشورة، حساب | `lib/features/pharmacist/` |
| أدمن `admin` | لوحة إدارة، طلبات الصيادلة، المرضى، حسابات الأدمن، طلبات استعادة كلمة المرور | `lib/features/admin/` |

---

## 2. نقطة بداية التطبيق

أول ملف يبدأ منه التطبيق هو:

`lib/main.dart`

وظيفته:

1. تشغيل Flutter bindings.
2. تهيئة Firebase عبر `Firebase.initializeApp`.
3. تفعيل تخزين Firestore المحلي `persistenceEnabled: true` حتى يعمل جزء من البيانات عند ضعف الاتصال.
4. تفعيل Firebase App Check في وضع الإصدار فقط.
5. تهيئة نظام الإشعارات المحلي من `NotificationService.init()`.
6. تشغيل `DawaTimeApp`.
7. تحميل الثيم واللغة ثم فتح `AuthWrapper`.

مسار البداية:

```text
main.dart
  -> DawaTimeApp
  -> MaterialApp
  -> AuthWrapper
```

---

## 3. هيكل المشروع العام

أهم الملفات والمجلدات في الجذر:

| المسار | الوظيفة |
|---|---|
| `pubspec.yaml` | تعريف اسم المشروع، الإصدارات، المكتبات، الصور والأصول |
| `firestore.rules` | قواعد أمان Firestore |
| `firebase.json` | إعداد FlutterFire للمشروع |
| `firebase.deploy.json` | ملف خاص لنشر قواعد Firestore فقط |
| `.firebaserc` | يحدد مشروع Firebase الافتراضي |
| `lib/` | كل كود Dart/Flutter |
| `assets/images/` | صور التطبيق والأيقونات |
| `assets/audio/` | ملفات صوت |
| `assets/voice/` | ملفات صوتية أو نطق |
| `android/` | إعدادات Android |
| `ios/`, `web/`, `windows/`, `linux/`, `macos/` | منصات Flutter الأخرى |

أهم المكتبات في `pubspec.yaml`:

| المكتبة | الاستخدام |
|---|---|
| `firebase_core` | تشغيل Firebase |
| `firebase_auth` | تسجيل الدخول والحسابات |
| `cloud_firestore` | قاعدة البيانات |
| `firebase_storage` | رفع صور الأدوية المنشورة |
| `google_sign_in` | تسجيل الدخول بحساب Google |
| `flutter_local_notifications` | إشعارات الجرعات والمخزون |
| `timezone` | جدولة الإشعارات بالتوقيت المحلي |
| `url_launcher` | فتح اتصال، واتساب، إيميل، روابط |
| `image_picker` | اختيار صور للأدوية المنشورة |

---

## 4. تقسيم مجلد `lib`

```text
lib/
  main.dart
  firebase_options.dart
  app/
    config/
    localization/
    theme/
    widgets/
  data/
    models/
    services/
  features/
    auth/
    patient/
    pharmacist/
    admin/
    settings/
```

هذا التقسيم مهم جدًا:

| المجلد | معناه |
|---|---|
| `app/` | أشياء عامة مشتركة بين كل التطبيق: الثيم، اللغة، الودجت المشتركة |
| `data/models/` | نماذج البيانات القادمة من Firestore |
| `data/services/` | الخدمات التي تقرأ وتكتب في Firebase أو تشغل الإشعارات |
| `features/` | الشاشات والتجارب حسب القسم أو الدور |

---

## 5. مجلد `app`

### `lib/app/theme/app_theme.dart`

هذا ملف الثيم العام.

يحتوي على:

| العنصر | الوظيفة |
|---|---|
| `AppPalette` | ألوان التطبيق الأساسية |
| `AppTheme.lightTheme()` | ثيم Material 3 |
| `_DawaTimePageTransitionsBuilder` | يلغي الانتقالات الطويلة بين الصفحات لتقليل الشاشات الفارغة |

ألوان مهمة:

| اللون | الاستخدام |
|---|---|
| `patientPrimary` | اللون الرئيسي للمريض |
| `pharmacistPrimary` | اللون الرئيسي للصيدلي |
| `adminPrimary` | اللون الرئيسي للأدمن |
| `success` | حالات النجاح |
| `amber` | التحذيرات والتنبيهات |

### `lib/app/theme/app_metrics.dart`

هذا ملف المقاسات الموحدة.

يحتوي على:

| الكلاس | الوظيفة |
|---|---|
| `AppSpacing` | المسافات الداخلية والخارجية |
| `AppRadius` | الزوايا |
| `AppLayout` | أقصى عرض للمحتوى والـ sheets |
| `AppFontSize` | أحجام الخطوط |

إذا أردت تغيير شكل التطبيق كله، ابدأ غالبًا من `app_theme.dart` و`app_metrics.dart`.

### `lib/app/localization/app_localization.dart`

هذا نظام اللغة داخل التطبيق.

يحتوي على:

| العنصر | الوظيفة |
|---|---|
| `AppLocaleController` | يحفظ اللغة الحالية عربي/إنجليزي |
| `AppLocaleScope` | يوزع اللغة داخل شجرة الودجت |
| `AppStrings` | قاموس النصوص الأساسية |
| `context.tr(ar: ..., en: ...)` | اختيار النص حسب اللغة |
| `context.t(AppText.appName)` | جلب نص محفوظ بمفتاح |

مثال:

```dart
context.tr(ar: 'الأدوية', en: 'Medications')
```

### `lib/app/widgets/`

هذا المجلد للودجت المشتركة.

| الملف | الوظيفة |
|---|---|
| `depth_card.dart` | كرت موحد مستخدم في أغلب الواجهات |
| `home_navigation_chrome.dart` | الشريط العلوي والسفلي للتنقل |
| `profile_side_drawer.dart` | القائمة الجانبية للحساب |
| `profile_editor_sheet.dart` | نافذة تعديل الملف الشخصي |
| `support_center_sheet.dart` | نافذة الدعم والتواصل |
| `language_toggle_button.dart` | زر تغيير اللغة |
| `animated_welcome_banner.dart` | رسالة ترحيب متحركة |

ملف `support_center_sheet.dart` مهم لأنه يحتوي على بيانات التواصل:

```text
اتصال
واتساب
إنستقرام
إيميل
```

ويفتح التطبيقات الخارجية عبر `url_launcher`.

---

## 6. مجلد `data/models`

النموذج `Model` هو كلاس يحول مستند Firestore إلى كائن Dart سهل الاستخدام.

### `app_user_model.dart`

يمثل المستخدم في مجموعة `users`.

أهم الحقول:

| الحقل | المعنى |
|---|---|
| `uid` | رقم المستخدم من Firebase Auth |
| `name` | الاسم |
| `username` | اسم المستخدم |
| `email` | البريد |
| `role` | `patient` أو `pharmacist` أو `admin` |
| `approvalStatus` | `approved` أو `pending` أو `rejected` |
| `pharmacyName` | اسم الصيدلية للصيدلي |
| `pharmacyLocation` | موقع الصيدلية |
| `pharmacyPhone` | هاتف الصيدلية |

دوال مهمة:

| الدالة | معناها |
|---|---|
| `needsAdminApproval` | هل الصيدلي ينتظر موافقة الإدارة؟ |
| `isRejected` | هل الصيدلي مرفوض؟ |
| `displayName` | اسم جاهز للعرض |
| `initials` | الأحرف الأولى للصورة الرمزية |

### `medication_model.dart`

يمثل دواء المريض في `medications` وأيضًا تقرير الدواء في `medication_reports`.

أهم الحقول:

| الحقل | المعنى |
|---|---|
| `name` | اسم الدواء |
| `dose` | الجرعة النصية |
| `form` | شكل الدواء: حبوب، شراب، بخاخ |
| `quantity` | الكمية الأصلية |
| `remainingQuantity` | الكمية المتبقية |
| `doseTimes` | أوقات الجرعات اليومية |
| `intervalDays` | كل كم يوم يتكرر الدواء |
| `notificationIds` | أرقام الإشعارات المحلية |
| `takenDoseLogs` | سجل الجرعات المأخوذة |
| `skippedDoseLogs` | سجل الجرعات المتخطاة |
| `isArchived` | هل الدواء انتهى أو أرشف؟ |

دوال مهمة:

| الدالة | الوظيفة |
|---|---|
| `sortedDoseTimes` | ترتيب أوقات الجرعات |
| `isScheduledOnDate(date)` | هل الدواء مجدول في هذا اليوم؟ |
| `isDoseTaken(scheduledAt)` | هل جرعة محددة تم تناولها؟ |
| `isDoseSkipped(scheduledAt)` | هل جرعة محددة تم تخطيها؟ |
| `isDoseMissed(scheduledAt)` | هل جرعة فاتت؟ |
| `doseLogKeyFor()` | يولد مفتاح ثابت للجرعة مثل `20260604_0900` |

### `pharmacy_task_model.dart`

يمثل عنصر مخزون الصيدلي في مجموعة `pharmacy`.

أهم الحقول:

| الحقل | المعنى |
|---|---|
| `title` | اسم عنصر المخزون |
| `quantity` | الكمية الحالية |
| `minQuantity` | حد التنبيه |
| `unit` | الوحدة |
| `isOutOfStock` | هل نفدت الكمية؟ |
| `isLowStock` | هل الكمية تحت الحد؟ |

### `shared_medicine_model.dart`

يمثل دواء منشور في السوق داخل مجموعة `shared_medicines`.

أهم الحقول:

| الحقل | المعنى |
|---|---|
| `pharmacistId` | صاحب النشر |
| `pharmacyName` | اسم الصيدلية |
| `name` | اسم الدواء |
| `description` | وصف الدواء |
| `usageInstructions` | تعليمات الاستخدام |
| `dosage` | الجرعة العامة |
| `packageSize` | حجم العبوة |
| `price` | السعر بالريال اليمني |
| `isAvailable` | متوفر أم لا |
| `requiresPrescription` | يحتاج وصفة أم لا |
| `searchIndex` | كلمات البحث |
| `imageUrl` | رابط الصورة |

### بقية النماذج

| الملف | الوظيفة |
|---|---|
| `pharmacy_rating_model.dart` | تقييمات المرضى للصيدليات |
| `password_reset_request_model.dart` | طلبات استعادة كلمة المرور |

---

## 7. مجلد `data/services`

الخدمة `Service` هي المكان الذي يتعامل مع Firebase أو الإشعارات. الواجهة لا تكتب غالبًا إلى Firestore مباشرة، بل تستدعي خدمة.

### `auth_service.dart`

يدير تسجيل الدخول والحسابات.

أهم الوظائف:

| الوظيفة | الاستخدام |
|---|---|
| `authStateChanges` | مراقبة حالة تسجيل الدخول |
| `watchUserProfile(uid)` | مراقبة ملف المستخدم |
| `registerWithEmail` | إنشاء حساب ببريد وكلمة مرور |
| `signInWithEmailAccount` | تسجيل دخول كمريض أو صيدلي |
| `signInAdmin` | تسجيل دخول الأدمن |
| `signInWithGoogle` | تسجيل دخول Google |
| `updateCurrentUserProfile` | تعديل ملف المستخدم |
| `watchAllUsers` | جلب المستخدمين للأدمن |
| `updatePharmacistApproval` | قبول أو رفض صيدلي |
| `submitPasswordResetRequest` | طلب رمز استعادة |
| `issuePasswordResetCode` | إصدار رمز من الأدمن |
| `sendPasswordResetEmailViaCode` | إرسال رابط إعادة تعيين بعد التحقق من الرمز |
| `ensureAdminProfile` | إنشاء/تصحيح حساب الأدمن الأساسي |

الأدمن الأساسي معرف في:

`lib/app/config/admin_access.dart`

البريد:

```text
hsab7164@gmail.com
```

### `medication_service.dart`

يدير أدوية المريض وتقاريرها.

أهم الوظائف:

| الوظيفة | الاستخدام |
|---|---|
| `addMedication` | إضافة دواء جديد |
| `updateMedication` | تعديل دواء موجود |
| `getUserMedications` | مراقبة أدوية المستخدم |
| `getUserMedicationReports` | مراقبة تقارير الأدوية الدائمة |
| `syncMedicationReportFromMedication` | حفظ نسخة تقرير من الدواء |
| `deleteMedication` | حذف الدواء من `medications` مع إبقاء التقرير |
| `markDoseAsTaken` | تسجيل جرعة مأخوذة وإنقاص الكمية |
| `markDoseAsSkipped` | تسجيل جرعة متخطاة |
| `replaceNotificationIds` | تحديث أرقام الإشعارات |

مهم جدًا:

عند حذف دواء، يتم حفظ بياناته أولًا في:

```text
medication_reports
```

ثم يحذف من:

```text
medications
```

بهذا يبقى التقرير ظاهرًا حتى بعد حذف الدواء أو نفاد كميته.

### `notification_service.dart`

يدير كل الإشعارات المحلية.

أنواع الإشعارات:

| النوع | الوظيفة |
|---|---|
| تذكير جرعة | يظهر وقت تناول الدواء |
| تأجيل جرعة | إشعار مرة واحدة بعد 30 أو 60 دقيقة |
| تنبيه كمية دواء | عند قرب نفاد كمية دواء المريض |
| تنبيه مخزون صيدلي | عند انخفاض مخزون الصيدلي |

وظائف مهمة:

| الوظيفة | الاستخدام |
|---|---|
| `init` | تهيئة الإشعارات |
| `scheduleMedicationReminders` | جدولة جرعات الدواء |
| `scheduleLowStockReminder` | جدولة تنبيه قرب النفاد |
| `syncInventoryAlert` | مزامنة تنبيه المخزون |
| `handleNotificationAction` | تنفيذ تناول/تخطي/تأجيل من الإشعار |
| `_markDoseStatus` | يكتب حالة الجرعة في Firestore من الخلفية |

عند تناول آخر جرعة من الإشعار:

1. يحفظ التقرير في `medication_reports`.
2. يحذف الدواء من `medications`.
3. يلغي إشعارات الدواء والكمية.

### `pharmacy_service.dart`

يدير مخزون الصيدلي في مجموعة `pharmacy`.

أهم الوظائف:

| الوظيفة | الاستخدام |
|---|---|
| `watchTasks` | مراقبة المخزون |
| `addTask` | إضافة عنصر مخزون |
| `updateTask` | تعديل عنصر مخزون |
| `toggleTask` | جعله متوفر/نافد |
| `adjustStock` | زيادة أو إنقاص الكمية |
| `deleteTask` | حذف عنصر مخزون |

### `shared_medicine_service.dart`

يدير الأدوية المنشورة من الصيدلي للمرضى.

أهم الوظائف:

| الوظيفة | الاستخدام |
|---|---|
| `watchMarketplaceMedicines` | عرض السوق للمريض |
| `watchMyPublishedMedicines` | أدوية الصيدلي المنشورة |
| `addSharedMedicine` | نشر دواء |
| `updateSharedMedicine` | تعديل دواء منشور |
| `updateAvailability` | تبديل التوفر |
| `deleteSharedMedicine` | حذف دواء منشور |
| `_tryUploadImage` | رفع صورة إذا كان Firebase Storage متاحًا |

### `pharmacy_rating_service.dart`

يدير تقييم الصيدليات.

أهم الوظائف:

| الوظيفة | الاستخدام |
|---|---|
| `watchRatingsForPharmacist` | تقييمات صيدلي معين |
| `watchSummaryForPharmacist` | متوسط التقييم وعدده |
| `submitRating` | إرسال أو تحديث تقييم المريض |

---

## 8. مسار المصادقة والدخول

ملفات المصادقة:

```text
lib/features/auth/
  auth_wrapper.dart
  account_gate_screens.dart
  login/login_screen.dart
  role_selection/role_selection_screen.dart
  welcome/welcome_portal.dart
  welcome/welcome_portal_pages.dart
```

### `auth_wrapper.dart`

هذا الملف هو حارس التطبيق.

وظيفته:

1. يعرض شاشة البداية `WelcomePortal` لمدة قصيرة.
2. يراقب حالة Firebase Auth.
3. إذا لا يوجد مستخدم، يفتح `LoginScreen`.
4. إذا يوجد مستخدم، يراقب ملفه في `users`.
5. يوجه المستخدم حسب `role`.

مسار التوجيه:

```text
role == patient     -> PatientHome
role == pharmacist  -> PharmacistHome
role == admin       -> AdminHome
```

حالات خاصة:

```text
pharmacist + pending  -> PharmacistPendingScreen
pharmacist + rejected -> PharmacistRejectedScreen
```

### `login_screen.dart`

واجهة تسجيل الدخول والتسجيل.

تحتوي على:

| الجزء | الوظيفة |
|---|---|
| تسجيل دخول | بريد/كلمة مرور |
| إنشاء حساب | اختيار مريض أو صيدلي |
| Google Sign-In | دخول بحساب Google |
| نسيت كلمة المرور | طلب رمز من الإدارة |
| وصول الإدارة | يفتح شاشة أدمن |
| التواصل بالإدارة | يفتح نافذة الدعم |
| دليل التطبيق/الخصوصية/الشروط | صفحات معلومات |

عند تسجيل صيدلي جديد:

```text
role = pharmacist
approvalStatus = pending
```

وبالتالي لا يدخل لوحة الصيدلي حتى يوافق الأدمن.

### `welcome_portal.dart`

شاشة البداية داخل التطبيق.

تعرض:

| العنصر | الوظيفة |
|---|---|
| شعار/اسم التطبيق | بداية مرئية |
| دليل التطبيق | صفحة شرح مختصر |
| الخصوصية | صفحة معلومات |
| الشروط | صفحة معلومات |
| بدء الآن | الانتقال للتسجيل أو التطبيق |

---

## 9. واجهة المريض

المجلد:

```text
lib/features/patient/
```

أهم الملفات:

| الملف | الوظيفة |
|---|---|
| `patient_home.dart` | الملف الرئيسي، يمسك الحالة والعمليات |
| `patient_home_tabs.dart` | تبويبات المريض وكروت الواجهة |
| `patient_home_sheets.dart` | النوافذ السفلية مثل إجراءات الجرعة |
| `patient_marketplace_tab.dart` | سوق الأدوية وتفاصيل الدواء والتقييم |
| `medication_editor_page.dart` | إضافة/تعديل دواء |

### `patient_home.dart`

هذا هو قلب واجهة المريض.

أهم العمليات فيه:

| الدالة | الوظيفة |
|---|---|
| `_timelineForDate` | يبني جدول جرعات اليوم |
| `_synchronizeMedicationReminders` | يزامن إشعارات الأدوية |
| `_synchronizeMedicationReports` | يضمن وجود تقارير للأدوية |
| `_openMedicationEditor` | فتح صفحة إضافة/تعديل دواء |
| `_saveMedication` | حفظ الدواء وجدولة إشعاراته |
| `_deleteMedication` | حذف الدواء |
| `_confirmDeleteMedication` | رسالة تأكيد الحذف |
| `_markDoseAsTaken` | تسجيل جرعة مأخوذة |
| `_markDoseAsSkipped` | تسجيل جرعة متخطاة |
| `_snoozeDose` | تأجيل الجرعة |
| `_showMedicationActions` | فتح نافذة الإجراءات |

تبويبات المريض:

| رقم | التبويب | الملف |
|---|---|---|
| 0 | الرئيسية وجدول الجرعات | `patient_home_tabs.dart` |
| 1 | الأدوية | `patient_home_tabs.dart` |
| 2 | تصفح السوق | `patient_marketplace_tab.dart` |
| 3 | التحديثات/التقارير | `patient_home_tabs.dart` |
| 4 | المزيد | `patient_home_tabs.dart` |

### إضافة دواء

المسار:

```text
PatientHome
  -> _openMedicationEditor
  -> MedicationEditorPage
  -> MedicationEditorResult
  -> _saveMedication
  -> MedicationService.addMedication/updateMedication
  -> NotificationService.scheduleMedicationReminders
```

### تناول جرعة

المسار:

```text
ضغط على جرعة
  -> _MedicationActionSheet
  -> _markDoseAsTaken
  -> MedicationService.markDoseAsTaken
  -> تحديث takenDoseLogs
  -> إنقاص remainingQuantity
  -> تحديث medication_reports
  -> حذف الدواء إذا انتهت الكمية
```

### التقارير

التقارير موجودة في:

`patient_home_tabs.dart`

الكلاسات المهمة:

| الكلاس | الوظيفة |
|---|---|
| `_MedicationReportsLivePage` | يقرأ التقارير من Firestore |
| `_MedicationReportsPage` | يعرض تقارير 7/30/90 يوم |
| `_AdherenceReport` | بيانات التقرير |
| `_MedicationMonthCalendarSheet` | تقويم الشهر للدواء |

التقرير يستخدم:

```text
medication_reports
```

وإذا لم يجد بيانات يستخدم الأدوية الحالية كاحتياط.

تقويم الشهر:

| العلامة | معناها |
|---|---|
| صح أخضر | كل جرعات اليوم تم تناولها |
| خطأ أحمر | يوجد جرعة لم تؤخذ |
| شرطة رمادية | يوم قادم أو جرعة لم يحن وقتها |
| فارغ | الدواء غير مجدول في هذا اليوم |

### سوق الأدوية للمريض

الملف:

`patient_marketplace_tab.dart`

يعرض الأدوية المنشورة من الصيادلة من مجموعة:

```text
shared_medicines
```

يستطيع المريض:

1. البحث.
2. فتح تفاصيل دواء.
3. رؤية الصيدلية والسعر والتوفر.
4. إرسال تقييم للصيدلية.

---

## 10. واجهة الصيدلي

المجلد:

```text
lib/features/pharmacist/
```

أهم الملفات:

| الملف | الوظيفة |
|---|---|
| `pharmacist_home.dart` | الملف الرئيسي للصيدلي |
| `pharmacist_home_sections.dart` | أقسام لوحة الصيدلي |
| `pharmacist_home_editor.dart` | محرر عناصر المخزون |
| `pharmacist_inventory_tab.dart` | واجهة المخزون |
| `pharmacist_medicine_tab.dart` | الأدوية المنشورة |
| `pharmacist_medicine_editor_page.dart` | إضافة/تعديل دواء منشور |

### `pharmacist_home.dart`

يدير:

| العملية | الدالة |
|---|---|
| فتح محرر المخزون | `_openTaskEditor` |
| حذف عنصر مخزون | `_deleteTask` |
| فتح محرر دواء منشور | `_openMedicineEditor` |
| تبديل توفر دواء منشور | `_toggleMedicineAvailability` |
| حذف دواء منشور | `_deleteMedicineListing` |
| تعديل ملف الصيدلي | `_openProfileEditor` |

تبويبات الصيدلي:

| التبويب | الوظيفة |
|---|---|
| الرئيسية | ملخص الصيدلي |
| المخزون | إدارة الكميات |
| الأدوية | الأدوية المنشورة للمرضى |
| التحليلات | معلومات وإحصائيات |
| الحساب | بيانات الحساب |

### المخزون

الملف:

`pharmacist_inventory_tab.dart`

يعرض كروت المخزون مع:

| العنصر | الوظيفة |
|---|---|
| زر `+` | زيادة الكمية |
| زر `-` | إنقاص الكمية |
| العدد في الوسط | الكمية الحالية |
| حد التنبيه | `minQuantity` |
| حالة منخفض/نافد | حسب الكمية |

الخدمة المستخدمة:

`PharmacyService.adjustStock`

المجموعة في Firestore:

```text
pharmacy
```

### نشر دواء من الصيدلي

الملف:

`pharmacist_medicine_editor_page.dart`

يحتوي على:

| العنصر | الوظيفة |
|---|---|
| اسم الدواء | `name` |
| الوصف | `description` |
| الاستخدام | `usageInstructions` |
| الجرعة | `dosage` |
| حجم العبوة | `packageSize` |
| السعر | `price` |
| التوفر | `isAvailable` |
| يحتاج وصفة | `requiresPrescription` |
| صورة | ترفع إلى Firebase Storage إذا متاح |

---

## 11. واجهة الأدمن

المجلد:

```text
lib/features/admin/
```

أهم الملفات:

| الملف | الوظيفة |
|---|---|
| `admin_login_screen.dart` | تسجيل دخول الأدمن |
| `admin_home.dart` | الملف الرئيسي للوحة الإدارة |
| `admin_home_sections.dart` | كروت وأقسام الإدارة |

### تسجيل دخول الأدمن

يتم من كرت `وصول الإدارة` في شاشة تسجيل الدخول.

الأدمن الأساسي:

```text
hsab7164@gmail.com
```

### `admin_home.dart`

يدير:

| الدالة | الوظيفة |
|---|---|
| `_handleApprovalChange` | قبول/رفض صيدلي |
| `_issueResetAccessCode` | إصدار رمز استعادة كلمة مرور |
| `_openProfileEditor` | تعديل ملف الأدمن |
| `_buildSection` | اختيار القسم المعروض |

أقسام الأدمن:

| القسم | الوظيفة |
|---|---|
| Dashboard | ملخص عام |
| Requests | طلبات الصيادلة |
| Pharmacists | كل الصيادلة |
| Patients | كل المرضى |
| Access | الأدمن وطلبات استعادة كلمة المرور |

---

## 12. إعدادات التطبيق

الملف:

`lib/features/settings/settings_page.dart`

يوفر:

| العنصر | الوظيفة |
|---|---|
| تغيير اللغة | عربي/إنجليزي |
| دعم دواء تايم | يفتح `SupportCenterSheet` |

---

## 13. قواعد Firestore

الملف:

`firestore.rules`

هذا الملف يحدد من يقرأ ويكتب في Firestore.

المجموعات الأساسية:

| المجموعة | من يستخدمها؟ | الوظيفة |
|---|---|---|
| `users` | الجميع حسب الصلاحية | ملفات المستخدمين |
| `medications` | المريض فقط | الأدوية المجدولة الحالية |
| `medication_reports` | المريض فقط | تقارير أدوية دائمة بعد الحذف |
| `pharmacy` | الصيدلي المعتمد فقط | مخزون الصيدلي |
| `shared_medicines` | الصيدلي ينشر، الجميع يقرأ بعد تسجيل الدخول | سوق الأدوية |
| `pharmacy_ratings` | المرضى يكتبون، الجميع يقرأ بعد تسجيل الدخول | تقييم الصيدليات |
| `password_reset_requests` | المستخدم يطلب، الأدمن يدير | استعادة كلمة المرور |

أهم الدوال داخل القواعد:

| الدالة | الوظيفة |
|---|---|
| `isSignedIn()` | هل المستخدم مسجل دخول؟ |
| `isOwner(userId)` | هل المستخدم هو صاحب الحساب؟ |
| `isBootstrapAdmin()` | هل البريد هو أدمن أساسي؟ |
| `isAdmin()` | هل المستخدم أدمن؟ |
| `isPatient()` | هل المستخدم مريض؟ |
| `isApprovedPharmacist()` | هل الصيدلي معتمد؟ |

نشر القواعد:

```powershell
firebase.cmd deploy --only firestore:rules --config firebase.deploy.json --project my-alharith-first-one
```

سبب استخدام `firebase.deploy.json`:

ملف `firebase.json` الحالي خاص بـ FlutterFire وفيه مفتاح `flutter`، لذلك نستخدم ملف نشر منفصل يحتوي فقط على:

```json
{
  "firestore": {
    "rules": "firestore.rules"
  }
}
```

---

## 14. تدفق البيانات بين الواجهة وفايرباس

### تسجيل حساب جديد

```text
LoginScreen
  -> AuthService.registerWithEmail
  -> Firebase Auth creates user
  -> users/{uid} is created
  -> AuthWrapper reads profile
  -> opens proper home screen
```

### اعتماد صيدلي

```text
AdminHome
  -> _handleApprovalChange
  -> AuthService.updatePharmacistApproval
  -> users/{uid}.approvalStatus = approved/rejected
  -> AuthWrapper يغير شاشة الصيدلي تلقائياً
```

### إضافة دواء مريض

```text
MedicationEditorPage
  -> MedicationEditorResult
  -> PatientHome._saveMedication
  -> MedicationService.addMedication
  -> medications/{id}
  -> medication_reports/{id}
  -> NotificationService.scheduleMedicationReminders
```

### حذف دواء مريض

```text
PatientHome._confirmDeleteMedication
  -> MedicationService.deleteMedication
  -> save latest report into medication_reports/{id}
  -> delete medications/{id}
  -> cancel notifications
```

### نفاد كمية الدواء

```text
markDoseAsTaken
  -> remainingQuantity - 1
  -> if remainingQuantity == 0
  -> save report
  -> delete scheduled medication
  -> keep report visible
```

### نشر دواء صيدلي

```text
PharmacistMedicineEditorPage
  -> SharedMedicineService.addSharedMedicine
  -> optional image upload to Firebase Storage
  -> shared_medicines/{id}
  -> patient marketplace reads it
```

### تعديل مخزون

```text
Pharmacist inventory card
  -> + or -
  -> PharmacyService.adjustStock
  -> pharmacy/{id}.quantity
  -> sync local inventory alert
```

---

## 15. كيف تدخل على كل جزء من الكود

داخل VS Code أو Android Studio استخدم البحث السريع:

```text
Ctrl + P
```

ثم اكتب اسم الملف.

أهم الملفات التي ستفتحها كثيرًا:

| تريد تعديل | افتح |
|---|---|
| بداية التطبيق | `lib/main.dart` |
| توجيه المستخدم بعد الدخول | `lib/features/auth/auth_wrapper.dart` |
| شاشة تسجيل الدخول | `lib/features/auth/login/login_screen.dart` |
| شاشة البداية | `lib/features/auth/welcome/welcome_portal.dart` |
| نصوص البداية | `lib/features/auth/welcome/welcome_portal_pages.dart` |
| صفحة المريض الرئيسية | `lib/features/patient/patient_home.dart` |
| تبويبات المريض | `lib/features/patient/patient_home_tabs.dart` |
| نوافذ إجراءات الجرعات | `lib/features/patient/patient_home_sheets.dart` |
| محرر دواء المريض | `lib/features/patient/medication_editor_page.dart` |
| سوق المريض | `lib/features/patient/patient_marketplace_tab.dart` |
| صفحة الصيدلي | `lib/features/pharmacist/pharmacist_home.dart` |
| مخزون الصيدلي | `lib/features/pharmacist/pharmacist_inventory_tab.dart` |
| أدوية الصيدلي المنشورة | `lib/features/pharmacist/pharmacist_medicine_tab.dart` |
| محرر دواء منشور | `lib/features/pharmacist/pharmacist_medicine_editor_page.dart` |
| صفحة الأدمن | `lib/features/admin/admin_home.dart` |
| أقسام الأدمن | `lib/features/admin/admin_home_sections.dart` |
| خدمات الحسابات | `lib/data/services/auth_service.dart` |
| خدمات الأدوية | `lib/data/services/medication_service.dart` |
| خدمات الإشعارات | `lib/data/services/notification_service.dart` |
| خدمات المخزون | `lib/data/services/pharmacy_service.dart` |
| خدمات السوق | `lib/data/services/shared_medicine_service.dart` |
| الثيم | `lib/app/theme/app_theme.dart` |
| المقاسات | `lib/app/theme/app_metrics.dart` |
| اللغة | `lib/app/localization/app_localization.dart` |
| الدعم والتواصل | `lib/app/widgets/support_center_sheet.dart` |
| قواعد Firebase | `firestore.rules` |

---

## 16. كيف تعدل أشياء شائعة

### تغيير رقم الدعم أو الإيميل

افتح:

```text
lib/app/widgets/support_center_sheet.dart
```

ثم عدل القيم:

```dart
supportPhone
supportWhatsapp
supportEmail
supportInstagram
```

### تغيير ألوان التطبيق

افتح:

```text
lib/app/theme/app_theme.dart
```

عدل `AppPalette`.

### تغيير نص عربي/إنجليزي في شاشة معينة

ابحث داخل الملف عن:

```dart
context.tr(ar: '...', en: '...')
```

وعدل النصين.

### تغيير تبويبات المريض

افتح:

```text
lib/features/patient/patient_home.dart
```

وابحث عن:

```dart
_buildTabContent
AnimatedHomeBottomBar
```

### تغيير كرت جرعة المريض

افتح:

```text
lib/features/patient/patient_home_tabs.dart
```

وابحث عن:

```dart
_DoseMomentCard
```

### تغيير نافذة إجراءات الجرعة

افتح:

```text
lib/features/patient/patient_home_sheets.dart
```

وابحث عن:

```dart
_MedicationActionSheet
```

### تغيير منطق تناول/تخطي الجرعة

افتح:

```text
lib/data/services/medication_service.dart
```

وابحث عن:

```dart
markDoseAsTaken
markDoseAsSkipped
```

### تغيير منطق الإشعارات

افتح:

```text
lib/data/services/notification_service.dart
```

وابحث عن:

```dart
scheduleMedicationReminders
scheduleLowStockReminder
syncInventoryAlert
_markDoseStatus
```

### تغيير قواعد الصلاحيات

افتح:

```text
firestore.rules
```

بعد التعديل انشر:

```powershell
firebase.cmd deploy --only firestore:rules --config firebase.deploy.json --project my-alharith-first-one
```

---

## 17. أوامر مهمة

تشغيل التحليل:

```powershell
C:\dev\flutter\bin\flutter.bat --suppress-analytics analyze
```

تشغيل التطبيق:

```powershell
C:\dev\flutter\bin\flutter.bat run
```

جلب الحزم:

```powershell
C:\dev\flutter\bin\flutter.bat pub get
```

نشر قواعد Firestore:

```powershell
firebase.cmd deploy --only firestore:rules --config firebase.deploy.json --project my-alharith-first-one
```

---

## 18. ملاحظات مهمة عن التصميم

التطبيق يستخدم أسلوب موحد:

| العنصر | الملف |
|---|---|
| الكروت | `DepthCard` |
| شريط التنقل السفلي | `AnimatedHomeBottomBar` |
| القائمة الجانبية | `ProfileSideDrawer` |
| ألوان الدور | `AppPalette` |
| المسافات | `AppSpacing` |
| الزوايا | `AppRadius` |

الفكرة:

1. لا تكرر تصميم كرت جديد من الصفر إلا إذا احتجت.
2. استخدم `DepthCard` للكروت.
3. استخدم `context.tr` لكل نص يظهر للمستخدم.
4. حافظ على فصل المنطق عن الواجهة: الواجهة تستدعي خدمة، والخدمة تكتب في Firestore.

---

## 19. ملاحظات مهمة عن العمل بدون إنترنت

في `main.dart`:

```dart
FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
```

هذا يعني أن Firestore يحاول استخدام الكاش المحلي عند ضعف الاتصال.

عمليات الجرعات في `MedicationService` مصممة بأسلوب `set(..., merge: true)` بدل الاعتماد الكامل على transactions، وهذا يساعد أكثر في حالات الاتصال الضعيف.

لكن يجب الانتباه:

1. بعض العمليات تحتاج مزامنة لاحقة عندما يعود الإنترنت.
2. الإشعارات المحلية تعمل على الجهاز، لكن تحديث Firestore يحتاج المستخدم مسجل دخول وFirebase مهيأ.
3. التقرير يحفظ في `medication_reports` حتى لا يختفي بعد حذف الدواء المجدول.

---

## 20. الخلاصة الذهنية للمشروع

تخيل المشروع كطبقات:

```text
UI Screens
  -> Services
  -> Firebase / Notifications
  -> Models
  -> UI rebuilds via Streams
```

مثال عملي:

```text
المريض ضغط "تناول"
  -> patient_home.dart
  -> medication_service.dart
  -> Firestore medications + medication_reports
  -> StreamBuilder يعيد بناء الواجهة
  -> التقرير والتقويم يعرضان الحالة الجديدة
```

إذا أردت فهم أي ميزة، اسأل نفسك:

1. ما الشاشة التي تعرضها؟
2. ما الخدمة التي تستدعيها؟
3. ما مجموعة Firestore التي تتأثر؟
4. ما النموذج الذي يحول البيانات؟
5. هل يوجد إشعار مرتبط؟
6. هل قواعد Firestore تسمح بالعملية؟

بهذه الطريقة ستفهم المشروع بسرعة وبدون ضياع بين الملفات.

