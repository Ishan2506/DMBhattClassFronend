import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/utils/academic_constants.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/match_following_game_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/match_following_history_screen.dart';

class MatchFollowingSelectionScreen extends StatefulWidget {
  const MatchFollowingSelectionScreen({super.key});

  @override
  State<MatchFollowingSelectionScreen> createState() => _MatchFollowingSelectionScreenState();
}

class _MatchFollowingSelectionScreenState extends State<MatchFollowingSelectionScreen> {
  bool _isLoading = true;
  String? _selectedSubject;
  String? _selectedUnit;
  String? _selectedTitle;
  List<String> _subjects = [];
  List<String> _units = [];
  List<String> _titles = [];

  String? _userStandard;
  String? _userBoard;
  String? _userStream;
  String? _userMedium;

  List<dynamic> _allExercises = [];

  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchExams();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await ApiService.getDashboardData();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['examResults'] ?? [];
        if (mounted) {
          setState(() {
            _history = results.where((e) => e['type'] == 'MATCH_FOLLOWING').toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching match following history: $e");
    }
  }

  bool _isTaken(dynamic exam) {
    return false;
  }

  Future<void> _fetchExams() async {
    await _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userStandard = prefs.getString('std');
      _userBoard = prefs.getString('board');
      _userStream = prefs.getString('stream');
      _userMedium = prefs.getString('medium');

      // Fetch profile to get real-time info if online
      final profileResponse = await ApiService.getProfile(forceRefresh: true);
      if (profileResponse.statusCode == 200) {
        final data = jsonDecode(profileResponse.body);
        final profile = data['profile'];
        if (profile != null) {
          _userStandard = profile['std']?.toString() ?? _userStandard;
          _userBoard = profile['board']?.toString() ?? _userBoard;
          _userStream = profile['stream']?.toString() ?? _userStream;
          _userMedium = profile['medium']?.toString() ?? _userMedium;
        }
      }

      // Backward compatibility: If the DB has "11 Science", split it.
      if (_userStandard != null && _userStandard!.contains(' ')) {
         final parts = _userStandard!.split(' ');
         _userStandard = parts[0];
         if (_userStream == null || _userStream == '-' || _userStream!.isEmpty) {
             _userStream = parts.skip(1).join(' ');
         }
      }

      // Fetch Match Following Exams
      final response = await ApiService.getAllMatchFollowingExams(
        std: _userStandard,
        medium: _userMedium,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        _allExercises = data.where((e) {
          final examStream = e['stream']?.toString();
          
          // Match Stream if Std is 11 or 12
          if (_userStandard != null) {
            final numMatch = RegExp(r'\d+').firstMatch(_userStandard!);
            int stdNum = 0;
            if (numMatch != null) {
               stdNum = int.tryParse(numMatch.group(0) ?? '0') ?? 0;
            }
            if (stdNum >= 11) {
               if (_userStream != null && examStream != null && examStream != _userStream && examStream.isNotEmpty && examStream != "-") return false;
            }
          }
          return true;
        }).toList();
      }

      final activeSubjects = _allExercises
          .map((e) => e['subject'].toString())
          .toSet()
          .toList();

      setState(() {
        _subjects = activeSubjects;
        _units = [];
        _titles = [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading profile or subjects: $e");
      setState(() {
        _subjects = [];
        _units = [];
        _titles = [];
        _isLoading = false;
      });
    }
  }

  void _onSubjectChanged(String? subject) {
    setState(() {
      _selectedSubject = subject;
      _selectedUnit = null;
      _selectedTitle = null;
      _units = [];
      _titles = [];

      if (subject != null) {
        _units = _allExercises
            .where((ex) => ex['subject'] == subject)
            .map((ex) => ex['unit']?.toString() ?? '1')
            .toSet()
            .toList();
      }
    });
  }

  void _onUnitChanged(String? unit) {
    String? newTitle;
    List<String> newTitles = [];

    if (unit != null) {
      newTitles = _allExercises
          .where((ex) =>
              ex['subject'] == _selectedSubject &&
              (ex['unit']?.toString() ?? '1') == unit)
          .map((ex) => ex['title']?.toString() ?? ex['unit']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();

      if (newTitles.length == 1) {
        newTitle = newTitles.first;
      }
    }

    setState(() {
      _selectedUnit = unit;
      _titles = newTitles;
      _selectedTitle = null;
    });

    if (newTitle != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onTitleChanged(newTitle);
        }
      });
    }
  }

  void _onTitleChanged(String? title) {
    setState(() {
      _selectedTitle = title;
    });
  }

  // Get matching exercises filtered by standard and subject
  List<dynamic> get _filteredExercises {
    var result = _allExercises;

    if (_selectedSubject != null) {
      result = result.where((ex) => ex['subject'] == _selectedSubject).toList();
    }

    if (_selectedUnit != null) {
      result = result.where((ex) => ex['unit'].toString() == _selectedUnit).toList();
    }

    if (_selectedTitle != null) {
      result = result.where((ex) => (ex['title']?.toString() ?? ex['unit']?.toString() ?? '') == _selectedTitle).toList();
    }

    return result;
  }

  String _getTranslation(BuildContext context, String key) {
    // only english language currenyly we are working on
    final locale = Localizations.localeOf(context).languageCode;
    const translations = {
      'en': {
        'title': 'Match the Following',
        'subject': 'Subject',
        'allSubjects': 'All Subjects',
        'noExercises': 'No matching exercises found',
        'selectSubject': 'Filter by Subject',
        'pairs': 'Pairs',
        'start': 'START',
        'matchAll': 'Connect the correct pairs from Column A to Column B.',
      },
      'gu': {
        'title': 'α¬£α½ïα¬íα¬òα¬╛ α¬£α½ïα¬íα½ï',
        'subject': 'α¬╡α¬┐α¬╖α¬»',
        'allSubjects': 'α¬¼α¬ºα¬╛ α¬╡α¬┐α¬╖α¬»α½ï',
        'noExercises': 'α¬òα½ïα¬ê α¬£α½ïα¬íα¬òα¬╛ α¬«α¬│α½ìα¬»α¬╛ α¬¿α¬Ñα½Ç',
        'selectSubject': 'α¬╡α¬┐α¬╖α¬» α¬¬α¬╕α¬éα¬ª α¬òα¬░α½ï',
        'pairs': 'α¬£α½ïα¬íα½Çα¬ô',
        'start': 'α¬╢α¬░α½é α¬òα¬░α½ï',
        'matchAll': 'α¬òα½ëα¬▓αñ« A α¬«α¬╛α¬éα¬Ñα½Ç α¬òα½ëα¬▓α¬« B α¬╕α¬╛α¬Ñα½ç α¬╕α¬╛α¬Üα½Ç α¬£α½ïα¬íα½Ç α¬£α½ïα¬íα½ï.',
      },
      'hi': {
        'title': 'αñ╕αñ╣αÑÇ αñ«αñ┐αñ▓αñ╛αñ¿ αñòαñ░αÑçαñé',
        'subject': 'αñ╡αñ┐αñ╖αñ»',
        'allSubjects': 'αñ╕αñ¡αÑÇ αñ╡αñ┐αñ╖αñ»',
        'noExercises': 'αñòαÑïαñê αñ«αñ┐αñ▓αñ╛αñ¿ αñàαñ¡αÑìαñ»αñ╛αñ╕ αñ¿αñ╣αÑÇαñé αñ«αñ┐αñ▓αñ╛',
        'selectSubject': 'αñ╡αñ┐αñ╖αñ» αñªαÑìαñ╡αñ╛αñ░αñ╛ αñ½αñ╝αñ┐αñ▓αÑìαñƒαñ░ αñòαñ░αÑçαñé',
        'pairs': 'αñ£αÑïαñíαñ╝αÑç',
        'start': 'αñ╢αÑüαñ░αÑé αñòαñ░αÑçαñé',
        'matchAll': 'αñòαÑëαñ▓αñ« A αñ╕αÑç αñòαÑëαñ▓αñ« B αñòαÑç αñ╕αñ╣αÑÇ αñ£αÑïαñíαñ╝αÑç αñ«αñ┐αñ▓αñ╛αñÅαñüαÑñ',
      },
      'mr': {
        'title': 'αñ»αÑïαñùαÑìαñ» αñ£αÑïαñíαÑìαñ»αñ╛ αñ£αÑüαñ│αñ╡αñ╛',
        'subject': 'αñ╡αñ┐αñ╖αñ»',
        'allSubjects': 'αñ╕αñ░αÑìαñ╡ αñ╡αñ┐αñ╖αñ»',
        'noExercises': 'αñòαÑïαñúαññαÑìαñ»αñ╛αñ╣αÑÇ αñ£αÑïαñíαÑìαñ»αñ╛ αñåαñóαñ│αñ▓αÑìαñ»αñ╛ αñ¿αñ╛αñ╣αÑÇαññ',
        'selectSubject': 'αñ╡αñ┐αñ╖αñ» αñ¿αñ┐αñ╡αñíαñ╛',
        'pairs': 'αñ£αÑïαñíαÑìαñ»αñ╛',
        'start': 'αñ╕αÑüαñ░αÑé αñòαñ░αñ╛',
        'matchAll': 'αñ╕αÑìαññαñéαñ¡ A αñ«αñºαÑÇαñ▓ αñ»αÑïαñùαÑìαñ» αñ£αÑïαñíαÑìαñ»αñ╛ αñ╕αÑìαññαñéαñ¡ B αñ╢αÑÇ αñ£αÑüαñ│αñ╡αñ╛.',
      },
      'ta': {
        'title': 'α«¬α»èα«░α»üα«ñα»ìα«ñα»üα«ò',
        'subject': 'α«¬α«╛α«ƒα««α»ì',
        'allSubjects': 'α«àα«⌐α»êα«ñα»ìα«ñα»ü α«¬α«╛α«ƒα«Öα»ìα«òα«│α»üα««α»ì',
        'noExercises': 'α«¬α»èα«░α»üα«¿α»ìα«ñα»üα««α»ì α«¬α«»α«┐α«▒α»ìα«Üα«┐α«òα«│α»ì α«Äα«ñα»üα«╡α»üα««α»ì α«çα«▓α»ìα«▓α»ê',
        'selectSubject': 'α«¬α«╛α«ƒα«ñα»ìα«ñα»êα«ñα»ì α«ñα»çα«░α»ìα«¿α»ìα«ñα»åα«ƒα»üα«òα»ìα«òα«╡α»üα««α»ì',
        'pairs': 'α«£α»ïα«ƒα«┐α«òα«│α»ì',
        'start': 'α«ñα»èα«ƒα«Öα»ìα«òα»ü',
        'matchAll': 'α«¿α»åα«ƒα»üα«╡α«░α«┐α«Üα»ê A α«▓α«┐α«░α»üα«¿α»ìα«ñα»ü α«¿α»åα«ƒα»üα«╡α«░α«┐α«Üα»ê B α«çα«⌐α»ì α«Üα«░α«┐α«»α«╛α«⌐ α«£α»ïα«ƒα«┐α«òα«│α»ê α«çα«úα»êα«òα»ìα«òα«╡α»üα««α»ì.',
      }
    };
    final langMap = translations[locale] ?? translations['en']!;
    return langMap[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final exerciseSelected = _selectedTitle != null && _filteredExercises.isNotEmpty;

    return Scaffold(
      appBar: CustomAppBar(
        title: _getTranslation(context, 'title'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MatchFollowingHistoryScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const CustomLoader()
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomDropdown<String>(
                    labelText: _getTranslation(context, 'subject'),
                    hintText: _getTranslation(context, 'selectSubject'),
                    value: _selectedSubject,
                    items: _subjects,
                    itemLabelBuilder: (String item) => item,
                    onChanged: _onSubjectChanged,
                  ),
                  const SizedBox(height: 16),
                  CustomDropdown<String>(
                    labelText: "Unit",
                    hintText: "Select Unit",
                    value: _selectedUnit,
                    items: _units,
                    itemLabelBuilder: (String item) => item,
                    onChanged: _onUnitChanged,
                  ),
                  const SizedBox(height: 16),
                  CustomDropdown<String>(
                    labelText: "Exercise Title",
                    hintText: "Select Title",
                    value: _selectedTitle,
                    items: _titles,
                    itemLabelBuilder: (String item) => item,
                    onChanged: _onTitleChanged,
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: !exerciseSelected
                          ? null
                          : LinearGradient(
                              colors: [
                                primary,
                                primary.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: !exerciseSelected
                          ? []
                          : [
                              BoxShadow(
                                color: primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed: !exerciseSelected
                          ? null
                          : () {
                              final exercise = _filteredExercises[0];
                              
                              if (_isTaken(exercise)) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Already Taken"),
                                    content: const Text("You have already performed this exam. Students can only take each exam once."),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("OK"),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MatchFollowingGameScreen(
                                    exerciseId: exercise['_id'] as String,
                                    title: (exercise['title']?.toString().trim().isNotEmpty ?? false)
                                        ? exercise['title'].toString()
                                        : (exercise['unit']?.toString() ?? 'Match the Following'),
                                    subject: exercise['subject']?.toString() ?? '',
                                    pairsData: List<Map<String, String>>.from(
                                      (exercise['pairs'] as List).map(
                                        (p) => {
                                          "left": (p['left'] ?? "").toString(),
                                          "right": (p['right'] ?? "").toString(),
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ).then((_) => _fetchHistory());
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.grey.shade400,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "START EXERCISE",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
