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
  List<String> _subjects = [];

  String? _userStandard;
  String? _userBoard;
  String? _userStream;
  String? _userMedium;

  // Local matching data store
  final List<Map<String, dynamic>> _allExercises = const [
    {
      "id": "sci_cell_org",
      "subject": "Science",
      "std": ["6", "7", "8", "9", "10"],
      "title": "Cell Organelles & Functions",
      "description": "Match each organelle to its vital cellular function.",
      "pairs": [
        {"left": "Mitochondria", "right": "Powerhouse of the Cell"},
        {"left": "Ribosomes", "right": "Protein Synthesis"},
        {"left": "Lysosomes", "right": "Suicidal Bags of the Cell"},
        {"left": "Chloroplast", "right": "Photosynthesis"},
        {"left": "Nucleus", "right": "Brain of the Cell"}
      ]
    },
    {
      "id": "sci_chem_sym",
      "subject": "Science",
      "std": ["8", "9", "10"],
      "title": "Chemical Formulas",
      "description": "Match the chemical compounds with their molecular formulas.",
      "pairs": [
        {"left": "Water", "right": "H₂O"},
        {"left": "Carbon Dioxide", "right": "CO₂"},
        {"left": "Common Salt", "right": "NaCl"},
        {"left": "Glucose", "right": "C₆H₁₂O₆"},
        {"left": "Hydrochloric Acid", "right": "HCl"}
      ]
    },
    {
      "id": "sci_body_sys",
      "subject": "Science",
      "std": ["6", "7", "8", "9", "10"],
      "title": "Human Body Organs & Systems",
      "description": "Match the organ with its main system.",
      "pairs": [
        {"left": "Heart", "right": "Circulatory System"},
        {"left": "Lungs", "right": "Respiratory System"},
        {"left": "Stomach", "right": "Digestive System"},
        {"left": "Brain", "right": "Nervous System"},
        {"left": "Kidneys", "right": "Excretory System"}
      ]
    },
    {
      "id": "math_geo_area",
      "subject": "Maths",
      "std": ["6", "7", "8", "9", "10"],
      "title": "Geometry Area Formulas",
      "description": "Match the 2D shapes with their area calculation formulas.",
      "pairs": [
        {"left": "Circle", "right": "πr²"},
        {"left": "Triangle", "right": "½ × b × h"},
        {"left": "Rectangle", "right": "l × b"},
        {"left": "Square", "right": "Side²"},
        {"left": "Trapezium", "right": "½ × (a + b) × h"}
      ]
    },
    {
      "id": "math_constants",
      "subject": "Maths",
      "std": ["6", "7", "8", "9", "10"],
      "title": "Triangles & Circles Properties",
      "description": "Match shapes and angles to their geometric definitions.",
      "pairs": [
        {"left": "Right Angle", "right": "Exactly 90°"},
        {"left": "Triangle Angles Sum", "right": "Exactly 180°"},
        {"left": "Quadrilateral Angles Sum", "right": "Exactly 360°"},
        {"left": "Perimeter of Circle", "right": "2πr"},
        {"left": "Value of Pi (π)", "right": "22/7 or 3.1415"}
      ]
    },
    {
      "id": "eng_synonyms",
      "subject": "English",
      "std": ["6", "7", "8", "9", "10", "11", "12"],
      "title": "Synonyms Challenge",
      "description": "Connect the words with their closest meanings.",
      "pairs": [
        {"left": "Ancient", "right": "Extremely old"},
        {"left": "Gigantic", "right": "Huge or massive"},
        {"left": "Reluctant", "right": "Unwilling"},
        {"left": "Abundant", "right": "Plentiful"},
        {"left": "Brief", "right": "Short and concise"}
      ]
    },
    {
      "id": "eng_antonyms",
      "subject": "English",
      "std": ["6", "7", "8", "9", "10", "11", "12"],
      "title": "Antonyms Challenge",
      "description": "Link words to their direct opposites.",
      "pairs": [
        {"left": "Brave", "right": "Cowardly"},
        {"left": "Optimistic", "right": "Pessimistic"},
        {"left": "Ascend", "right": "Descend"},
        {"left": "Expand", "right": "Contract"},
        {"left": "Generous", "right": "Stingy"}
      ]
    },
    {
      "id": "ss_capitals",
      "subject": "Social Science",
      "std": ["6", "7", "8", "9", "10"],
      "title": "Indian States & Capitals",
      "description": "Match the Indian states with their capitals.",
      "pairs": [
        {"left": "Maharashtra", "right": "Mumbai"},
        {"left": "Gujarat", "right": "Gandhinagar"},
        {"left": "Karnataka", "right": "Bengaluru"},
        {"left": "Tamil Nadu", "right": "Chennai"},
        {"left": "Rajasthan", "right": "Jaipur"}
      ]
    },
    {
      "id": "ss_history",
      "subject": "Social Science",
      "std": ["6", "7", "8", "9", "10"],
      "title": "Indian History Landmarks",
      "description": "Link historical milestones with their accurate years.",
      "pairs": [
        {"left": "Indian Independence", "right": "1947"},
        {"left": "Battle of Plassey", "right": "1757"},
        {"left": "First Battle of Panipat", "right": "1526"},
        {"left": "Quit India Movement", "right": "1942"},
        {"left": "Constitution Adoption", "right": "1950"}
      ]
    },
    {
      "id": "phy_si_units",
      "subject": "Physics",
      "std": ["11", "12"],
      "title": "SI Units & Quantities",
      "description": "Match physical quantities with their corresponding SI Units.",
      "pairs": [
        {"left": "Force", "right": "Newton (N)"},
        {"left": "Energy", "right": "Joule (J)"},
        {"left": "Resistance", "right": "Ohm (Ω)"},
        {"left": "Current", "right": "Ampere (A)"},
        {"left": "Pressure", "right": "Pascal (Pa)"}
      ]
    },
    {
      "id": "phy_constants",
      "subject": "Physics",
      "std": ["11", "12"],
      "title": "Universal Constants",
      "description": "Match physics symbols with their exact values.",
      "pairs": [
        {"left": "Speed of Light (c)", "right": "3 × 10⁸ m/s"},
        {"left": "Planck's Constant (h)", "right": "6.626 × 10⁻³⁴ J·s"},
        {"left": "Gravitational Const (G)", "right": "6.674 × 10⁻¹¹ N·m²/kg²"},
        {"left": "Gravity on Earth (g)", "right": "9.8 m/s²"},
        {"left": "Universal Gas Const (R)", "right": "8.314 J/(mol·K)"}
      ]
    },
    {
      "id": "chem_func_grp",
      "subject": "Chemistry",
      "std": ["11", "12"],
      "title": "Organic Functional Groups",
      "description": "Match the class of organic compounds with their formulas.",
      "pairs": [
        {"left": "Alcohol", "right": "-OH"},
        {"left": "Aldehyde", "right": "-CHO"},
        {"left": "Carboxylic Acid", "right": "-COOH"},
        {"left": "Ketone", "right": "-CO-"},
        {"left": "Ether", "right": "-O-"}
      ]
    },
    {
      "id": "chem_common_names",
      "subject": "Chemistry",
      "std": ["11", "12"],
      "title": "Chemical Common Names",
      "description": "Match IUPAC chemical structures with common household names.",
      "pairs": [
        {"left": "Sodium Bicarbonate", "right": "Baking Soda"},
        {"left": "Calcium Carbonate", "right": "Chalk / Limestone"},
        {"left": "Sodium Carbonate", "right": "Washing Soda"},
        {"left": "Nitrous Oxide", "right": "Laughing Gas"},
        {"left": "Solid Carbon Dioxide", "right": "Dry Ice"}
      ]
    },
    {
      "id": "bio_vitamins",
      "subject": "Biology",
      "std": ["11", "12"],
      "title": "Vitamins & Deficiency Diseases",
      "description": "Connect vitamin types with the illnesses caused by their deficiency.",
      "pairs": [
        {"left": "Vitamin A", "right": "Night Blindness"},
        {"left": "Vitamin B₁", "right": "Beriberi"},
        {"left": "Vitamin C", "right": "Scurvy"},
        {"left": "Vitamin D", "right": "Rickets"},
        {"left": "Vitamin K", "right": "Delayed Blood Clotting"}
      ]
    },
    {
      "id": "bio_hormones",
      "subject": "Biology",
      "std": ["11", "12"],
      "title": "Plant Hormones",
      "description": "Match phytohormones with their main physiological functions.",
      "pairs": [
        {"left": "Auxin", "right": "Apical dominance"},
        {"left": "Gibberellin", "right": "Stem elongation"},
        {"left": "Cytokinin", "right": "Promotes cell division"},
        {"left": "Ethylene", "right": "Fruit ripening"},
        {"left": "Abscisic Acid", "right": "Dormancy & seed arrest"}
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadFilters();
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

      setState(() {
        _subjects = loadedSubjects;
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

  // Get matching exercises filtered by standard and subject
  List<Map<String, dynamic>> get _filteredExercises {
    final currentStd = _normalizedUserStd;
    return _allExercises.where((ex) {
      final stdList = ex['std'] as List<String>;
      final matchesStd = stdList.contains(currentStd);
      final matchesSub = _selectedSubject == null || ex['subject'] == _selectedSubject;
      return matchesStd && matchesSub;
    }).toList();
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
        'title': 'જોડકા જોડો',
        'subject': 'વિષય',
        'allSubjects': 'બધા વિષયો',
        'noExercises': 'કોઈ જોડકા મળ્યા નથી',
        'selectSubject': 'વિષય પસંદ કરો',
        'pairs': 'જોડીઓ',
        'start': 'શરૂ કરો',
        'matchAll': 'કૉલम A માંથી કૉલમ B સાથે સાચી જોડી જોડો.',
      },
      'hi': {
        'title': 'सही मिलान करें',
        'subject': 'विषय',
        'allSubjects': 'सभी विषय',
        'noExercises': 'कोई मिलान अभ्यास नहीं मिला',
        'selectSubject': 'विषय द्वारा फ़िल्टर करें',
        'pairs': 'जोड़े',
        'start': 'शुरू करें',
        'matchAll': 'कॉलम A से कॉलम B के सही जोड़े मिलाएँ।',
      },
      'mr': {
        'title': 'योग्य जोड्या जुळवा',
        'subject': 'विषय',
        'allSubjects': 'सर्व विषय',
        'noExercises': 'कोणत्याही जोड्या आढळल्या नाहीत',
        'selectSubject': 'विषय निवडा',
        'pairs': 'जोड्या',
        'start': 'सुरू करा',
        'matchAll': 'स्तंभ A मधील योग्य जोड्या स्तंभ B शी जुळवा.',
      },
      'ta': {
        'title': 'பொருத்துக',
        'subject': 'பாடம்',
        'allSubjects': 'அனைத்து பாடங்களும்',
        'noExercises': 'பொருந்தும் பயிற்சிகள் எதுவும் இல்லை',
        'selectSubject': 'பாடத்தைத் தேர்ந்தெடுக்கவும்',
        'pairs': 'ஜோடிகள்',
        'start': 'தொடங்கு',
        'matchAll': 'நெடுவரிசை A லிருந்து நெடுவரிசை B இன் சரியான ஜோடிகளை இணைக்கவும்.',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MatchFollowingHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const CustomLoader()
          : Column(
              children: [
                // Dropdown Filter Area
                Container(
                  color: isDark ? const Color(0xFF1A2340) : Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: CustomDropdown<String>(
                    labelText: _getTranslation(context, 'subject'),
                    hintText: _getTranslation(context, 'allSubjects'),
                    value: _selectedSubject,
                    items: _subjects,
                    itemLabelBuilder: (String item) => item,
                    onChanged: (val) {
                      setState(() {
                        _selectedSubject = val;
                      });
                    },
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
                // List of Exercises
                Expanded(
                  child: _filteredExercises.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _filteredExercises.length,
                          itemBuilder: (context, index) {
                            final exercise = _filteredExercises[index];
                            return _buildExerciseCard(exercise, theme, isDark);
                          },
                        ),
                ),
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

  Widget _buildExerciseCard(Map<String, dynamic> exercise, ThemeData theme, bool isDark) {
    final primary = theme.colorScheme.primary;
    final title = exercise['title'] as String;
    final subject = exercise['subject'] as String;
    final description = exercise['description'] as String;
    final pairsCount = (exercise['pairs'] as List).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2340) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$pairsCount ${_getTranslation(context, 'pairs')}",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    subject,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchFollowingGameScreen(
                          exerciseId: exercise['id'] as String,
                          title: title,
                          subject: subject,
                          pairsData: List<Map<String, String>>.from(
                            (exercise['pairs'] as List).map(
                              (p) => {
                                "left": p['left'] as String,
                                "right": p['right'] as String,
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  ),
                  child: Text(
                    _getTranslation(context, 'start'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
