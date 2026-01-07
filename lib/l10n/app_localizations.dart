import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @accountEmailPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'email@example.com'**
  String get accountEmailPlaceholder;

  /// No description provided for @accountNamePlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'عميل دفــا'**
  String get accountNamePlaceholder;

  /// No description provided for @accountServiceSettings.
  ///
  /// In ar, this message translates to:
  /// **'⚙️ الإعدادات'**
  String get accountServiceSettings;

  /// No description provided for @accountServiceSupportHelp.
  ///
  /// In ar, this message translates to:
  /// **'💬 الدعم والمساعدة'**
  String get accountServiceSupportHelp;

  /// No description provided for @accountServicesTitle.
  ///
  /// In ar, this message translates to:
  /// **'خدمات حسابي 🚀'**
  String get accountServicesTitle;

  /// No description provided for @accountStandardLabel.
  ///
  /// In ar, this message translates to:
  /// **'عميل'**
  String get accountStandardLabel;

  /// No description provided for @accountTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get accountTitle;

  /// No description provided for @activeCurrencyLabel.
  ///
  /// In ar, this message translates to:
  /// **'العملة النشطة'**
  String get activeCurrencyLabel;

  /// No description provided for @addPaymentMethod.
  ///
  /// In ar, this message translates to:
  /// **'إضافة وسيلة دفع جديدة'**
  String get addPaymentMethod;

  /// No description provided for @additionalInfoLabel.
  ///
  /// In ar, this message translates to:
  /// **'معلومات إضافية'**
  String get additionalInfoLabel;

  /// No description provided for @address_line1.
  ///
  /// In ar, this message translates to:
  /// **'العنوان (سطر 1)'**
  String get address_line1;

  /// No description provided for @address_line2_optional.
  ///
  /// In ar, this message translates to:
  /// **'العنوان (سطر 2) اختياري'**
  String get address_line2_optional;

  /// No description provided for @appPrefsSection.
  ///
  /// In ar, this message translates to:
  /// **'تفضيلات التطبيق'**
  String get appPrefsSection;

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'متجر دفــا'**
  String get appTitle;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @bank_ref_label.
  ///
  /// In ar, this message translates to:
  /// **'رقم الحوالة / المرجع'**
  String get bank_ref_label;

  /// No description provided for @bank_ref_required_msg.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم الحوالة/المرجع للتحويل البنكي'**
  String get bank_ref_required_msg;

  /// No description provided for @bank_transfer_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'ادخل رقم الحوالة/المرجع بعد التحويل.'**
  String get bank_transfer_subtitle;

  /// No description provided for @bank_transfer_title.
  ///
  /// In ar, this message translates to:
  /// **'تحويل بنكي'**
  String get bank_transfer_title;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @cancelOrderNowButton.
  ///
  /// In ar, this message translates to:
  /// **'🚫 إلغاء الطلب الآن'**
  String get cancelOrderNowButton;

  /// No description provided for @cancel_button.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel_button;

  /// No description provided for @cart_empty.
  ///
  /// In ar, this message translates to:
  /// **'السلة فارغة'**
  String get cart_empty;

  /// No description provided for @changesSaved.
  ///
  /// In ar, this message translates to:
  /// **'✅ تم حفظ التغييرات بنجاح'**
  String get changesSaved;

  /// No description provided for @chatTypeOrder.
  ///
  /// In ar, this message translates to:
  /// **'🧾 طلب'**
  String get chatTypeOrder;

  /// No description provided for @chatTypeProduct.
  ///
  /// In ar, this message translates to:
  /// **'🛍️ منتج'**
  String get chatTypeProduct;

  /// No description provided for @checkout_title.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الطلب'**
  String get checkout_title;

  /// No description provided for @chooseLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اختر اللغة'**
  String get chooseLanguage;

  /// No description provided for @choose_payment_method.
  ///
  /// In ar, this message translates to:
  /// **'اختر طريقة الدفع'**
  String get choose_payment_method;

  /// No description provided for @choose_save_location.
  ///
  /// In ar, this message translates to:
  /// **'اختر مكان الحفظ'**
  String get choose_save_location;

  /// No description provided for @city.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get city;

  /// No description provided for @cod_subtitle.
  ///
  /// In ar, this message translates to:
  /// **'يتم الدفع عند استلام الخدمة/المنتج.'**
  String get cod_subtitle;

  /// No description provided for @cod_title.
  ///
  /// In ar, this message translates to:
  /// **'الدفع عند الاستلام'**
  String get cod_title;

  /// No description provided for @complete_order_button.
  ///
  /// In ar, this message translates to:
  /// **'إتمام الطلب'**
  String get complete_order_button;

  /// No description provided for @confirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPassword;

  /// No description provided for @confirm_order_button.
  ///
  /// In ar, this message translates to:
  /// **'متابعة وتأكيد الطلب'**
  String get confirm_order_button;

  /// No description provided for @createAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get createAccount;

  /// No description provided for @create_button.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get create_button;

  /// No description provided for @currencySettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات العملة'**
  String get currencySettingsTitle;

  /// No description provided for @currency_EUR.
  ///
  /// In ar, this message translates to:
  /// **'يورو'**
  String get currency_EUR;

  /// No description provided for @currency_SAR.
  ///
  /// In ar, this message translates to:
  /// **'ريال سعودي'**
  String get currency_SAR;

  /// No description provided for @currency_USD.
  ///
  /// In ar, this message translates to:
  /// **'دولار'**
  String get currency_USD;

  /// No description provided for @customerAttachmentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرفقاتك:'**
  String get customerAttachmentsTitle;

  /// No description provided for @customerEmailLabelFancy.
  ///
  /// In ar, this message translates to:
  /// **'✉️ الإيميل'**
  String get customerEmailLabelFancy;

  /// No description provided for @customerNameLabelFancy.
  ///
  /// In ar, this message translates to:
  /// **'🧑 الاسم'**
  String get customerNameLabelFancy;

  /// No description provided for @customerPhoneLabelFancy.
  ///
  /// In ar, this message translates to:
  /// **'📱 الجوال'**
  String get customerPhoneLabelFancy;

  /// No description provided for @customer_data.
  ///
  /// In ar, this message translates to:
  /// **'بيانات العميل'**
  String get customer_data;

  /// No description provided for @customer_label.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get customer_label;

  /// No description provided for @dateNotSpecified.
  ///
  /// In ar, this message translates to:
  /// **'---'**
  String get dateNotSpecified;

  /// No description provided for @defaultUserName.
  ///
  /// In ar, this message translates to:
  /// **'عميل دفــا'**
  String get defaultUserName;

  /// No description provided for @default_customer_name.
  ///
  /// In ar, this message translates to:
  /// **'عميل'**
  String get default_customer_name;

  /// No description provided for @delete_action.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete_action;

  /// No description provided for @delete_button.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete_button;

  /// No description provided for @delete_notification.
  ///
  /// In ar, this message translates to:
  /// **'حذف الإشعار'**
  String get delete_notification;

  /// No description provided for @downloadLabel.
  ///
  /// In ar, this message translates to:
  /// **'تحميل'**
  String get downloadLabel;

  /// No description provided for @editProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف الشخصي ✨'**
  String get editProfileTitle;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In ar, this message translates to:
  /// **'سيتم إرسال رابط تأكيد عند التغيير'**
  String get emailHint;

  /// No description provided for @emailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailLabel;

  /// No description provided for @emailUpdateError.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تحديث الإيميل. قد تحتاج لتسجيل الدخول مجدداً.'**
  String get emailUpdateError;

  /// No description provided for @emailVerificationSent.
  ///
  /// In ar, this message translates to:
  /// **'📨 تم إرسال رابط تأكيد إلى بريدك الإلكتروني.'**
  String get emailVerificationSent;

  /// No description provided for @email_label.
  ///
  /// In ar, this message translates to:
  /// **'الإيميل'**
  String get email_label;

  /// No description provided for @errorOccurred.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get errorOccurred;

  /// No description provided for @error_generic.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ: {error}'**
  String error_generic(Object error);

  /// No description provided for @exchangeRateLabel.
  ///
  /// In ar, this message translates to:
  /// **'سعر الصرف'**
  String get exchangeRateLabel;

  /// No description provided for @file_not_found_local.
  ///
  /// In ar, this message translates to:
  /// **'الملف غير موجود على الجهاز'**
  String get file_not_found_local;

  /// No description provided for @file_saved_uploaded_msg.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الملف ورفعه تلقائيًا'**
  String get file_saved_uploaded_msg;

  /// No description provided for @filterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get filterAll;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @fullNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullNameLabel;

  /// No description provided for @genericProduct.
  ///
  /// In ar, this message translates to:
  /// **'منتج'**
  String get genericProduct;

  /// No description provided for @homeHeaderTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك في دفــا ✨'**
  String get homeHeaderTitle;

  /// No description provided for @homeTitle.
  ///
  /// In ar, this message translates to:
  /// **'دفــا'**
  String get homeTitle;

  /// No description provided for @invalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'صيغة البريد غير صحيحة'**
  String get invalidEmail;

  /// No description provided for @kindProduct.
  ///
  /// In ar, this message translates to:
  /// **'منتج'**
  String get kindProduct;

  /// No description provided for @languageLabel.
  ///
  /// In ar, this message translates to:
  /// **'لغة التطبيق'**
  String get languageLabel;

  /// No description provided for @loadingOrderData.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل بيانات الطلب...'**
  String get loadingOrderData;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @loginWelcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا بك في دفــا'**
  String get loginWelcome;

  /// No description provided for @loginWithGoogle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول باستخدام Google'**
  String get loginWithGoogle;

  /// No description provided for @login_required_content.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن متابعة الدفع إلا بعد تسجيل الدخول.'**
  String get login_required_content;

  /// No description provided for @login_required_title.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول مطلوب'**
  String get login_required_title;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @mark_all_read.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل كمقروء'**
  String get mark_all_read;

  /// No description provided for @monthLabel.
  ///
  /// In ar, this message translates to:
  /// **'شهر'**
  String get monthLabel;

  /// No description provided for @mostPopularLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر طلباً'**
  String get mostPopularLabel;

  /// No description provided for @nameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get nameLabel;

  /// No description provided for @nameShort.
  ///
  /// In ar, this message translates to:
  /// **'الاسم قصير جدًا'**
  String get nameShort;

  /// No description provided for @name_label.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name_label;

  /// No description provided for @navAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get navAccount;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get navOrders;

  /// No description provided for @navStore.
  ///
  /// In ar, this message translates to:
  /// **'المتجر'**
  String get navStore;

  /// No description provided for @new_name_label.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الجديد'**
  String get new_name_label;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @noAccount.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get noAccount;

  /// No description provided for @no_notifications_yet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات حالياً'**
  String get no_notifications_yet;

  /// No description provided for @notAvailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر'**
  String get notAvailable;

  /// No description provided for @noteLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات إضافية'**
  String get noteLabel;

  /// No description provided for @noteOrFileRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى كتابة ملاحظة أو اختيار ملف قبل الإرسال.'**
  String get noteOrFileRequired;

  /// No description provided for @notes_hint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب أي ملاحظات إضافية للطلب...'**
  String get notes_hint;

  /// No description provided for @notes_label.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get notes_label;

  /// No description provided for @notif_chat_attachment_body.
  ///
  /// In ar, this message translates to:
  /// **'📎 مرفق جديد'**
  String get notif_chat_attachment_body;

  /// No description provided for @notif_chat_order_reply_prefix.
  ///
  /// In ar, this message translates to:
  /// **'رد جديد على الطلب #'**
  String get notif_chat_order_reply_prefix;

  /// No description provided for @notif_chat_support_title.
  ///
  /// In ar, this message translates to:
  /// **'رسالة جديدة من الدعم الفني 💬'**
  String get notif_chat_support_title;

  /// No description provided for @notif_order_status_changed_body.
  ///
  /// In ar, this message translates to:
  /// **'تغيرت حالة الطلب رقم {number} إلى: {status}'**
  String notif_order_status_changed_body(Object number, Object status);

  /// No description provided for @notif_order_update_title.
  ///
  /// In ar, this message translates to:
  /// **'تحديث حالة الطلب ✅'**
  String get notif_order_update_title;

  /// No description provided for @notification_new_badge.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get notification_new_badge;

  /// No description provided for @notification_time_now.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get notification_time_now;

  /// No description provided for @notifications_title.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications_title;

  /// No description provided for @openDetailsArrow.
  ///
  /// In ar, this message translates to:
  /// **'عرض التفاصيل ←'**
  String get openDetailsArrow;

  /// No description provided for @or.
  ///
  /// In ar, this message translates to:
  /// **'أو'**
  String get or;

  /// No description provided for @orderCancelSnack.
  ///
  /// In ar, this message translates to:
  /// **'✅ تم إلغاء الطلب'**
  String get orderCancelSnack;

  /// No description provided for @orderChatButton.
  ///
  /// In ar, this message translates to:
  /// **'💬 دردشة حول طلب #{orderNumber}'**
  String orderChatButton(Object orderNumber);

  /// No description provided for @orderCustomerInfoTitleFancy.
  ///
  /// In ar, this message translates to:
  /// **'👤 بيانات العميل'**
  String get orderCustomerInfoTitleFancy;

  /// No description provided for @orderDetailsAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'🧾 تفاصيل الطلب'**
  String get orderDetailsAppBarTitle;

  /// No description provided for @orderDetailsHeaderTitle.
  ///
  /// In ar, this message translates to:
  /// **'📦 طلبك جاهز للمتابعة'**
  String get orderDetailsHeaderTitle;

  /// No description provided for @orderDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get orderDetailsTitle;

  /// No description provided for @orderItemsTitleFancy.
  ///
  /// In ar, this message translates to:
  /// **'🧺 العناصر'**
  String get orderItemsTitleFancy;

  /// No description provided for @orderLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الطلب'**
  String get orderLoadFailed;

  /// No description provided for @orderNotesTitleFancy.
  ///
  /// In ar, this message translates to:
  /// **'📝 ملاحظات'**
  String get orderNotesTitleFancy;

  /// No description provided for @orderNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الطلب'**
  String get orderNumberLabel;

  /// No description provided for @orderNumberPrefix.
  ///
  /// In ar, this message translates to:
  /// **'رقم الطلب: {number}'**
  String orderNumberPrefix(Object number);

  /// No description provided for @orderStatusCanceled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get orderStatusCanceled;

  /// No description provided for @orderStatusDone.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get orderStatusDone;

  /// No description provided for @orderStatusInProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get orderStatusInProgress;

  /// No description provided for @orderStatusLabel.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب'**
  String get orderStatusLabel;

  /// No description provided for @orderStatusNew.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get orderStatusNew;

  /// No description provided for @orderStatusUnknown.
  ///
  /// In ar, this message translates to:
  /// **'غير معروف'**
  String get orderStatusUnknown;

  /// No description provided for @orderThanksFooterShort.
  ///
  /// In ar, this message translates to:
  /// **'💎 شكراً لثقتك بمتجر دفــــا — نحن هنا لخدمتك.'**
  String get orderThanksFooterShort;

  /// No description provided for @orderTotalHiddenSpecial.
  ///
  /// In ar, this message translates to:
  /// **'🔒 هذا الطلب بنظام خاص — لا يظهر الإجمالي هنا.'**
  String get orderTotalHiddenSpecial;

  /// No description provided for @orderTotalLabelFancy.
  ///
  /// In ar, this message translates to:
  /// **'💰 الإجمالي'**
  String get orderTotalLabelFancy;

  /// No description provided for @orderTypeGeneric.
  ///
  /// In ar, this message translates to:
  /// **'طلب عام'**
  String get orderTypeGeneric;

  /// No description provided for @orderTypeLabelFancy.
  ///
  /// In ar, this message translates to:
  /// **'🧩 نوع الطلب'**
  String get orderTypeLabelFancy;

  /// No description provided for @orderTypeProduct.
  ///
  /// In ar, this message translates to:
  /// **'منتج'**
  String get orderTypeProduct;

  /// No description provided for @orderTypeService.
  ///
  /// In ar, this message translates to:
  /// **'خدمة'**
  String get orderTypeService;

  /// No description provided for @order_confirm_page_review_msg.
  ///
  /// In ar, this message translates to:
  /// **'راجع بيانات طلبك قبل المتابعة للدفع'**
  String get order_confirm_page_review_msg;

  /// No description provided for @order_failed_msg.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء إنشاء الطلب'**
  String get order_failed_msg;

  /// No description provided for @order_failed_title.
  ///
  /// In ar, this message translates to:
  /// **'لم تكتمل العملية ⚠️'**
  String get order_failed_title;

  /// No description provided for @order_success_msg.
  ///
  /// In ar, this message translates to:
  /// **'شكرًا لثقتك في دفــا'**
  String get order_success_msg;

  /// No description provided for @order_success_title.
  ///
  /// In ar, this message translates to:
  /// **'تم إتمام الطلب بنجاح 🎉'**
  String get order_success_title;

  /// No description provided for @order_summary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الطلب'**
  String get order_summary;

  /// No description provided for @ordersDetailsLabel.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل'**
  String get ordersDetailsLabel;

  /// No description provided for @ordersEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد طلبات حالياً'**
  String get ordersEmpty;

  /// No description provided for @ordersIndexFallback.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل الوضع الاحتياطي تلقائيًا — أعد فتح الصفحة.'**
  String get ordersIndexFallback;

  /// No description provided for @ordersIndexRequired.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات غير ظاهرة لأن Firestore يتطلب إنشاء فهرس.'**
  String get ordersIndexRequired;

  /// No description provided for @ordersLoadError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تحميل الطلبات'**
  String get ordersLoadError;

  /// No description provided for @ordersLoginRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تسجيل الدخول لعرض الطلبات'**
  String get ordersLoginRequired;

  /// No description provided for @ordersTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get ordersTitle;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @passwordNotMatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get passwordNotMatch;

  /// No description provided for @paymentSection.
  ///
  /// In ar, this message translates to:
  /// **'الدفع والاشتراكات'**
  String get paymentSection;

  /// No description provided for @payment_title.
  ///
  /// In ar, this message translates to:
  /// **'الدفع'**
  String get payment_title;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneLabel;

  /// No description provided for @phone_is_required_msg.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف إلزامي'**
  String get phone_is_required_msg;

  /// No description provided for @phone_number.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجوال'**
  String get phone_number;

  /// No description provided for @phone_required_label.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف (إلزامي)'**
  String get phone_required_label;

  /// No description provided for @pick_file_tooltip.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ملف'**
  String get pick_file_tooltip;

  /// No description provided for @please_login_first.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء تسجيل الدخول أولاً'**
  String get please_login_first;

  /// No description provided for @proceed_to_payment.
  ///
  /// In ar, this message translates to:
  /// **'متابعة إلى الدفع'**
  String get proceed_to_payment;

  /// No description provided for @productDescriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'وصف المنتج'**
  String get productDescriptionLabel;

  /// No description provided for @productKindLabel.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get productKindLabel;

  /// No description provided for @products_label.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get products_label;

  /// No description provided for @profileSection.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profileSection;

  /// No description provided for @registerHint.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حسابك لبدء التسوق في دفــا'**
  String get registerHint;

  /// No description provided for @registerNow.
  ///
  /// In ar, this message translates to:
  /// **'سجل الآن'**
  String get registerNow;

  /// No description provided for @rename_action.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تسمية'**
  String get rename_action;

  /// No description provided for @rename_folder_title.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تسمية مجلد'**
  String get rename_folder_title;

  /// No description provided for @reorderSameItemsButton.
  ///
  /// In ar, this message translates to:
  /// **'🔁 إعادة طلب نفس العناصر'**
  String get reorderSameItemsButton;

  /// No description provided for @retry_button.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry_button;

  /// No description provided for @return_to_home.
  ///
  /// In ar, this message translates to:
  /// **'العودة للرئيسية'**
  String get return_to_home;

  /// No description provided for @root_folder_name.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get root_folder_name;

  /// No description provided for @routeNotLinked.
  ///
  /// In ar, this message translates to:
  /// **'هذه الصفحة غير مرتبطة بالتطبيق حاليًا.'**
  String get routeNotLinked;

  /// No description provided for @saveChanges.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التغييرات'**
  String get saveChanges;

  /// No description provided for @save_as_image.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كصورة (JPEG)'**
  String get save_as_image;

  /// No description provided for @save_button.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save_button;

  /// No description provided for @save_in_current_folder.
  ///
  /// In ar, this message translates to:
  /// **'حفظ داخل المجلد الحالي'**
  String get save_in_current_folder;

  /// No description provided for @sendError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الإرسال'**
  String get sendError;

  /// No description provided for @sendRequest.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get sendRequest;

  /// No description provided for @serviceTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الخدمة'**
  String get serviceTitleLabel;

  /// No description provided for @serviceTitleRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى كتابة عنوان الخدمة المطلوبة'**
  String get serviceTitleRequired;

  /// No description provided for @servicesTitle.
  ///
  /// In ar, this message translates to:
  /// **'خدماتنا المتكاملة'**
  String get servicesTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @share_action.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share_action;

  /// No description provided for @shipping_address.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الشحن'**
  String get shipping_address;

  /// No description provided for @shortPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور قصيرة جدًا'**
  String get shortPassword;

  /// No description provided for @skip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get skip;

  /// No description provided for @sliderBadgeImage.
  ///
  /// In ar, this message translates to:
  /// **'🖼️ صورة'**
  String get sliderBadgeImage;

  /// No description provided for @sliderBadgeLink.
  ///
  /// In ar, this message translates to:
  /// **'🔗 رابط'**
  String get sliderBadgeLink;

  /// No description provided for @sliderBadgeProduct.
  ///
  /// In ar, this message translates to:
  /// **'🛒 منتج'**
  String get sliderBadgeProduct;

  /// No description provided for @specialTitle.
  ///
  /// In ar, this message translates to:
  /// **'دفــا سبيشل'**
  String get specialTitle;

  /// No description provided for @startNow.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get startNow;

  /// No description provided for @stepConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'التأكيد'**
  String get stepConfirmation;

  /// No description provided for @stepPayment.
  ///
  /// In ar, this message translates to:
  /// **'الدفع'**
  String get stepPayment;

  /// No description provided for @stepProduct.
  ///
  /// In ar, this message translates to:
  /// **'المنتج'**
  String get stepProduct;

  /// No description provided for @storeContactUs.
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا'**
  String get storeContactUs;

  /// No description provided for @storeEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات متاحة حاليًا'**
  String get storeEmpty;

  /// No description provided for @storeLoadError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تحميل المنتجات'**
  String get storeLoadError;

  /// No description provided for @storeOrderNow.
  ///
  /// In ar, this message translates to:
  /// **'اطلب الآن'**
  String get storeOrderNow;

  /// No description provided for @storeSubscribeNow.
  ///
  /// In ar, this message translates to:
  /// **'اشترك الآن'**
  String get storeSubscribeNow;

  /// No description provided for @storeTitle.
  ///
  /// In ar, this message translates to:
  /// **'المتجر'**
  String get storeTitle;

  /// No description provided for @success_badge.
  ///
  /// In ar, this message translates to:
  /// **'تم بنجاح 🥳'**
  String get success_badge;

  /// No description provided for @tapToOpenLabel.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للفتح'**
  String get tapToOpenLabel;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get total;

  /// No description provided for @totalAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ الإجمالي'**
  String get totalAmount;

  /// No description provided for @total_items_count.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي ({count} عناصر)'**
  String total_items_count(Object count);

  /// No description provided for @upload_to_cloud.
  ///
  /// In ar, this message translates to:
  /// **'رفع للسحابة'**
  String get upload_to_cloud;

  /// No description provided for @viewDetails.
  ///
  /// In ar, this message translates to:
  /// **'عرض التفاصيل'**
  String get viewDetails;

  /// No description provided for @view_order.
  ///
  /// In ar, this message translates to:
  /// **'عرض الطلب'**
  String get view_order;

  /// No description provided for @zip_code.
  ///
  /// In ar, this message translates to:
  /// **'الرمز البريدي'**
  String get zip_code;

  /// No description provided for @onboardingWelcomeDesc.
  ///
  /// In ar, this message translates to:
  /// **'متجر دفــا وجهتك المختارة للفخامة والجودة — منتجات منتقاة بعناية، تفاصيل راقية، وتجربة تسوق تليق بذوقك من أول خطوة.'**
  String get onboardingWelcomeDesc;

  /// No description provided for @onboardingFeaturesTitle.
  ///
  /// In ar, this message translates to:
  /// **'لماذا متجر دفــا؟'**
  String get onboardingFeaturesTitle;

  /// No description provided for @onboardingFeature1Title.
  ///
  /// In ar, this message translates to:
  /// **'منتجات فاخرة'**
  String get onboardingFeature1Title;

  /// No description provided for @onboardingFeature1Desc.
  ///
  /// In ar, this message translates to:
  /// **'تشكيلة منتقاة بعناية تجمع بين الأناقة، الذوق الرفيع، والجودة العالية.'**
  String get onboardingFeature1Desc;

  /// No description provided for @onboardingFeature2Title.
  ///
  /// In ar, this message translates to:
  /// **'جودة موثوقة'**
  String get onboardingFeature2Title;

  /// No description provided for @onboardingFeature2Desc.
  ///
  /// In ar, this message translates to:
  /// **'وصف دقيق، صور واضحة، ومعايير جودة نلتزم بها في كل منتج.'**
  String get onboardingFeature2Desc;

  /// No description provided for @onboardingFeature3Title.
  ///
  /// In ar, this message translates to:
  /// **'عروض حصرية'**
  String get onboardingFeature3Title;

  /// No description provided for @onboardingFeature3Desc.
  ///
  /// In ar, this message translates to:
  /// **'عروض موسمية ومفاجآت مميزة مصممة لعملاء دفــا.'**
  String get onboardingFeature3Desc;

  /// No description provided for @onboardingFeature4Title.
  ///
  /// In ar, this message translates to:
  /// **'طلب سهل وسريع'**
  String get onboardingFeature4Title;

  /// No description provided for @onboardingFeature4Desc.
  ///
  /// In ar, this message translates to:
  /// **'عملية شراء سلسة بخطوات بسيطة ومتابعة طلباتك بكل وضوح.'**
  String get onboardingFeature4Desc;

  /// No description provided for @onboardingFeature5Title.
  ///
  /// In ar, this message translates to:
  /// **'دعم متجاوب'**
  String get onboardingFeature5Title;

  /// No description provided for @onboardingFeature5Desc.
  ///
  /// In ar, this message translates to:
  /// **'فريق دعم جاهز للتواصل معك وتقديم المساعدة في أي وقت.'**
  String get onboardingFeature5Desc;

  /// No description provided for @editProfile.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف الشخصي'**
  String get editProfile;

  /// No description provided for @services.
  ///
  /// In ar, this message translates to:
  /// **'الخدمات'**
  String get services;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// No description provided for @profileSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة معلومات حسابك'**
  String get profileSubtitle;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @settingsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اللغة والإشعارات والخصوصية'**
  String get settingsSubtitle;

  /// No description provided for @support.
  ///
  /// In ar, this message translates to:
  /// **'الدعم'**
  String get support;

  /// No description provided for @supportSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا عبر الدردشة'**
  String get supportSubtitle;

  /// No description provided for @accountVipLabel.
  ///
  /// In ar, this message translates to:
  /// **'عميل مميز'**
  String get accountVipLabel;

  /// No description provided for @invalidPhoneError.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف غير صحيح'**
  String get invalidPhoneError;

  /// No description provided for @onboardingSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get onboardingNext;

  /// No description provided for @onboardingStartShopping.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التسوق'**
  String get onboardingStartShopping;

  /// No description provided for @onboardingChooseLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اختر اللغة'**
  String get onboardingChooseLanguage;

  /// No description provided for @onboardingChooseLanguageHint.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تغيير اللغة لاحقًا من الإعدادات'**
  String get onboardingChooseLanguageHint;

  /// No description provided for @onboardingArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get onboardingArabic;

  /// No description provided for @onboardingEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get onboardingEnglish;

  /// No description provided for @onboardingDefaTitle.
  ///
  /// In ar, this message translates to:
  /// **'دِفــــا — حيث يبدأ الذوق الرفيع'**
  String get onboardingDefaTitle;

  /// No description provided for @onboardingDefaSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'قطع راقية بروح شرقية…\nتفاصيل ذهبية تُكمل حضورك وتُبهج من تحب'**
  String get onboardingDefaSubtitle;

  /// No description provided for @onboardingShowcaseTitle.
  ///
  /// In ar, this message translates to:
  /// **'مختارات دِفــــا الراقية'**
  String get onboardingShowcaseTitle;

  /// No description provided for @onboardingShowcaseDesc.
  ///
  /// In ar, this message translates to:
  /// **'هدايا تُدهش، إكسسوارات بلمسة فخامة، خواتم عقيق فاخر،\nومباخر ومنحوتات تروي حكاية ذوق'**
  String get onboardingShowcaseDesc;

  /// No description provided for @onboardingCatGifts.
  ///
  /// In ar, this message translates to:
  /// **'هدايا تُدهش'**
  String get onboardingCatGifts;

  /// No description provided for @onboardingCatAccessories.
  ///
  /// In ar, this message translates to:
  /// **'إكسسوارات فاخرة'**
  String get onboardingCatAccessories;

  /// No description provided for @onboardingCatAgate.
  ///
  /// In ar, this message translates to:
  /// **'خواتم العقيق'**
  String get onboardingCatAgate;

  /// No description provided for @onboardingCatIncense.
  ///
  /// In ar, this message translates to:
  /// **'مباخر وتحف'**
  String get onboardingCatIncense;

  /// No description provided for @checkout_step_product.
  ///
  /// In ar, this message translates to:
  /// **'المنتج'**
  String get checkout_step_product;

  /// No description provided for @checkout_step_confirm.
  ///
  /// In ar, this message translates to:
  /// **'التأكيد'**
  String get checkout_step_confirm;

  /// No description provided for @checkout_step_payment.
  ///
  /// In ar, this message translates to:
  /// **'الدفع'**
  String get checkout_step_payment;

  /// No description provided for @checkout_status_new.
  ///
  /// In ar, this message translates to:
  /// **'طلب جديد'**
  String get checkout_status_new;

  /// No description provided for @checkout_status_pending.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get checkout_status_pending;

  /// No description provided for @checkout_status_canceled.
  ///
  /// In ar, this message translates to:
  /// **'تم الإلغاء'**
  String get checkout_status_canceled;

  /// No description provided for @checkout_process_title.
  ///
  /// In ar, this message translates to:
  /// **'مراحل إتمام الطلب'**
  String get checkout_process_title;

  /// No description provided for @checkout_secure_connection.
  ///
  /// In ar, this message translates to:
  /// **'جاري تأمين اتصالك ببوابة الدفع الفاخرة...'**
  String get checkout_secure_connection;

  /// No description provided for @checkout_review_basket.
  ///
  /// In ar, this message translates to:
  /// **'جاري مراجعة سلة مشتريات دِفا الرسمية...'**
  String get checkout_review_basket;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
