import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English'),
  hindi('hi', 'हिंदी'),
  bengali('bn', 'বাংলা'),
  tamil('ta', 'தமிழ்'),
  telugu('te', 'తెలుగు'),
  marathi('mr', 'मराठी'),
  gujarati('gu', 'ગુજરાતી'),
  kannada('kn', 'ಕನ್ನಡ'),
  malayalam('ml', 'മലയാളം'),
  punjabi('pa', 'ਪੰਜਾਬੀ');

  const AppLanguage(this.code, this.displayName);
  final String code;
  final String displayName;
}

class I18nService {
  static final I18nService _instance = I18nService._internal();
  factory I18nService() => _instance;
  I18nService._internal();

  AppLanguage _currentLanguage = AppLanguage.english;
  final Map<String, Map<String, String>> _translations = {};

  Future<void> initialize() async {
    await _loadTranslations();
    await _loadSavedLanguage();
  }

  Future<void> _loadTranslations() async {
    _translations.addAll({
      'en': _englishTranslations,
      'hi': _hindiTranslations,
      'bn': _bengaliTranslations,
      'ta': _tamilTranslations,
      'te': _teluguTranslations,
      'mr': _marathiTranslations,
      'gu': _gujaratiTranslations,
      'kn': _kannadaTranslations,
      'ml': _malayalamTranslations,
      'pa': _punjabiTranslations,
    });
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString('app_language') ?? 'en';
      _currentLanguage = AppLanguage.values.firstWhere(
        (lang) => lang.code == savedLanguageCode,
        orElse: () => AppLanguage.english,
      );
    } catch (e) {
      debugPrint('Failed to load saved language: $e');
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', language.code);
    } catch (e) {
      debugPrint('Failed to save language: $e');
    }
  }

  AppLanguage get currentLanguage => _currentLanguage;

  String translate(String key, {Map<String, String>? params}) {
    final translation = _translations[_currentLanguage.code]?[key] ??
                       _translations['en']?[key] ??
                       key;

    if (params != null) {
      return _replaceParameters(translation, params);
    }

    return translation;
  }

  String _replaceParameters(String translation, Map<String, String> params) {
    String result = translation;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  List<AppLanguage> get supportedLanguages => AppLanguage.values;

  // Translation maps
  static const Map<String, String> _englishTranslations = {
    // Common
    'app_name': 'VoteReady',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'add': 'Add',
    'search': 'Search',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'retry': 'Retry',
    'next': 'Next',
    'previous': 'Previous',
    'finish': 'Finish',
    'skip': 'Skip',
    'close': 'Close',
    'yes': 'Yes',
    'no': 'No',
    'submit': 'Submit',
    'clear': 'Clear',
    'reset': 'Reset',
    'refresh': 'Refresh',
    'back': 'Back',
    'home': 'Home',
    'settings': 'Settings',
    'profile': 'Profile',
    'logout': 'Logout',
    'login': 'Login',
    'register': 'Register',
    
    // Navigation
    'dashboard': 'Dashboard',
    'eligibility': 'Eligibility Check',
    'registration': 'Voter Registration',
    'verification': 'Verify Details',
    'voting_day': 'Voting Day',
    'results': 'Election Results',
    'global_insights': 'Global Insights',
    'issue_resolver': 'Issue Resolver',
    
    // Onboarding
    'welcome_to_voteready': 'Welcome to VoteReady',
    'your_election_companion': 'Your complete election companion app',
    'lets_get_started': 'Let\'s Get Started',
    'app_description': 'VoteReady helps you navigate the Indian election process with ease',
    'features_title': 'Key Features',
    'feature_eligibility': 'Check your voting eligibility',
    'feature_registration': 'Register to vote online',
    'feature_verification': 'Verify voter details',
    'feature_voting_day': 'Get voting day information',
    'feature_results': 'Track election results',
    'permissions_title': 'Permissions',
    'permissions_description': 'We need some permissions to provide the best experience',
    'permission_location': 'Location access for polling station information',
    'permission_notifications': 'Notifications for important updates',
    'permission_storage': 'Storage for saving your documents',
    'account_setup': 'Account Setup',
    'enter_your_details': 'Enter your details to personalize your experience',
    'tutorial_complete': 'Tutorial Complete!',
    'ready_to_vote': 'You\'re all set to make your vote count!',
    
    // Forms
    'full_name': 'Full Name',
    'email_address': 'Email Address',
    'phone_number': 'Phone Number',
    'age': 'Age',
    'date_of_birth': 'Date of Birth',
    'gender': 'Gender',
    'address': 'Address',
    'city': 'City',
    'state': 'State',
    'pincode': 'Pincode',
    'aadhaar_number': 'Aadhaar Number',
    'voter_id': 'Voter ID',
    
    // Validation
    'field_required': 'This field is required',
    'invalid_email': 'Please enter a valid email address',
    'invalid_phone': 'Please enter a valid phone number',
    'invalid_age': 'Please enter a valid age (18-120)',
    'invalid_pincode': 'Please enter a valid 6-digit pincode',
    'invalid_aadhaar': 'Please enter a valid 12-digit Aadhaar number',
    'invalid_voter_id': 'Please enter a valid Voter ID',
    
    // Eligibility
    'eligibility_check': 'Eligibility Check',
    'check_if_eligible': 'Check if you\'re eligible to vote',
    'eligibility_criteria': 'Eligibility Criteria',
    'age_requirement': 'Must be 18 years or older',
    'citizenship_requirement': 'Must be an Indian citizen',
    'residence_requirement': 'Must be a resident of the constituency',
    'you_are_eligible': 'Congratulations! You are eligible to vote',
    'not_eligible': 'Sorry, you are not eligible to vote',
    'not_eligible_reason': 'Reason: {reason}',
    
    // Registration
    'voter_registration': 'Voter Registration',
    'register_to_vote': 'Register to vote in upcoming elections',
    'registration_steps': 'Registration Steps',
    'step_1': 'Fill Form 6',
    'step_2': 'Upload Documents',
    'step_3': 'Submit Application',
    'track_application': 'Track Application Status',
    'registration_status': 'Registration Status',
    'pending': 'Pending',
    'approved': 'Approved',
    'rejected': 'Rejected',
    
    // Verification
    'verify_details': 'Verify Your Details',
    'check_voter_list': 'Check if your name is in the voter list',
    'search_voter_list': 'Search Voter List',
    'name_found': 'Name Found in Voter List',
    'name_not_found': 'Name Not Found',
    'voter_details': 'Voter Details',
    'polling_station': 'Polling Station',
    'serial_number': 'Serial Number',
    
    // Voting Day
    'voting_day_info': 'Voting Day Information',
    'find_polling_station': 'Find Your Polling Station',
    'voting_date': 'Voting Date',
    'voting_time': 'Voting Time',
    'required_documents': 'Required Documents',
    'voter_id_card': 'Voter ID Card',
    'id_proof': 'Photo ID Proof',
    'voting_process': 'Voting Process',
    'step_1_verification': 'Step 1: Identity Verification',
    'step_2_ink_mark': 'Step 2: Get Ink Mark',
    'step_3_vote': 'Step 3: Cast Your Vote',
    'step_4_slip': 'Step 4: Get Voting Slip',
    
    // Results
    'election_results': 'Election Results',
    'live_results': 'Live Results',
    'constituency_results': 'Constituency Results',
    'candidate_details': 'Candidate Details',
    'party': 'Party',
    'votes': 'Votes',
    'vote_percentage': 'Vote %',
    'leading_candidate': 'Leading Candidate',
    'trailing_candidate': 'Trailing Candidate',
    'total_voters': 'Total Voters',
    'votes_polled': 'Votes Polled',
    'voter_turnout': 'Voter Turnout',
    
    // Error Messages
    'network_error': 'Network error. Please check your connection.',
    'server_error': 'Server error. Please try again later.',
    'validation_error': 'Please check your input and try again.',
    'authentication_error': 'Please login to continue.',
    'permission_denied': 'Permission denied. Please enable in settings.',
    'something_went_wrong': 'Something went wrong. Please try again.',
    
    // Success Messages
    'data_saved': 'Data saved successfully!',
    'profile_updated': 'Profile updated successfully!',
    'registration_submitted': 'Registration submitted successfully!',
    'documents_uploaded': 'Documents uploaded successfully!',
    
    // Settings
    'app_settings': 'App Settings',
    'language': 'Language',
    'theme': 'Theme',
    'notifications': 'Notifications',
    'privacy': 'Privacy',
    'about': 'About',
    'version': 'Version',
    'contact_support': 'Contact Support',
    'terms_conditions': 'Terms & Conditions',
    'privacy_policy': 'Privacy Policy',
    
    // Accessibility
    'high_contrast': 'High Contrast',
    'large_text': 'Large Text',
    'screen_reader': 'Screen Reader',
    'reduced_motion': 'Reduced Motion',
    'color_blind_friendly': 'Color Blind Friendly',
  };

  static const Map<String, String> _hindiTranslations = {
    'app_name': 'वोटरेडी',
    'ok': 'ठीक है',
    'cancel': 'रद्द करें',
    'save': 'सेव करें',
    'delete': 'हटाएं',
    'edit': 'संपादित करें',
    'add': 'जोड़ें',
    'search': 'खोजें',
    'loading': 'लोड हो रहा है...',
    'error': 'त्रुटि',
    'success': 'सफलता',
    'retry': 'फिर से कोशिश करें',
    'next': 'अगला',
    'previous': 'पिछला',
    'finish': 'समाप्त',
    'skip': 'छोड़ें',
    'close': 'बंद करें',
    'yes': 'हाँ',
    'no': 'नहीं',
    'submit': 'जमा करें',
    'clear': 'साफ करें',
    'reset': 'रीसेट करें',
    'refresh': 'रिफ्रेश करें',
    'back': 'वापस',
    'home': 'होम',
    'settings': 'सेटिंग्स',
    'profile': 'प्रोफाइल',
    'logout': 'लॉगआउट',
    'login': 'लॉगिन',
    'register': 'रजिस्टर',
    
    'dashboard': 'डैशबोर्ड',
    'eligibility': 'पात्रता जांच',
    'registration': 'मतदाता पंजीकरण',
    'verification': 'विवरण सत्यापन',
    'voting_day': 'मतदान दिवस',
    'results': 'चुनाव परिणाम',
    'global_insights': 'वैश्विक जानकारी',
    'issue_resolver': 'समस्या समाधान',
    
    'welcome_to_voteready': 'वोटरेडी में आपका स्वागत है',
    'your_election_companion': 'आपका पूर्ण चुनाव साथी ऐप',
    'lets_get_started': 'चलिए शुरू करते हैं',
    'app_description': 'वोटरेडी आपको भारतीय चुनाव प्रक्रिया को आसानी से नेविगेट करने में मदद करता है',
    'full_name': 'पूरा नाम',
    'email_address': 'ईमेल पता',
    'phone_number': 'फोन नंबर',
    'age': 'आयु',
    'date_of_birth': 'जन्म तिथि',
    'gender': 'लिंग',
    'address': 'पता',
    'city': 'शहर',
    'state': 'राज्य',
    'pincode': 'पिनकोड',
    'aadhaar_number': 'आधार नंबर',
    'voter_id': 'मतदाता पहचान पत्र',
    
    'field_required': 'यह फील्ड आवश्यक है',
    'invalid_email': 'कृपया एक वैध ईमेल पता दर्ज करें',
    'invalid_phone': 'कृपया एक वैध फोन नंबर दर्ज करें',
    'invalid_age': 'कृपया एक वैध आयु दर्ज करें (18-120)',
    'network_error': 'नेटवर्क त्रुटि। कृपया अपना कनेक्शन जांचें।',
    'server_error': 'सर्वर त्रुटि। कृपया बाद में फिर से कोशिश करें।',
  };

  static const Map<String, String> _bengaliTranslations = {
    'app_name': 'ভোটরেডি',
    'ok': 'ঠিক আছে',
    'cancel': '�াতিল',
    'save': 'সংরক্ষণ করুন',
    'delete': 'মুছুন',
    'edit': 'সম্পাদনা করুন',
    'add': 'যোগ করুন',
    'search': 'অনুসন্ধান',
    'loading': 'লোড হচ্ছে...',
    'error': 'ত্রুটি',
    'success': 'সফলতা',
    'retry': 'পুনরায় চেষ্টা করুন',
    'next': 'পরবর্তী',
    'previous': 'পূর্ববর্তী',
    'finish': 'সমাপ্ত',
    'skip': 'এড়িয়ে যান',
    'close': 'বন্ধ করুন',
    'yes': 'হ্যাঁ',
    'no': 'না',
    'submit': 'জমা দিন',
    'clear': 'পরিষ্কার করুন',
    'reset': 'রিসেট করুন',
    'refresh': 'রিফ্রেশ করুন',
    'back': 'পিছনে',
    'home': 'হোম',
    'settings': 'সেটিংস',
    'profile': 'প্রোফাইল',
    'logout': 'লগআউট',
    'login': 'লগইন',
    'register': 'নিবন্ধন',
    
    'dashboard': 'ড্যাশবোর্ড',
    'eligibility': 'যোগ্যতা পরীক্ষা',
    'registration': 'ভোটার নিবন্ধন',
    'verification': 'বিবরণ যাচাই',
    'voting_day': 'ভোটদানের দিন',
    'results': 'নির্বাচনের ফলাফল',
    'global_insights': 'গ্লোবাল ইনসাইটস',
    'issue_resolver': 'সমস্যা সমাধান',
    
    'welcome_to_voteready': 'ভোটরেডিতে স্বাগতম',
    'your_election_companion': 'আপনার সম্পূর্ণ নির্বাচন সহযোগী অ্যাপ',
    'lets_get_started': 'চলুন শুরু করি',
    'app_description': 'ভোটরেডি আপনাকে ভারতীয় নির্বাচন প্রক্রিয়া সহজে নেভিগেট করতে সাহায্য করে',
    'full_name': 'পূর্ণ নাম',
    'email_address': 'ইমেল ঠিকানা',
    'phone_number': 'ফোন নম্বর',
    'age': 'বয়স',
    'date_of_birth': 'জন্ম তারিখ',
    'gender': 'লিঙ্গ',
    'address': 'ঠিকানা',
    'city': 'শহর',
    'state': 'রাজ্য',
    'pincode': 'পিনকোড',
    'aadhaar_number': 'আধার নম্বর',
    'voter_id': 'ভোটার আইডি',
    
    'field_required': 'এই ক্ষেত্রটি আবশ্যক',
    'invalid_email': 'অনুগ্রহ করে একটি বৈধ ইমেল ঠিকানা লিখুন',
    'invalid_phone': 'অনুগ্রহ করে একটি বৈধ ফোন নম্বর লিখুন',
    'invalid_age': 'অনুগ্রহ করে একটি বৈধ বয়স লিখুন (১৮-১২০)',
    'network_error': 'নেটওয়ার্ক ত্রুটি। অনুগ্রহ করে আপনার সংযোগ পরীক্ষা করুন।',
    'server_error': 'সার্ভার ত্রুটি। অনুগ্রহ করে পরে আবার চেষ্টা করুন।',
  };

  // Add other language translations (simplified for brevity)
  static const Map<String, String> _tamilTranslations = {
    'app_name': 'வோட்ரெடி',
    'ok': 'சரி',
    'cancel': 'ரத்துசெய்',
    'save': 'சேமி',
    'delete': 'நீக்கு',
    'edit': 'திருத்து',
    'add': 'சேர்',
    'search': 'தேடு',
    'loading': 'ஏற்றுகிறது...',
    'error': 'பிழை',
    'success': 'வெற்றி',
    'retry': 'மீண்டும் முயற்சி செய்',
    'next': 'அடுத்தது',
    'previous': 'முந்தையது',
    'finish': 'முடிக்கவும்',
    'skip': 'தவிர்',
    'close': 'மூடு',
    'yes': 'ஆம்',
    'no': 'இல்லை',
    'submit': 'சமர்ப்பி',
    'clear': 'அழி',
    'reset': 'மீட்டமை',
    'refresh': 'புதுப்பி',
    'back': 'பின்',
    'home': 'வீடு',
    'settings': 'அமைப்புகள்',
    'profile': 'சுயவிவரம்',
    'logout': 'வெளியேறு',
    'login': 'உள்நுழைக',
    'register': 'பதிவுசெய்',
    
    'dashboard': 'டாஷ்போர்டு',
    'eligibility': 'தகுதி சோதனை',
    'registration': 'வாக்காளர் பதிவு',
    'verification': 'விவரங்களை சரிபார்க்க',
    'voting_day': 'வாக்களிப்பு நாள்',
    'results': 'தேர்தல் முடிவுகள்',
    'global_insights': 'உலகளாவிய நுண்ணறிவுகள்',
    'issue_resolver': 'பிரச்சினை தீர்க்கும்',
    
    'welcome_to_voteready': 'வோட்ரெடிக்கு வரவேற்றுகிறோம்',
    'your_election_companion': 'உங்கள் முழுமையான தேர்தல் துணை பயன்பாடு',
    'lets_get_started': 'வாரீயாம் தொடங்குவோம்',
    'app_description': 'வோட்ரெடி இந்திய தேர்தல் செயல்முறையை எளிதாக செய்ய உங்களுக்கு உதவுகிறது',
    'full_name': 'முழு பெயர்',
    'email_address': 'மின்னஞ்சல் முகவரி',
    'phone_number': 'தொலைபேசி எண்',
    'age': 'வயது',
    'date_of_birth': 'பிறந்த தேதி',
    'gender': 'பாலினம்',
    'address': 'முகவரி',
    'city': 'நகரம்',
    'state': 'மாநிலம்',
    'pincode': 'பின்கோட்',
    'aadhaar_number': 'ஆதார் எண்',
    'voter_id': 'வாக்காளர் ஐடி',
    
    'field_required': 'இந்த புலம் தேவை',
    'invalid_email': 'தயவுசெய்து சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்',
    'invalid_phone': 'தயவுசெய்து சரியான தொலைபேசி எண்ணை உள்ளிடவும்',
    'invalid_age': 'தயவுசெய்து சரியான வயதை உள்ளிடவும் (18-120)',
    'network_error': 'நெட்வொர்க் பிழை. தயவுசெய்து உங்கள் இணைப்பை சரிபார்க்கவும்.',
    'server_error': 'சர்வர் பிழை. தயவுசெய்து பின்னர் மீண்டும் முயற்சி செய்யவும்.',
  };

  static const Map<String, String> _teluguTranslations = {
    'app_name': 'వోట్‌రెడీ',
    'ok': 'సరే',
    'cancel': 'రద్దు చేయండి',
    'save': 'సేవ్ చేయండి',
    'delete': 'తొలగించండి',
    'edit': 'సవరించండి',
    'add': 'జోడించండి',
    'search': 'శోధించండి',
    'loading': 'లోడ్ అవుతోంది...',
    'error': 'లోపం',
    'success': 'విజయం',
    'retry': 'మళ్ళీ ప్రయత్నించండి',
    'next': 'తరువాత',
    'previous': 'ముందు',
    'finish': 'పూర్తి',
    'skip': 'దాటవేయండి',
    'close': 'మూసివేయండి',
    'yes': 'అవును',
    'no': 'వద్దు',
    'submit': 'సమర్పించండి',
    'clear': 'శుభ్రం చేయండి',
    'reset': 'రీసెట్ చేయండి',
    'refresh': 'రిఫ్రెష్ చేయండి',
    'back': 'వెనుకకు',
    'home': 'హోమ్',
    'settings': 'సెట్టింగ్‌లు',
    'profile': 'ప్రొఫైల్',
    'logout': 'లాగ్‌అవుట్',
    'login': 'లాగిన్',
    'register': 'నమోదు చేయండి',
    
    'dashboard': 'డాష్‌బోర్డ్',
    'eligibility': 'అర్హత పరిశీలన',
    'registration': 'ఓటర్ నమోదు',
    'verification': 'వివరాల నిర్ధారణ',
    'voting_day': 'ఓటింగ్ రోజు',
    'results': 'ఎన్నికల ఫలితాలు',
    'global_insights': 'గ్లోబల్ ఇన్సైట్స్',
    'issue_resolver': 'సమస్య పరిష్కారం',
    
    'welcome_to_voteready': 'వోట్‌రెడీకి స్వాగతం',
    'your_election_companion': 'మీ పూర్తి ఎన్నికల సహచర యాప్',
    'lets_get_started': 'మొదలుపెడదాం',
    'app_description': 'వోట్‌రెడీ మీకు భారతీయ ఎన్నికల ప్రక్రియను సులభంగా నావిగేట్ చేయడంలో సహాయపడుతుంది',
    'full_name': 'పూర్తి పేరు',
    'email_address': 'ఇమెయిల్ చిరునామా',
    'phone_number': 'ఫోన్ నంబర్',
    'age': 'వయస్సు',
    'date_of_birth': 'పుట్టిన తేదీ',
    'gender': 'లింగం',
    'address': 'చిరునామా',
    'city': 'నగరం',
    'state': 'రాష్ట్రం',
    'pincode': 'పిన్‌కోడ్',
    'aadhaar_number': 'ఆధార్ నంబర్',
    'voter_id': 'ఓటర్ ఐడి',
    
    'field_required': 'ఈ ఫీల్డ్ అవసరం',
    'invalid_email': 'దయచేసి చెల్లిన ఇమెయిల్ చిరునామాను నమోదు చేయండి',
    'invalid_phone': 'దయచేసి చెల్లిన ఫోన్ నంబర్‌ను నమోదు చేయండి',
    'invalid_age': 'దయచేసి చెల్లిన వయస్సును నమోదు చేయండి (18-120)',
    'network_error': 'నెట్‌వర్క్ లోపం. దయచేసి మీ కనెక్షన్‌ను తనిఖీ చేయండి.',
    'server_error': 'సర్వర్ లోపం. దయచేసి తర్వాత మళ్ళీ ప్రయత్నించండి.',
  };

  static const Map<String, String> _marathiTranslations = {
    'app_name': 'वोटरेडी',
    'ok': 'ठीक आहे',
    'cancel': 'रद्द करा',
    'save': 'जतन करा',
    'delete': 'हटवा',
    'edit': 'संपादित करा',
    'add': 'जोडा',
    'search': 'शोधा',
    'loading': 'लोड होत आहे...',
    'error': 'त्रुटी',
    'success': 'यशस्वी',
    'retry': 'पुन्हा प्रयत्न करा',
    'next': 'पुढील',
    'previous': 'आधीचे',
    'finish': 'संपन्न',
    'skip': 'वगळा',
    'close': 'बंद करा',
    'yes': 'होय',
    'no': 'नाही',
    'submit': 'सादर करा',
    'clear': 'साफ करा',
    'reset': 'रीसेट करा',
    'refresh': 'रिफ्रेश करा',
    'back': 'मागे',
    'home': 'होम',
    'settings': 'सेटिंग्ज',
    'profile': 'प्रोफाइल',
    'logout': 'लॉगआउट',
    'login': 'लॉगिन',
    'register': 'नोंदणी करा',
    
    'dashboard': 'डॅशबोर्ड',
    'eligibility': 'पात्रता तपासणी',
    'registration': 'मतदार नोंदणी',
    'verification': 'तपशील तपासणी',
    'voting_day': 'मतदान दिवस',
    'results': 'निवडणूक परिणाम',
    'global_insights': 'ग्लोबल इनसाइट्स',
    'issue_resolver': 'समस्या निराकरण',
    
    'welcome_to_voteready': 'वोटरेडीमध्ये आपले स्वागत आहे',
    'your_election_companion': 'आपले संपूर्ण निवडणूक साथी अॅप',
    'lets_get_started': 'चला सुरुवात करूया',
    'app_description': 'वोटरेडी आपल्याला भारतीय निवडणूक प्रक्रियेत सहजपणे नॅव्हिगेट करण्यास मदत करते',
    'full_name': 'पूर्ण नाव',
    'email_address': 'ईमेल पत्ता',
    'phone_number': 'फोन नंबर',
    'age': 'वय',
    'date_of_birth': 'जन्मतारीख',
    'gender': 'लिंग',
    'address': 'पत्ता',
    'city': 'शहर',
    'state': 'राज्य',
    'pincode': 'पिनकोड',
    'aadhaar_number': 'आधार क्रमांक',
    'voter_id': 'मतदार ओळखपत्र',
    
    'field_required': 'हे फील्ड आवश्यक आहे',
    'invalid_email': 'कृपया वैध ईमेल पत्ता प्रविष्ट करा',
    'invalid_phone': 'कृपया वैध फोन नंबर प्रविष्ट करा',
    'invalid_age': 'कृपया वैध वय प्रविष्ट करा (18-120)',
    'network_error': 'नेटवर्क त्रुटी. कृपया आपले जोडणी तपासा.',
    'server_error': 'सर्व्हर त्रुटी. कृपया नंतर पुन्हा प्रयत्न करा.',
  };

  static const Map<String, String> _gujaratiTranslations = {
    'app_name': 'વોટરેડી',
    'ok': 'બરાબર',
    'cancel': 'રદ કરો',
    'save': 'સાચવો',
    'delete': 'કાઢી નાખો',
    'edit': 'સંપાદિત કરો',
    'add': 'ઉમેરો',
    'search': 'શોધો',
    'loading': 'લોડ થઈ રહ્યું છે...',
    'error': 'ભૂલ',
    'success': 'સફળતા',
    'retry': 'ફરીથી પ્રયાસ કરો',
    'next': 'આગળનું',
    'previous': 'પહેલાંનું',
    'finish': 'પૂર્ણ',
    'skip': 'છોડો',
    'close': 'બંધ કરો',
    'yes': 'હા',
    'no': 'ના',
    'submit': 'સબમિટ કરો',
    'clear': 'સાફ કરો',
    'reset': 'રીસેટ કરો',
    'refresh': 'રિફ્રેશ કરો',
    'back': 'પાછળ',
    'home': 'હોમ',
    'settings': 'સેટિંગ્સ',
    'profile': 'પ્રોફાઇલ',
    'logout': 'લોગઆઉટ',
    'login': 'લોગિન',
    'register': 'નોંધણી કરો',
    
    'dashboard': 'ડેશબોર્ડ',
    'eligibility': 'લાયકાત તપાસણી',
    'registration': 'મતદાર નોંધણી',
    'verification': 'વિગતો ચકાસણી',
    'voting_day': 'મતદાન દિવસ',
    'results': 'ચૂંટણી પરિણામો',
    'global_insights': 'ગ્લોબલ ઇનસાઇટ્સ',
    'issue_resolver': 'સમસ્યા નિરાકરણ',
    
    'welcome_to_voteready': 'વોટરેડીમાં આપનું સ્વાગત છે',
    'your_election_companion': 'તમારું સંપૂર્ણ ચૂંટણી સાથી એપ',
    'lets_get_started': 'ચાલો શરૂ કરીએ',
    'app_description': 'વોટરેડી તમને ભારતીય ચૂંટણી પ્રક્રિયામાં સરળતાથી નેવિગેટ કરવામાં મદદ કરે છે',
    'full_name': 'પૂરું નામ',
    'email_address': 'ઈમેલ સરનામું',
    'phone_number': 'ફોન નંબર',
    'age': 'ઉંમર',
    'date_of_birth': 'જન્મ તારીખ',
    'gender': 'લિંગ',
    'address': 'સરનામું',
    'city': 'શહેર',
    'state': 'રાજ્ય',
    'pincode': 'પિનકોડ',
    'aadhaar_number': 'આધાર નંબર',
    'voter_id': 'મતદાર આઈડી',
    
    'field_required': 'આ ફીલ્ડ આવશ્યક છે',
    'invalid_email': 'કૃપા કરીને માન્ય ઈમેલ સરનામું દાખલ કરો',
    'invalid_phone': 'કૃપા કરીને માન્ય ફોન નંબર દાખલ કરો',
    'invalid_age': 'કૃપા કરીને માન્ય ઉંમર દાખલ કરો (18-120)',
    'network_error': 'નેટવર્ક ભૂલ. કૃપા કરીને તમારું જોડાણ તપાસો.',
    'server_error': 'સર્વર ભૂલ. કૃપા કરીને પછી ફરીથી પ્રયાસ કરો.',
  };

  static const Map<String, String> _kannadaTranslations = {
    'app_name': 'ವೋಟ್‌ರೆಡಿ',
    'ok': 'ಸರಿ',
    'cancel': 'ರದ್ದು ಮಾಡಿ',
    'save': 'ಉಳಿಸಿ',
    'delete': 'ಅಳಿಸಿ',
    'edit': 'ಸಂಪಾದಿಸಿ',
    'add': 'ಸೇರಿಸಿ',
    'search': 'ಹುಡುಕಿ',
    'loading': 'ಲೋಡ್ ಆಗುತ್ತಿದೆ...',
    'error': 'ದೋಷ',
    'success': 'ಯಶಸ್ಸು',
    'retry': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
    'next': 'ಮುಂದಿನ',
    'previous': 'ಹಿಂದಿನ',
    'finish': 'ಪೂರ್ಣಗೊಳಿಸಿ',
    'skip': 'ಬಿಟ್ಟಿ',
    'close': 'ಮುಚ್ಚಿ',
    'yes': 'ಹೌದು',
    'no': 'ಇಲ್ಲ',
    'submit': 'ಸಲ್ಲಿಸಿ',
    'clear': 'ತೆರವುಗೊಳಿಸಿ',
    'reset': 'ಮರುಹೊಂದಿಸಿ',
    'refresh': 'ರಿಫ್ರೆಶ್ ಮಾಡಿ',
    'back': 'ಹಿಂದಕ್ಕೆ',
    'home': 'ಮನೆ',
    'settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
    'profile': 'ಪ್ರೊಫೈಲ್',
    'logout': 'ಲಾಗ್‌ಔಟ್',
    'login': 'ಲಾಗಿನ್',
    'register': 'ನೋಂದಣಿ ಮಾಡಿ',
    
    'dashboard': 'ಡ್ಯಾಶ್‌ಬೋರ್ಡ್',
    'eligibility': 'ಅರ್ಹತೆ ಪರೀಕ್ಷೆ',
    'registration': 'ಮತದಾರ ನೋಂದಣಿ',
    'verification': 'ವಿವರಗಳ ಪರಿಶೀಲನೆ',
    'voting_day': 'ಮತದಾನ ದಿನ',
    'results': 'ಚುನಾವಣಿ ಫಲಿತಾಂಶಗಳು',
    'global_insights': 'ಜಾಗತಿಕ ಒಳನೋಟಗಳು',
    'issue_resolver': 'ಸಮಸ್ಯೆ ಪರಿಹಾರ',
    
    'welcome_to_voteready': 'ವೋಟ್‌ರೆಡಿಗೆ ಸ್ವಾಗತ',
    'your_election_companion': 'ನಿಮ್ಮ ಸಂಪೂರ್ಣ ಚುನಾವಣಿ ಸಹಚರ ಅಪ್ಲಿಕೇಶನ್',
    'lets_get_started': 'ಆರಂಭಿಸೋಣ',
    'app_description': 'ವೋಟ್‌ರೆಡಿ ನಿಮಗೆ ಭಾರತೀಯ ಚುನಾವಣಿ ಪ್ರಕ್ರಿಯೆಯನ್ನು ಸುಲಭವಾಗಿ ನ್ಯಾವಿಗೇಟ್ ಮಾಡಲು ಸಹಾಯ ಮಾಡುತ್ತದೆ',
    'full_name': 'ಪೂರ್ಣ ಹೆಸರು',
    'email_address': 'ಇಮೇಲ್ ವಿಳಾಸ',
    'phone_number': 'ಫೋನ್ ಸಂಖ್ಯೆ',
    'age': 'ವಯಸ್ಸು',
    'date_of_birth': 'ಜನ್ಮ ದಿನಾಂಕ',
    'gender': 'ಲಿಂಗ',
    'address': 'ವಿಳಾಸ',
    'city': 'ನಗರ',
    'state': 'ರಾಜ್ಯ',
    'pincode': 'ಪಿನ್‌ಕೋಡ್',
    'aadhaar_number': 'ಆಧಾರ್ ಸಂಖ್ಯೆ',
    'voter_id': 'ಮತದಾರ ಐಡಿ',
    
    'field_required': 'ಈ ಕ್ಷೇತ್ರ ಅಗತ್ಯವಿದೆ',
    'invalid_email': 'ದಯವಿಟ್ಟು ಮಾನ್ಯವಾದ ಇಮೇಲ್ ವಿಳಾಸವನ್ನು ನಮೂದಿಸಿ',
    'invalid_phone': 'ದಯವಿಟ್ಟು ಮಾನ್ಯವಾದ ಫೋನ್ ಸಂಖ್ಯೆಯನ್ನು ನಮೂದಿಸಿ',
    'invalid_age': 'ದಯವಿಟ್ಟು ಮಾನ್ಯವಾದ ವಯಸ್ಸನ್ನು ನಮೂದಿಸಿ (18-120)',
    'network_error': 'ನೆಟ್‌ವರ್ಕ್ ದೋಷ. ದಯವಿಟ್ಟು ನಿಮ್ಮ ಸಂಪರ್ಕವನ್ನು ಪರಿಶೀಲಿಸಿ.',
    'server_error': 'ಸರ್ವರ್ ದೋಷ. ದಯವಿಟ್ಟು ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
  };

  static const Map<String, String> _malayalamTranslations = {
    'app_name': 'വോട്ടറെഡി',
    'ok': 'ശരി',
    'cancel': 'റദ്ദാക്കുക',
    'save': 'സംരക്ഷിക്കുക',
    'delete': 'നീക്കം ചെയ്യുക',
    'edit': 'എഡിറ്റ് ചെയ്യുക',
    'add': 'ചേർക്കുക',
    'search': 'തിരയുക',
    'loading': 'ലോഡ് ചെയ്യുന്നു...',
    'error': 'പിശക്',
    'success': 'വിജയം',
    'retry': 'വീണ്ടും ശ്രമിക്കുക',
    'next': 'അടുത്തത്',
    'previous': 'മുമ്പത്തെ',
    'finish': 'പൂർത്തിയാക്കുക',
    'skip': 'ഒഴിവാക്കുക',
    'close': 'അടയ്ക്കുക',
    'yes': 'അതെ',
    'no': 'അല്ല',
    'submit': 'സമർപ്പിക്കുക',
    'clear': 'വൃത്തിയാക്കുക',
    'reset': 'പുനഃസജ്ജമാക്കുക',
    'refresh': 'പുതുക്കുക',
    'back': 'പിന്നിലേക്ക്',
    'home': 'വീട്',
    'settings': 'ക്രമീകരണങ്ങൾ',
    'profile': 'പ്രൊഫൈൽ',
    'logout': 'ലോഗ്‌ഔട്ട്',
    'login': 'ലോഗിൻ',
    'register': 'രജിസ്റ്റർ ചെയ്യുക',
    
    'dashboard': 'ഡാഷ്ബോർഡ്',
    'eligibility': 'യോഗ്യതാ പരിശോധന',
    'registration': 'വോട്ടർ രജിസ്ട്രേഷൻ',
    'verification': 'വിശദാംശങ്ങൾ പരിശോധിക്കുക',
    'voting_day': 'വോട്ടിംഗ് ദിവസം',
    'results': 'തെരഞ്ഞെടുപ്പ് ഫലങ്ങൾ',
    'global_insights': 'ആഗോള ഉൾകാഴ്ചകൾ',
    'issue_resolver': 'പ്രശ്നപരിഹാരം',
    
    'welcome_to_voteready': 'വോട്ടറെഡിയിലേക്ക് സ്വാഗതം',
    'your_election_companion': 'നിങ്ങളുടെ പൂർണ്ണമായ തെരഞ്ഞെടുപ്പ് കൂട്ടാളി ആപ്പ്',
    'lets_get_started': 'തുടങ്ങാം',
    'app_description': 'വോട്ടറെഡി നിങ്ങളെ ഇന്ത്യൻ തെരഞ്ഞെടുപ്പ് പ്രക്രിയ എളുപ്പത്തിൽ നാവിഗേറ്റ് ചെയ്യാൻ സഹായിക്കുന്നു',
    'full_name': 'പൂർണ്ണനാമം',
    'email_address': 'ഇമെയിൽ വിലാസം',
    'phone_number': 'ഫോൺ നമ്പർ',
    'age': 'പ്രായം',
    'date_of_birth': 'ജനനത്തീയതി',
    'gender': 'ലിംഗഭേദം',
    'address': 'വിലാസം',
    'city': 'നഗരം',
    'state': 'സംസ്ഥാനം',
    'pincode': 'പിൻകോഡ്',
    'aadhaar_number': 'ആധാർ നമ്പർ',
    'voter_id': 'വോട്ടർ ഐഡി',
    
    'field_required': 'ഈ ഫീൽഡ് ആവശ്യമാണ്',
    'invalid_email': 'ദയവായി സാധുവായ ഇമെയിൽ വിലാസം നൽകുക',
    'invalid_phone': 'ദയവായി സാധുവായ ഫോൺ നമ്പർ നൽകുക',
    'invalid_age': 'ദയവായി സാധുവായ പ്രായം നൽകുക (18-120)',
    'network_error': 'നെറ്റ്‌വർക്ക് പിശക്. ദയവായി നിങ്ങളുടെ കണക്ഷൻ പരിശോധിക്കുക.',
    'server_error': 'സെർവർ പിശക്. ദയവായി പിന്നീട് വീണ്ടും ശ്രമിക്കുക.',
  };

  static const Map<String, String> _punjabiTranslations = {
    'app_name': 'ਵੋਟਰੇਡੀ',
    'ok': 'ਠੀਕ ਹੈ',
    'cancel': 'ਰੱਦ ਕਰੋ',
    'save': 'ਸੰਭਾਲੋ',
    'delete': 'ਹਟਾਓ',
    'edit': 'ਸੰਪਾਦਿਤ ਕਰੋ',
    'add': 'ਸ਼ਾਮਲ ਕਰੋ',
    'search': 'ਖੋਜੋ',
    'loading': 'ਲੋਡ ਹੋ ਰਿਹਾ ਹੈ...',
    'error': 'ਗਲਤੀ',
    'success': 'ਸਫਲਤਾ',
    'retry': 'ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ',
    'next': 'ਅਗਲਾ',
    'previous': 'ਪਿਛਲਾ',
    'finish': 'ਮੁਕੰਮਲ',
    'skip': 'ਛੱਡੋ',
    'close': 'ਬੰਦ ਕਰੋ',
    'yes': 'ਹਾਂ',
    'no': 'ਨਹੀਂ',
    'submit': 'ਜਮ੍ਹਾਂ ਕਰੋ',
    'clear': 'ਸਾਫ਼ ਕਰੋ',
    'reset': 'ਰੀਸੈਟ ਕਰੋ',
    'refresh': 'ਤਾਜ਼ਾ ਕਰੋ',
    'back': 'ਪਿੱਛੇ',
    'home': 'ਘਰ',
    'settings': 'ਸੈਟਿੰਗਾਂ',
    'profile': 'ਪ੍ਰੋਫਾਈਲ',
    'logout': 'ਲਾਗਆਊਟ',
    'login': 'ਲਾਗਇਨ',
    'register': 'ਰਜਿਸਟਰ ਕਰੋ',
    
    'dashboard': 'ਡੈਸ਼ਬੋਰਡ',
    'eligibility': 'ਯੋਗਤਾ ਜਾਂਚ',
    'registration': 'ਵੋਟਰ ਰਜਿਸਟ੍ਰੇਸ਼ਨ',
    'verification': 'ਵੇਰਨਾ ਪੁਸ਼ਟੀ ਕਰੋ',
    'voting_day': 'ਵੋਟਿੰਗ ਦਿਨ',
    'results': 'ਚੋਣ ਨਤੀਜੇ',
    'global_insights': 'ਗਲੋਬਲ ਇਨਸਾਈਟਸ',
    'issue_resolver': 'ਮੁੱਦਾ ਹੱਲ ਕਰਨਾ',
    
    'welcome_to_voteready': 'ਵੋਟਰੇਡੀ ਵਿੱਚ ਤੁਹਾਡਾ ਸਵਾਗਤ ਹੈ',
    'your_election_companion': 'ਤੁਹਾਡਾ ਪੂਰਾ ਚੋਣ ਸਾਥੀ ਐਪ',
    'lets_get_started': 'ਚਲੋ ਸ਼ੁਰੂ ਕਰੀਏ',
    'app_description': 'ਵੋਟਰੇਡੀ ਤੁਹਾਨੂੰ ਭਾਰਤੀ ਚੋਣ ਪ੍ਰਕਿਰਿਆ ਵਿੱਚ ਆਸਾਨੀ ਨਾਲ ਨੈਵੀਗੇਟ ਕਰਨ ਵਿੱਚ ਮਦਦ ਕਰਦਾ ਹੈ',
    'full_name': 'ਪੂਰਾ ਨਾਮ',
    'email_address': 'ਈਮੇਲ ਪਤਾ',
    'phone_number': 'ਫੋਨ ਨੰਬਰ',
    'age': 'ਉਮਰ',
    'date_of_birth': 'ਜਨਮ ਮਿਤੀ',
    'gender': 'ਲਿੰਗ',
    'address': 'ਪਤਾ',
    'city': 'ਸ਼ਹਿਰ',
    'state': 'ਰਾਜ',
    'pincode': 'ਪਿੰਨਕੋਡ',
    'aadhaar_number': 'ਆਧਾਰ ਨੰਬਰ',
    'voter_id': 'ਵੋਟਰ ਆਈਡੀ',
    
    'field_required': 'ਇਹ ਖੇਤਰ ਲੋੜੀਂਦਾ ਹੈ',
    'invalid_email': 'ਕਿਰਪਾ ਕਰਕੇ ਇੱਕ ਵੈਧ ਈਮੇਲ ਪਤਾ ਦਾਖਲ ਕਰੋ',
    'invalid_phone': 'ਕਿਰਪਾ ਕਰਕੇ ਇੱਕ ਵੈਧ ਫੋਨ ਨੰਬਰ ਦਾਖਲ ਕਰੋ',
    'invalid_age': 'ਕਿਰਪਾ ਕਰਕੇ ਇੱਕ ਵੈਧ ਉਮਰ ਦਾਖਲ ਕਰੋ (18-120)',
    'network_error': 'ਨੈੱਟਵਰਕ ਗਲਤੀ। ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਕਨੈਕਸ਼ਨ ਚੈੱਕ ਕਰੋ।',
    'server_error': 'ਸਰਵਰ ਗਲਤੀ। ਕਿਰਪਾ ਕਰਕੇ ਬਾਅਦ ਵਿੱਚ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
  };
}

// Extension for easy translation
extension I18nExtension on String {
  String tr({Map<String, String>? params}) {
    return I18nService().translate(this, params: params);
  }
}

// I18n provider for Riverpod
final i18nServiceProvider = Provider<I18nService>((ref) {
  return I18nService();
});

// I18n-aware widget
class LocalizedWidget extends ConsumerWidget {
  final Widget child;

  const LocalizedWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18nService = ref.watch(i18nServiceProvider);
    
    return Directionality(
      textDirection: _getTextDirection(i18nService.currentLanguage),
      child: child,
    );
  }

  TextDirection _getTextDirection(AppLanguage language) {
    // Most Indian languages are left-to-right
    // Add RTL languages if needed in the future
    return TextDirection.ltr;
  }
}
