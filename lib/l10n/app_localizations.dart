import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';

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
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('mr'),
    Locale('ta'),
  ];

  /// No description provided for @studentProfile.
  ///
  /// In en, this message translates to:
  /// **'Student Profile'**
  String get studentProfile;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @switchAccounts.
  ///
  /// In en, this message translates to:
  /// **'Switch Accounts'**
  String get switchAccounts;

  /// No description provided for @manageProfiles.
  ///
  /// In en, this message translates to:
  /// **'Manage your profiles seamlessly'**
  String get manageProfiles;

  /// No description provided for @logInExisting.
  ///
  /// In en, this message translates to:
  /// **'Log In Existing'**
  String get logInExisting;

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNew;

  /// No description provided for @learningPoints.
  ///
  /// In en, this message translates to:
  /// **'Learning Points'**
  String get learningPoints;

  /// No description provided for @recentPerformance.
  ///
  /// In en, this message translates to:
  /// **'Recent Performance'**
  String get recentPerformance;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile Details'**
  String get profileDetails;

  /// No description provided for @school.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get school;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @parentsContact.
  ///
  /// In en, this message translates to:
  /// **'Parent\'s Contact'**
  String get parentsContact;

  /// No description provided for @signOutSession.
  ///
  /// In en, this message translates to:
  /// **'Sign Out of session'**
  String get signOutSession;

  /// No description provided for @switchProfile.
  ///
  /// In en, this message translates to:
  /// **'Switch Profile'**
  String get switchProfile;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @addAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Another Account'**
  String get addAnotherAccount;

  /// No description provided for @onlineExam.
  ///
  /// In en, this message translates to:
  /// **'Online Exam'**
  String get onlineExam;

  /// No description provided for @offlineExam.
  ///
  /// In en, this message translates to:
  /// **'Offline Exam'**
  String get offlineExam;

  /// No description provided for @singleProfileActive.
  ///
  /// In en, this message translates to:
  /// **'Single Profile Active. Add another to switch easily.'**
  String get singleProfileActive;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @dmai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get dmai;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @dailyTimeTable.
  ///
  /// In en, this message translates to:
  /// **'Daily Time Table'**
  String get dailyTimeTable;

  /// No description provided for @startExam.
  ///
  /// In en, this message translates to:
  /// **'START EXAM'**
  String get startExam;

  /// No description provided for @nextExamWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your next exam is waiting for you.'**
  String get nextExamWaiting;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @academicPerformance.
  ///
  /// In en, this message translates to:
  /// **'Academic Performance'**
  String get academicPerformance;

  /// No description provided for @totalRewardPoints.
  ///
  /// In en, this message translates to:
  /// **'Total Reward Points'**
  String get totalRewardPoints;

  /// No description provided for @welcomeStudent.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Student!'**
  String get welcomeStudent;

  /// No description provided for @readyToTest.
  ///
  /// In en, this message translates to:
  /// **'Ready to test your knowledge?'**
  String get readyToTest;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @selectSubject.
  ///
  /// In en, this message translates to:
  /// **'Select Subject'**
  String get selectSubject;

  /// No description provided for @marks.
  ///
  /// In en, this message translates to:
  /// **'Marks'**
  String get marks;

  /// No description provided for @selectMarks.
  ///
  /// In en, this message translates to:
  /// **'Select Marks'**
  String get selectMarks;

  /// No description provided for @startNewExam.
  ///
  /// In en, this message translates to:
  /// **'Start a New Exam'**
  String get startNewExam;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @selectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select Unit'**
  String get selectUnit;

  /// No description provided for @examInstructions.
  ///
  /// In en, this message translates to:
  /// **'Exam Instructions'**
  String get examInstructions;

  /// No description provided for @instruction1.
  ///
  /// In en, this message translates to:
  /// **'Each question has 4 multiple-choice options.'**
  String get instruction1;

  /// No description provided for @instruction2.
  ///
  /// In en, this message translates to:
  /// **'You must select only one option per question.'**
  String get instruction2;

  /// No description provided for @instruction3.
  ///
  /// In en, this message translates to:
  /// **'Each correct answer is worth 1 mark.'**
  String get instruction3;

  /// No description provided for @instruction4.
  ///
  /// In en, this message translates to:
  /// **'There is no penalty for incorrect answers.'**
  String get instruction4;

  /// No description provided for @instruction5.
  ///
  /// In en, this message translates to:
  /// **'You have 5 minutes to answer each question.'**
  String get instruction5;

  /// No description provided for @allTheBest.
  ///
  /// In en, this message translates to:
  /// **'All the best!'**
  String get allTheBest;

  /// No description provided for @proceedToExam.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Exam'**
  String get proceedToExam;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @questionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionProgress(Object current, Object total);

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotDpin.
  ///
  /// In en, this message translates to:
  /// **'Forgot D-PIN?'**
  String get forgotDpin;

  /// No description provided for @dpin.
  ///
  /// In en, this message translates to:
  /// **'D-PIN'**
  String get dpin;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @middleName.
  ///
  /// In en, this message translates to:
  /// **'Middle Name'**
  String get middleName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @std.
  ///
  /// In en, this message translates to:
  /// **'STD'**
  String get std;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @welcomeToDmBhatt.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Our Learning Platform'**
  String get welcomeToDmBhatt;

  /// No description provided for @academicPath.
  ///
  /// In en, this message translates to:
  /// **'Your path to academic excellence starts here.'**
  String get academicPath;

  /// No description provided for @registerGuest.
  ///
  /// In en, this message translates to:
  /// **'Register as a guest'**
  String get registerGuest;

  /// No description provided for @guestRegistration.
  ///
  /// In en, this message translates to:
  /// **'Guest Registration'**
  String get guestRegistration;

  /// No description provided for @welcomeGuest.
  ///
  /// In en, this message translates to:
  /// **'Welcome Guest'**
  String get welcomeGuest;

  /// No description provided for @dontWorry.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry,'**
  String get dontWorry;

  /// No description provided for @forgotPasswordHeader.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordHeader;

  /// No description provided for @forgotPasswordSubtext.
  ///
  /// In en, this message translates to:
  /// **'Please enter the phone number associated with your account.'**
  String get forgotPasswordSubtext;

  /// No description provided for @enterPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered phone number'**
  String get enterPhoneHint;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @sendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Sending OTP...'**
  String get sendingOtp;

  /// No description provided for @heyThere.
  ///
  /// In en, this message translates to:
  /// **'Hey there,'**
  String get heyThere;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @forgotPasswordQuestion.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPasswordQuestion;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @rollNumber.
  ///
  /// In en, this message translates to:
  /// **'Roll Number'**
  String get rollNumber;

  /// No description provided for @parentPhone.
  ///
  /// In en, this message translates to:
  /// **'Parent\'s Mobile Number'**
  String get parentPhone;

  /// No description provided for @standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standard;

  /// No description provided for @stream.
  ///
  /// In en, this message translates to:
  /// **'Stream'**
  String get stream;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @schoolName.
  ///
  /// In en, this message translates to:
  /// **'School Name'**
  String get schoolName;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree with '**
  String get agreeTerms;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsConditions;

  /// No description provided for @fiveMinRapidTest.
  ///
  /// In en, this message translates to:
  /// **'5 Min Rapid Test'**
  String get fiveMinRapidTest;

  /// No description provided for @studyForFiveMins.
  ///
  /// In en, this message translates to:
  /// **'Study for 5 mins & take a quick quiz!'**
  String get studyForFiveMins;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get startNow;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @phoneMustBeTenDigits.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be 10 digits'**
  String get phoneMustBeTenDigits;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 7 characters'**
  String get passwordLengthError;

  /// No description provided for @passwordComplexityError.
  ///
  /// In en, this message translates to:
  /// **'Password must have at least one uppercase letter, one digit, and one special character'**
  String get passwordComplexityError;

  /// No description provided for @pleaseEnterParentMobile.
  ///
  /// In en, this message translates to:
  /// **'Please enter parent\'s mobile number'**
  String get pleaseEnterParentMobile;

  /// No description provided for @instituteName.
  ///
  /// In en, this message translates to:
  /// **'Institute Name'**
  String get instituteName;

  /// No description provided for @pleaseAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'Please agree to Terms and Conditions'**
  String get pleaseAgreeTerms;

  /// No description provided for @pleaseSelectAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please select all required fields'**
  String get pleaseSelectAllFields;

  /// No description provided for @pleaseSelectStream.
  ///
  /// In en, this message translates to:
  /// **'Please select a stream'**
  String get pleaseSelectStream;

  /// No description provided for @phoneNumbersCannotBeSame.
  ///
  /// In en, this message translates to:
  /// **'Phone number and Parent\'s mobile number cannot be the same'**
  String get phoneNumbersCannotBeSame;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @enterDetailsToAdd.
  ///
  /// In en, this message translates to:
  /// **'Enter details to add a new profile'**
  String get enterDetailsToAdd;

  /// No description provided for @loginAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Login & Add'**
  String get loginAndAdd;

  /// No description provided for @studentActivities.
  ///
  /// In en, this message translates to:
  /// **'Student Activities'**
  String get studentActivities;

  /// No description provided for @appInformation.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInformation;

  /// No description provided for @meetOurInfluencer.
  ///
  /// In en, this message translates to:
  /// **'Meet Our Influencer'**
  String get meetOurInfluencer;

  /// No description provided for @myArea.
  ///
  /// In en, this message translates to:
  /// **'My Area'**
  String get myArea;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @mindGames.
  ///
  /// In en, this message translates to:
  /// **'Mind Games'**
  String get mindGames;

  /// No description provided for @schoolPapers.
  ///
  /// In en, this message translates to:
  /// **'School Papers'**
  String get schoolPapers;

  /// No description provided for @boardPapers.
  ///
  /// In en, this message translates to:
  /// **'Board Papers'**
  String get boardPapers;

  /// No description provided for @examHistory.
  ///
  /// In en, this message translates to:
  /// **'Exam History'**
  String get examHistory;

  /// No description provided for @productHistory.
  ///
  /// In en, this message translates to:
  /// **'Product History'**
  String get productHistory;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @upgradePlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlan;

  /// No description provided for @referAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer & Earn'**
  String get referAndEarn;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @followUs.
  ///
  /// In en, this message translates to:
  /// **'Follow Us'**
  String get followUs;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful'**
  String get registrationSuccessful;

  /// No description provided for @guestRegistrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Guest Registration Successful'**
  String get guestRegistrationSuccessful;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration Failed: '**
  String get registrationFailed;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @themeStyle.
  ///
  /// In en, this message translates to:
  /// **'Theme Style'**
  String get themeStyle;

  /// No description provided for @selectThemeStyle.
  ///
  /// In en, this message translates to:
  /// **'Select Theme Style'**
  String get selectThemeStyle;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @areYouSureSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get areYouSureSignOut;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully'**
  String get signOutSuccess;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @gujarati.
  ///
  /// In en, this message translates to:
  /// **'Gujarati'**
  String get gujarati;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @classic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get classic;

  /// No description provided for @ocean.
  ///
  /// In en, this message translates to:
  /// **'Ocean (Teal)'**
  String get ocean;

  /// No description provided for @sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset (Orange)'**
  String get sunset;

  /// No description provided for @forest.
  ///
  /// In en, this message translates to:
  /// **'Forest (Green)'**
  String get forest;

  /// No description provided for @lavender.
  ///
  /// In en, this message translates to:
  /// **'Lavender (Purple)'**
  String get lavender;

  /// No description provided for @midnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight (Deep Blue)'**
  String get midnight;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get marathi;

  /// No description provided for @referAndEarnHeader.
  ///
  /// In en, this message translates to:
  /// **'Invited Friends & Earn Bonus Points'**
  String get referAndEarnHeader;

  /// No description provided for @referAndEarnSubtext.
  ///
  /// In en, this message translates to:
  /// **'Share your unique code with friends. When they join, you earn bonus points!'**
  String get referAndEarnSubtext;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'YOUR REFERRAL CODE'**
  String get yourReferralCode;

  /// No description provided for @generateCode.
  ///
  /// In en, this message translates to:
  /// **'Generate Code'**
  String get generateCode;

  /// No description provided for @shareCode.
  ///
  /// In en, this message translates to:
  /// **'Share Code'**
  String get shareCode;

  /// No description provided for @limitReached.
  ///
  /// In en, this message translates to:
  /// **'Limit Reached'**
  String get limitReached;

  /// No description provided for @referMoreStudents.
  ///
  /// In en, this message translates to:
  /// **'You can refer {count} more students.'**
  String referMoreStudents(Object count);

  /// No description provided for @maxReferralLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached the maximum referral limit of {max}.'**
  String maxReferralLimitReached(Object max);

  /// No description provided for @referralMilestones.
  ///
  /// In en, this message translates to:
  /// **'Referral Milestones'**
  String get referralMilestones;

  /// No description provided for @pointsConversionNote.
  ///
  /// In en, this message translates to:
  /// **'Points Conversion: 50 Points = ₹1. Points can be used for plan upgrades.'**
  String get pointsConversionNote;

  /// No description provided for @totalBonusPoints.
  ///
  /// In en, this message translates to:
  /// **'Total Bonus Points'**
  String get totalBonusPoints;

  /// No description provided for @invitedFriendsCount.
  ///
  /// In en, this message translates to:
  /// **'Invited Friends ({count}/{max})'**
  String invitedFriendsCount(Object count, Object max);

  /// No description provided for @noFriendsInvited.
  ///
  /// In en, this message translates to:
  /// **'No friends invited yet'**
  String get noFriendsInvited;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard!'**
  String get codeCopied;

  /// No description provided for @generateCodeFirst.
  ///
  /// In en, this message translates to:
  /// **'Please generate a code first.'**
  String get generateCodeFirst;

  /// No description provided for @shareTextWeb.
  ///
  /// In en, this message translates to:
  /// **'Join our learning platform using my referral code: {code} and get amazing benefits! Download now: {url}'**
  String shareTextWeb(Object code, Object url);

  /// No description provided for @shareTextMobile.
  ///
  /// In en, this message translates to:
  /// **'Hello! I am gifting you a special discount on our Learning App. Use my code \"{code}\" at the time of registration to claim it! Download: {url}'**
  String shareTextMobile(Object code, Object url);

  /// No description provided for @aboutUsHeader.
  ///
  /// In en, this message translates to:
  /// **'Empowering Your Future'**
  String get aboutUsHeader;

  /// No description provided for @aboutUsDescription.
  ///
  /// In en, this message translates to:
  /// **'We are committed to providing top-quality education and modern learning resources to help every student excel. Our mission is to simplify complex concepts and inspire a lifelong love for learning.\n\nWith a focus on interactive teaching and student success, we provide the tools and support needed to reach academic goals and beyond.'**
  String get aboutUsDescription;

  /// No description provided for @influencerName.
  ///
  /// In en, this message translates to:
  /// **'Our Lead Educator'**
  String get influencerName;

  /// No description provided for @followOnInstagram.
  ///
  /// In en, this message translates to:
  /// **'Follow on Instagram'**
  String get followOnInstagram;

  /// No description provided for @selectStandard.
  ///
  /// In en, this message translates to:
  /// **'Select Standard'**
  String get selectStandard;

  /// No description provided for @selectStream.
  ///
  /// In en, this message translates to:
  /// **'Select Stream'**
  String get selectStream;

  /// No description provided for @selectMedium.
  ///
  /// In en, this message translates to:
  /// **'Select Medium'**
  String get selectMedium;

  /// No description provided for @board.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get board;

  /// No description provided for @loginAs.
  ///
  /// In en, this message translates to:
  /// **'Login As'**
  String get loginAs;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacher;

  /// No description provided for @baseAmount.
  ///
  /// In en, this message translates to:
  /// **'Base Amount'**
  String get baseAmount;

  /// No description provided for @promoDiscount.
  ///
  /// In en, this message translates to:
  /// **'Promo Discount (50%)'**
  String get promoDiscount;

  /// No description provided for @pointsDiscount.
  ///
  /// In en, this message translates to:
  /// **'Points Discount'**
  String get pointsDiscount;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Payable'**
  String get totalPayable;

  /// No description provided for @haveRedeemCode.
  ///
  /// In en, this message translates to:
  /// **'Have a Redeem Code?'**
  String get haveRedeemCode;

  /// No description provided for @promoHint.
  ///
  /// In en, this message translates to:
  /// **'Use DMBHATT{std}'**
  String promoHint(Object std);

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @useRewardPoints.
  ///
  /// In en, this message translates to:
  /// **'Use Reward Points (Available: {points})'**
  String useRewardPoints(Object points);

  /// No description provided for @pointsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter points to use'**
  String get pointsHint;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @payAndUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Pay ₹{amount} & Upgrade'**
  String payAndUpgrade(Object amount);

  /// No description provided for @selectStandardFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select standard first'**
  String get selectStandardFirst;

  /// No description provided for @promoAppliedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Promo code applied successfully!'**
  String get promoAppliedSuccess;

  /// No description provided for @invalidPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid promo code'**
  String get invalidPromoCode;

  /// No description provided for @insufficientPoints.
  ///
  /// In en, this message translates to:
  /// **'You only have {points} points'**
  String insufficientPoints(Object points);

  /// No description provided for @pointsAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Points adjusted to max payable amount'**
  String get pointsAdjusted;

  /// No description provided for @pointsAppliedAmount.
  ///
  /// In en, this message translates to:
  /// **'Points applied: ₹{amount} off'**
  String pointsAppliedAmount(Object amount);

  /// No description provided for @selectStandardMediumError.
  ///
  /// In en, this message translates to:
  /// **'Please select Standard and Medium'**
  String get selectStandardMediumError;

  /// No description provided for @selectStreamError.
  ///
  /// In en, this message translates to:
  /// **'Please select Stream'**
  String get selectStreamError;

  /// No description provided for @planUpgradeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Plan Upgraded Successfully!'**
  String get planUpgradeSuccess;

  /// No description provided for @regularExams.
  ///
  /// In en, this message translates to:
  /// **'Regular Exams'**
  String get regularExams;

  /// No description provided for @fiveMinQuiz.
  ///
  /// In en, this message translates to:
  /// **'5 Min Quiz'**
  String get fiveMinQuiz;

  /// No description provided for @noExamsFound.
  ///
  /// In en, this message translates to:
  /// **'No exams found'**
  String get noExamsFound;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateLabel(Object date);

  /// No description provided for @marksLabel.
  ///
  /// In en, this message translates to:
  /// **'Marks'**
  String get marksLabel;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @shareProtected.
  ///
  /// In en, this message translates to:
  /// **'Share (Protected)'**
  String get shareProtected;

  /// No description provided for @downloadedTo.
  ///
  /// In en, this message translates to:
  /// **'Downloaded to: {path}'**
  String downloadedTo(Object path);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(Object error);

  /// No description provided for @sharingPdf.
  ///
  /// In en, this message translates to:
  /// **'Sharing PDF...'**
  String get sharingPdf;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share failed: {error}'**
  String shareFailed(Object error);

  /// No description provided for @marksObtained.
  ///
  /// In en, this message translates to:
  /// **'Marks Obtained: {marks}'**
  String marksObtained(Object marks);

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions:'**
  String get questions;

  /// No description provided for @rateYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate Your Experience'**
  String get rateYourExperience;

  /// No description provided for @howDoYouFeel.
  ///
  /// In en, this message translates to:
  /// **'How do you feel about the app?'**
  String get howDoYouFeel;

  /// No description provided for @terrible.
  ///
  /// In en, this message translates to:
  /// **'Terrible'**
  String get terrible;

  /// No description provided for @bad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get bad;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @great.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get great;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Write your feedback here (optional)...'**
  String get feedbackHint;

  /// No description provided for @thankYouFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thankYouFeedback;

  /// No description provided for @selectRatingError.
  ///
  /// In en, this message translates to:
  /// **'Please select a rating.'**
  String get selectRatingError;

  /// No description provided for @followUsOn.
  ///
  /// In en, this message translates to:
  /// **'Follow Us On'**
  String get followUsOn;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @instagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instagram;

  /// No description provided for @youtube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get youtube;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @dailyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily Limit Reached'**
  String get dailyLimitReached;

  /// No description provided for @limitQuotaMessage.
  ///
  /// In en, this message translates to:
  /// **'You have used your 1 hour quota for today. Come back tomorrow!'**
  String get limitQuotaMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @memoryMatch.
  ///
  /// In en, this message translates to:
  /// **'Memory Match'**
  String get memoryMatch;

  /// No description provided for @memoryMatchDesc.
  ///
  /// In en, this message translates to:
  /// **'Improve your memory by finding matching pairs of cards.'**
  String get memoryMatchDesc;

  /// No description provided for @speedMath.
  ///
  /// In en, this message translates to:
  /// **'Speed Math'**
  String get speedMath;

  /// No description provided for @speedMathDesc.
  ///
  /// In en, this message translates to:
  /// **'Test your calculation speed! Good for mental agility.'**
  String get speedMathDesc;

  /// No description provided for @wordScramble.
  ///
  /// In en, this message translates to:
  /// **'Word Scramble'**
  String get wordScramble;

  /// No description provided for @wordScrambleDesc.
  ///
  /// In en, this message translates to:
  /// **'Unscramble the educational words.'**
  String get wordScrambleDesc;

  /// No description provided for @oddOneOut.
  ///
  /// In en, this message translates to:
  /// **'Odd One Out'**
  String get oddOneOut;

  /// No description provided for @oddOneOutDesc.
  ///
  /// In en, this message translates to:
  /// **'Identify the item that doesn\'t belong in the group.'**
  String get oddOneOutDesc;

  /// No description provided for @codeBreaker.
  ///
  /// In en, this message translates to:
  /// **'Code Breaker'**
  String get codeBreaker;

  /// No description provided for @codeBreakerDesc.
  ///
  /// In en, this message translates to:
  /// **'Use logic to guess the secret color code.'**
  String get codeBreakerDesc;

  /// No description provided for @factOrFiction.
  ///
  /// In en, this message translates to:
  /// **'Fact or Fiction?'**
  String get factOrFiction;

  /// No description provided for @factOrFictionDesc.
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge with quick true or false questions.'**
  String get factOrFictionDesc;

  /// No description provided for @sentenceBuilder.
  ///
  /// In en, this message translates to:
  /// **'Sentence Builder'**
  String get sentenceBuilder;

  /// No description provided for @sentenceBuilderDesc.
  ///
  /// In en, this message translates to:
  /// **'Form correct sentences from the jumbled words.'**
  String get sentenceBuilderDesc;

  /// No description provided for @grammarGuardian.
  ///
  /// In en, this message translates to:
  /// **'Grammar Guardian'**
  String get grammarGuardian;

  /// No description provided for @grammarGuardianDesc.
  ///
  /// In en, this message translates to:
  /// **'Master English grammar by spotting the correct usage.'**
  String get grammarGuardianDesc;

  /// No description provided for @wordBridge.
  ///
  /// In en, this message translates to:
  /// **'Word Bridge'**
  String get wordBridge;

  /// No description provided for @wordBridgeDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect two unrelated concepts through a chain of words.'**
  String get wordBridgeDesc;

  /// No description provided for @emojiDecoder.
  ///
  /// In en, this message translates to:
  /// **'Emoji Decoder'**
  String get emojiDecoder;

  /// No description provided for @emojiDecoderDesc.
  ///
  /// In en, this message translates to:
  /// **'Guess the famous idiom or phrase from emojis.'**
  String get emojiDecoderDesc;

  /// No description provided for @th.
  ///
  /// In en, this message translates to:
  /// **'th'**
  String get th;

  /// No description provided for @forLabel.
  ///
  /// In en, this message translates to:
  /// **'for'**
  String get forLabel;

  /// No description provided for @availablePapers.
  ///
  /// In en, this message translates to:
  /// **'Available Papers'**
  String get availablePapers;

  /// No description provided for @noPapersFound.
  ///
  /// In en, this message translates to:
  /// **'No board papers found'**
  String get noPapersFound;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @followOnWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Follow our WhatsApp Channel'**
  String get followOnWhatsApp;

  /// No description provided for @followOnFacebook.
  ///
  /// In en, this message translates to:
  /// **'Follow our Facebook Page'**
  String get followOnFacebook;

  /// No description provided for @clickHere.
  ///
  /// In en, this message translates to:
  /// **'Click here'**
  String get clickHere;

  /// No description provided for @dmBhattGroupTuition.
  ///
  /// In en, this message translates to:
  /// **'The Learning Academy'**
  String get dmBhattGroupTuition;

  /// No description provided for @excellenceInEducation.
  ///
  /// In en, this message translates to:
  /// **'Excellence in Education'**
  String get excellenceInEducation;

  /// No description provided for @manageProfilesSeamlessly.
  ///
  /// In en, this message translates to:
  /// **'Manage your profiles seamlessly'**
  String get manageProfilesSeamlessly;

  /// No description provided for @noResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'No results yet. Keep learning!'**
  String get noResultsMessage;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notApplicable;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;
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
      <String>['en', 'gu', 'hi', 'mr', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
