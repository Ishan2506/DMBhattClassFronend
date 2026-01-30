import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(Localizations.localeOf(context));
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'dashboard': 'Dashboard',
      'explore': 'Explore',
      'dmai': 'DMAI',
      'more': 'More',
      'home': 'Home',
      'daily_time_table': 'Daily Time Table',
      'start_exam': 'START EXAM',
      'next_exam_waiting': 'Your next exam is waiting for you.',
      'reports': 'Reports',
      'settings': 'Settings',
      'theme_mode': 'Theme Mode',
      'language': 'Language',
      'sign_out': 'Sign Out',
      'profile': 'Profile',
      'academic_performance': 'Academic Performance',
      'total_reward_points': 'Total Reward Points',
      'welcome_student': 'Welcome, Student!',
      'ready_to_test': 'Ready to test your knowledge?',
      'subject': 'Subject',
      'select_subject': 'Select Subject',
      'marks': 'Marks',
      'select_marks': 'Select Marks',
      'start_new_exam': 'Start a New Exam',
      'unit': 'Unit',
      'select_unit': 'Select Unit',
      'exam_instructions': 'Exam Instructions',
      'instruction1': 'Each question has 4 multiple-choice options.',
      'instruction2': 'You must select only one option per question.',
      'instruction3': 'Each correct answer is worth 1 mark.',
      'instruction4': 'There is no penalty for incorrect answers.',
      'instruction5': 'You have 5 minutes to answer each question.',
      'all_the_best': 'All the best!',
      'proceed_to_exam': 'Proceed to Exam',
      'question': 'Question',
      'next': 'Next',
      'previous': 'Previous',
      'submit': 'Submit',
      'skip': 'Skip',
      'login': 'Login',
      'password': 'Password',
      'email': 'Email',
      'forgot_dpin': 'Forgot D-PIN?',
      'dpin': 'D-PIN',
      'register': 'Register',
      'first_name': 'First Name',
      'middle_name': 'Middle Name',
      'last_name': 'Last Name',
      'full_name': 'Full Name',
      'phone_number': 'Phone Number',
      'std': 'STD',
      'medium': 'Medium',
      'school': 'School',
      'address': 'Address',
      'already_have_account': 'Already have an account?',
      'dont_have_account': "Don't have an account?",
      'welcome_to_dm_bhatt': 'Welcome to DM Bhatt Classes',
      'academic_path': 'Your path to academic excellence starts here.',
      'register_guest': 'Register as a guest',
      'guest_registration': 'Guest Registration',
      'welcome_guest': 'Welcome Guest',
      'dont_worry': "Don't worry,",
      'forgot_password_header': 'Forgot Password',
      'forgot_password_subtext': 'Please enter the phone number associated with your account.',
      'enter_phone_hint': 'Enter your registered phone number',
      'send_otp': 'Send OTP',
      'sending_otp': 'Sending OTP...',
      'hey_there': 'Hey there,',
      'welcome_back': 'Welcome Back',
      'forgot_password_question': 'Forgot your password?',
      'name': 'Name',
      'roll_number': 'Roll Number',
      'parent_phone': "Parent's Mobile Number",
      'standard': 'Standard',
      'stream': 'Stream',
      'state': 'State',
      'city': 'City',
      'school_name': 'School Name',
      'agree_terms': 'I agree with ',
      'terms_conditions': 'Terms and Conditions',
    },
    'hi': {
      'dashboard': 'डैशबोर्ड',
      'explore': 'खोजें',
      'dmai': 'डीएम एआई',
      'more': 'अधिक',
      'home': 'होम',
      'daily_time_table': 'दैनिक समय सारिणी',
      'start_exam': 'परीक्षा शुरू करें',
      'next_exam_waiting': 'आपकी अगली परीक्षा आपका इंतजार कर रही है।',
      'reports': 'रिपोर्ट',
      'settings': 'सेटिंग्स',
      'theme_mode': 'थीम मोड',
      'language': 'भाषा',
      'sign_out': 'साइन आउट',
      'profile': 'प्रोफ़ाइल',
      'academic_performance': 'शैक्षणिक प्रदर्शन',
      'total_reward_points': 'कुल इनाम अंक',
      'welcome_student': 'स्वागत है, विद्यार्थी!',
      'ready_to_test': 'क्या आप अपने ज्ञान का परीक्षण करने के लिए तैयार हैं?',
      'subject': 'विषय',
      'select_subject': 'विषय चुनें',
      'marks': 'अंक',
      'select_marks': 'अंक चुनें',
      'start_new_exam': 'नई परीक्षा शुरू करें',
      'unit': 'इकाई',
      'select_unit': 'इकाई चुनें',
      'exam_instructions': 'परीक्षा निर्देश',
      'instruction1': 'प्रत्येक प्रश्न में 4 बहुविकल्पीय विकल्प हैं।',
      'instruction2': 'आपको प्रति प्रश्न केवल एक विकल्प चुनना होगा।',
      'instruction3': 'प्रत्येक सही उत्तर 1 अंक का है।',
      'instruction4': 'गलत उत्तरों के लिए कोई नकारात्मक अंकन नहीं है।',
      'instruction5': 'प्रत्येक प्रश्न का उत्तर देने के लिए आपके पास 5 मिनट हैं।',
      'all_the_best': 'शुभकामनाएं!',
      'proceed_to_exam': 'परीक्षा के लिए आगे बढ़ें',
      'question': 'प्रश्न',
      'next': 'अगला',
      'previous': 'पिछला',
      'submit': 'जमा करें',
      'skip': 'छोड़ें',
      'login': 'लॉगिन',
      'password': 'पासवर्ड',
      'email': 'ईमेल',
      'forgot_dpin': 'डी-पिन भूल गए?',
      'dpin': 'डी-पिन',
      'register': 'पंजीकरण करें',
      'first_name': 'पहला नाम',
      'middle_name': 'मध्य नाम',
      'last_name': 'अंतिम नाम',
      'full_name': 'पूरा नाम',
      'phone_number': 'फ़ोन नंबर',
      'std': 'कक्षा',
      'medium': 'माध्यम',
      'school': 'स्कूल',
      'address': 'पता',
      'already_have_account': 'क्या आपके पास पहले से खाता है?',
      'dont_have_account': "क्या आपके पास खाता नहीं है?",
      'welcome_to_dm_bhatt': 'डीएम भट्ट क्लासेस में आपका स्वागत है',
      'academic_path': 'शैक्षणिक उत्कृष्टता की आपकी राह यहीं से शुरू होती है।',
      'register_guest': 'अतिथि के रूप में पंजीकरण करें',
      'guest_registration': 'अतिथि पंजीकरण',
      'welcome_guest': 'अतिथि का स्वागत है',
      'dont_worry': 'चिंता न करें,',
      'forgot_password_header': 'पासवर्ड भूल गए',
      'forgot_password_subtext': 'कृपया अपने खाते से जुड़ा फोन नंबर दर्ज करें।',
      'enter_phone_hint': 'अपना पंजीकृत फोन नंबर दर्ज करें',
      'send_otp': 'ओटीपी भेजें',
      'sending_otp': 'ओटीपी भेज रहे हैं...',
      'hey_there': 'नमस्ते,',
      'welcome_back': 'वापसी पर स्वागत है',
      'forgot_password_question': 'अपना पासवर्ड भूल गए?',
      'name': 'नाम',
      'roll_number': 'रोल नंबर',
      'parent_phone': "माता-पिता का मोबाइल नंबर",
      'standard': 'कक्षा',
      'stream': 'स्ट्रीम',
      'state': 'राज्य',
      'city': 'शहर',
      'school_name': 'स्कूल का नाम',
      'agree_terms': 'मैं सहमत हूँ ',
      'terms_conditions': 'नियम और शर्तें',
    },
    'gu': {
      'dashboard': 'ડેશબોર્ડ',
      'explore': 'અન્વેષણ',
      'dmai': 'ડીએમ એઆઈ',
      'more': 'વધુ',
      'home': 'હોમ',
      'daily_time_table': 'દૈનિક સમયપત્રક',
      'start_exam': 'પરીક્ષા શરૂ કરો',
      'next_exam_waiting': 'તમારી આગામી પરીક્ષા તમારી રાહ જોઈ રહી છે.',
      'reports': 'અહેવાલો',
      'settings': 'સેટિંગ્સ',
      'theme_mode': 'થીમ મોડ',
      'language': 'ભાષા',
      'sign_out': 'સાઇન આઉટ',
      'profile': 'પ્રોફાઇલ',
      'academic_performance': 'શૈક્ષણિક પ્રદર્શન',
      'total_reward_points': 'કુલ પુરસ્કાર પોઈન્ટ',
      'welcome_student': 'સ્વાગત છે, વિદ્યાર્થી!',
      'ready_to_test': 'તમારા જ્ઞાનનું પરીક્ષણ કરવા તૈયાર છો?',
      'subject': 'વિષય',
      'select_subject': 'વિષય પસંદ કરો',
      'marks': 'ગુણ',
      'select_marks': 'ગુણ પસંદ કરો',
      'start_new_exam': 'નવી પરીક્ષા શરૂ કરો',
      'unit': 'એકમ',
      'select_unit': 'એકમ પસંદ કરો',
      'exam_instructions': 'પરીક્ષાની સૂચનાઓ',
      'instruction1': 'દરેક પ્રશ્નમાં 4 બહુવિકલ્પ વિકલ્પો છે.',
      'instruction2': 'તમારે દરેક પ્રશ્ન માટે ફક્ત એક જ વિકલ્પ પસંદ કરવો આવશ્યક છે.',
      'instruction3': 'દરેક સાચા જવાબ માટે 1 ગુણ છે.',
      'instruction4': 'ખોટા જવાબો માટે કોઈ નેગેટિવ માર્કિંગ નથી.',
      'instruction5': 'દરેક પ્રશ્નનો જવાબ આપવા માટે તમારી પાસે 5 મિનિટ છે.',
      'all_the_best': 'શુભેચ્છા!',
      'proceed_to_exam': 'પરીક્ષા માટે આગળ વધો',
      'question': 'પ્રશ્ન',
      'next': 'આગળ',
      'previous': 'પાછળ',
      'submit': 'સબમિટ કરો',
      'skip': 'છોડી દો',
      'login': 'લોગિન',
      'password': 'પાસવર્ડ',
      'email': 'ઈમેલ',
      'forgot_dpin': 'D-PIN ભૂલી ગયા છો?',
      'dpin': 'D-PIN',
      'register': 'રજીસ્ટર',
      'first_name': 'પ્રથમ નામ',
      'middle_name': 'મધ્યમ નામ',
      'last_name': 'અટક',
      'full_name': 'પૂરું નામ',
      'phone_number': 'ફોન નંબર',
      'std': 'ધોરણ',
      'medium': 'માધ્યમ',
      'school': 'શાળા',
      'address': 'સરનામું',
      'already_have_account': 'પહેલેથી જ એકાઉન્ટ છે?',
      'dont_have_account': "એકાઉન્ટ નથી?",
      'welcome_to_dm_bhatt': 'ડીએમ ભટ્ટ ક્લાસીસમાં તમારું સ્વાગત છે',
      'academic_path': 'શૈક્ષણિક શ્રેષ્ઠતા તરફનો તમારો માર્ગ અહીંથી શરૂ થાય છે.',
      'register_guest': 'મહેમાન તરીકે નોંધણી કરો',
      'guest_registration': 'મહેમાન નોંધણી',
      'welcome_guest': 'મહેમાનનું સ્વાગત છે',
      'dont_worry': 'ચિંતા કરશો નહીં,',
      'forgot_password_header': 'પાસવર્ડ ભૂલી ગયા છો',
      'forgot_password_subtext': 'કૃપા કરીને તમારા ખાતા સાથે સંકળાયેલ ફોન નંબર દાખલ કરો.',
      'enter_phone_hint': 'તમારો રજિસ્ટર્ડ ફોન નંબર દાખલ કરો',
      'send_otp': 'ઓટીપી મોકલો',
      'sending_otp': 'ઓટીપી મોકલી રહ્યા છીએ...',
      'hey_there': 'નમસ્તે,',
      'welcome_back': 'ફરી સ્વાગત છે',
      'forgot_password_question': 'તમારો પાસવર્ડ ભૂલી ગયા છો?',
      'name': 'નામ',
      'roll_number': 'રોલ નંબર',
      'parent_phone': "વાલીનો મોબાઈલ નંબર",
      'standard': 'ધોરણ',
      'stream': 'સ્ટ્રીમ',
      'state': 'રાજ્ય',
      'city': 'શહેર',
      'school_name': 'શાળાનું નામ',
      'agree_terms': 'હું સાથે સહમત છું ',
      'terms_conditions': 'નિયમો અને શરતો',
    },
  };

  String get dashboard => _localizedValues[locale.languageCode]!['dashboard']!;
  String get explore => _localizedValues[locale.languageCode]!['explore']!;
  String get dmai => _localizedValues[locale.languageCode]!['dmai']!;
  String get more => _localizedValues[locale.languageCode]!['more']!;
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get dailyTimeTable => _localizedValues[locale.languageCode]!['daily_time_table']!;
  String get startExam => _localizedValues[locale.languageCode]!['start_exam']!;
  String get nextExamWaiting => _localizedValues[locale.languageCode]!['next_exam_waiting']!;
  String get reports => _localizedValues[locale.languageCode]!['reports']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get themeMode => _localizedValues[locale.languageCode]!['theme_mode']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get signOut => _localizedValues[locale.languageCode]!['sign_out']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get academicPerformance => _localizedValues[locale.languageCode]!['academic_performance']!;
  String get totalRewardPoints => _localizedValues[locale.languageCode]!['total_reward_points']!;
  
  String get welcomeStudent => _localizedValues[locale.languageCode]!['welcome_student']!;
  String get readyToTest => _localizedValues[locale.languageCode]!['ready_to_test']!;
  String get subject => _localizedValues[locale.languageCode]!['subject']!;
  String get selectSubject => _localizedValues[locale.languageCode]!['select_subject']!;
  String get marks => _localizedValues[locale.languageCode]!['marks']!;
  String get selectMarks => _localizedValues[locale.languageCode]!['select_marks']!;
  String get startNewExam => _localizedValues[locale.languageCode]!['start_new_exam']!;
  String get unit => _localizedValues[locale.languageCode]!['unit']!;
  String get selectUnit => _localizedValues[locale.languageCode]!['select_unit']!;
  String get examInstructions => _localizedValues[locale.languageCode]!['exam_instructions']!;
  String get instruction1 => _localizedValues[locale.languageCode]!['instruction1']!;
  String get instruction2 => _localizedValues[locale.languageCode]!['instruction2']!;
  String get instruction3 => _localizedValues[locale.languageCode]!['instruction3']!;
  String get instruction4 => _localizedValues[locale.languageCode]!['instruction4']!;
  String get instruction5 => _localizedValues[locale.languageCode]!['instruction5']!;
  String get allTheBest => _localizedValues[locale.languageCode]!['all_the_best']!;
  String get proceedToExam => _localizedValues[locale.languageCode]!['proceed_to_exam']!;
  String get question => _localizedValues[locale.languageCode]!['question']!;
  String get next => _localizedValues[locale.languageCode]!['next']!;
  String get previous => _localizedValues[locale.languageCode]!['previous']!;
  String get submit => _localizedValues[locale.languageCode]!['submit']!;
  String get skip => _localizedValues[locale.languageCode]!['skip']!;
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get forgotDpin => _localizedValues[locale.languageCode]!['forgot_dpin']!;
  String get dpin => _localizedValues[locale.languageCode]!['dpin']!;
  String get register => _localizedValues[locale.languageCode]!['register']!;
  String get firstName => _localizedValues[locale.languageCode]!['first_name']!;
  String get middleName => _localizedValues[locale.languageCode]!['middle_name']!;
  String get lastName => _localizedValues[locale.languageCode]!['last_name']!;
  String get fullName => _localizedValues[locale.languageCode]!['full_name']!;
  String get phoneNumber => _localizedValues[locale.languageCode]!['phone_number']!;
  String get std => _localizedValues[locale.languageCode]!['std']!;
  String get medium => _localizedValues[locale.languageCode]!['medium']!;
  String get school => _localizedValues[locale.languageCode]!['school']!;
  String get address => _localizedValues[locale.languageCode]!['address']!;
  String get alreadyHaveAccount => _localizedValues[locale.languageCode]!['already_have_account']!;
  String get dontHaveAccount => _localizedValues[locale.languageCode]!['dont_have_account']!;

  String get welcomeToDmBhatt => _localizedValues[locale.languageCode]!['welcome_to_dm_bhatt']!;
  String get academicPath => _localizedValues[locale.languageCode]!['academic_path']!;
  String get registerGuest => _localizedValues[locale.languageCode]!['register_guest']!;
  String get guestRegistration => _localizedValues[locale.languageCode]!['guest_registration']!;
  String get welcomeGuest => _localizedValues[locale.languageCode]!['welcome_guest']!;
  String get dontWorry => _localizedValues[locale.languageCode]!['dont_worry']!;
  String get forgotPasswordHeader => _localizedValues[locale.languageCode]!['forgot_password_header']!;
  String get forgotPasswordSubtext => _localizedValues[locale.languageCode]!['forgot_password_subtext']!;
  String get enterPhoneHint => _localizedValues[locale.languageCode]!['enter_phone_hint']!;
  String get sendOtp => _localizedValues[locale.languageCode]!['send_otp']!;
  String get sendingOtp => _localizedValues[locale.languageCode]!['sending_otp']!;
  String get heyThere => _localizedValues[locale.languageCode]!['hey_there']!;
  String get welcomeBack => _localizedValues[locale.languageCode]!['welcome_back']!;
  String get forgotPasswordQuestion => _localizedValues[locale.languageCode]!['forgot_password_question']!;
  String get name => _localizedValues[locale.languageCode]!['name']!;
  String get rollNumber => _localizedValues[locale.languageCode]!['roll_number']!;
  String get parentPhone => _localizedValues[locale.languageCode]!['parent_phone']!;
  String get standard => _localizedValues[locale.languageCode]!['standard']!;
  String get stream => _localizedValues[locale.languageCode]!['stream']!;
  String get state => _localizedValues[locale.languageCode]!['state']!;
  String get city => _localizedValues[locale.languageCode]!['city']!;
  String get schoolName => _localizedValues[locale.languageCode]!['school_name']!;
  String get agreeTerms => _localizedValues[locale.languageCode]!['agree_terms']!;
  String get termsConditions => _localizedValues[locale.languageCode]!['terms_conditions']!;

  // Method to get by key if needed
  String getString(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}
