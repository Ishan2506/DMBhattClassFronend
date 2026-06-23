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
    if (_history.isEmpty) return false;
    final examId = exam['_id'].toString();
    return _history.any((h) => h['examId'].toString() == examId);
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

      // Format standard string to get numerical value (e.g. "9th" -> "9")
      String normStd = "10";
      if (_userStandard != null) {
        final match = RegExp(r'(\d+)').firstMatch(_userStandard!);
        if (match != null) {
          normStd = match.group(1)!;
        }
      }

      // Fetch valid subjects list using AcademicConstants
      final loadedSubjects = AcademicConstants.getSubjectsForStudent(
        board: _userBoard ?? "GSEB",
        std: normStd,
        stream: _userStream,
      );

      // Fetch Match Following Exams
      final response = await ApiService.getAllMatchFollowingExams();
      if (response.statusCode == 200) {
        _allExercises = jsonDecode(response.body);
      }

      setState(() {
        _subjects = loadedSubjects;
        _updateUnitsAndTitles();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading profile or subjects: $e");
      setState(() {
        _subjects = ["Science", "Maths", "English", "Physics", "Chemistry", "Biology"];
        _isLoading = false;
      });
    }
  }

  // Normalizes the stored user standard to search matches
  String get _normalizedUserStd {
    if (_userStandard == null) return "10";
    final match = RegExp(r'(\d+)').firstMatch(_userStandard!);
    return match != null ? match.group(1)! : _userStandard!;
  }

  void _updateUnitsAndTitles() {
    final currentStd = _normalizedUserStd;
    List<String> units = [];
    List<String> titles = [];

    var filtered = _allExercises.where((ex) {
      final String std = ex['std'].toString();
      return std == currentStd;
    }).toList();

    if (_selectedSubject != null) {
      filtered = filtered.where((ex) => ex['subject'] == _selectedSubject).toList();
    }

    units = filtered.map((e) => e['unit'].toString()).toSet().toList();

    var unitFiltered = filtered;
    if (_selectedUnit != null) {
      unitFiltered = filtered.where((ex) => ex['unit'].toString() == _selectedUnit).toList();
    }

    titles = unitFiltered.map((e) => e['title']?.toString() ?? e['unit']?.toString() ?? '').where((t) => t.isNotEmpty).toSet().toList();

    setState(() {
      _units = units;
      _titles = titles;
      if (!_units.contains(_selectedUnit)) _selectedUnit = null;
      if (!_titles.contains(_selectedTitle)) _selectedTitle = null;
    });
  }

  // Get matching exercises filtered by standard and subject
  List<dynamic> get _filteredExercises {
    final currentStd = _normalizedUserStd;
    var result = _allExercises.where((ex) {
      final String std = ex['std'].toString();
      return std == currentStd;
    }).toList();

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

    return Scaffold(
      appBar: CustomAppBar(
        title: _getTranslation(context, 'title'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const CustomLoader()
          : Column(
              children: [
                // Dropdown Filter Area
                Container(
                  color: isDark ? const Color(0xFF1A2340) : Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    children: [
                      CustomDropdown<String>(
                        labelText: _getTranslation(context, 'subject'),
                        hintText: _getTranslation(context, 'allSubjects'),
                        value: _selectedSubject,
                        items: _subjects,
                        itemLabelBuilder: (String item) => item,
                        onChanged: (val) {
                          setState(() {
                            _selectedSubject = val;
                            _updateUnitsAndTitles();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomDropdown<String>(
                        labelText: "Unit",
                        hintText: "All Units",
                        value: _selectedUnit,
                        items: _units,
                        itemLabelBuilder: (String item) => item,
                        onChanged: (val) {
                          setState(() {
                            _selectedUnit = val;
                            _updateUnitsAndTitles();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomDropdown<String>(
                        labelText: "Exercise Title",
                        hintText: "All Titles",
                        value: _selectedTitle,
                        items: _titles,
                        itemLabelBuilder: (String item) => item,
                        onChanged: (val) {
                          setState(() {
                            _selectedTitle = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Heading Explanation Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: primary.withOpacity(0.05),
                  child: Text(
                    _getTranslation(context, 'matchAll'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Spacer
                const Spacer(),
                // Start Button Section
                if (_filteredExercises.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary,
                            primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final exercise = _filteredExercises[0];
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
                  )
                else
                  Expanded(child: _buildEmptyState(isDark)),
              ],
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.compare_arrows_rounded,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _getTranslation(context, 'noExercises'),
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

}
