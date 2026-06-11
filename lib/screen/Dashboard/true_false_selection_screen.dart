import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dm_bhatt_tutions/network/api_service.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_loader.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_app_bar.dart';
import 'package:dm_bhatt_tutions/custom_widgets/custom_dropdown.dart';
import 'package:dm_bhatt_tutions/utils/academic_constants.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/true_false_game_screen.dart';
import 'package:dm_bhatt_tutions/screen/Dashboard/true_false_history_screen.dart';

class TrueFalseSelectionScreen extends StatefulWidget {
  const TrueFalseSelectionScreen({super.key});

  @override
  State<TrueFalseSelectionScreen> createState() => _TrueFalseSelectionScreenState();
}

class _TrueFalseSelectionScreenState extends State<TrueFalseSelectionScreen> {
  bool _isLoading = true;
  String? _selectedSubject;
  List<String> _subjects = [];

  String? _userStandard;
  String? _userBoard;
  String? _userStream;
  String? _userMedium;

  // Local True/False data store
  final List<Map<String, dynamic>> _allExercises = const [
    {
      "id": "tf_sci_cell",
      "subject": "Science",
      "std": ["6", "7", "8", "9", "10"],
      "title": "Cell Biology & Genetics",
      "description": "Test your knowledge on cells, plant vs animal cells, and DNA structures.",
      "questions": [
        {
          "statement": "All living organisms are made up of one or more cells.",
          "answer": true,
          "explanation": "Cell is the fundamental unit of life. All living organisms are cellular."
        },
        {
          "statement": "Plant cells contain cell walls, whereas animal cells do not.",
          "answer": true,
          "explanation": "Cell walls provide structural support and are unique to plant cells, fungi, and some bacteria."
        },
        {
          "statement": "Mitochondria is known as the powerhouse of the cell.",
          "answer": true,
          "explanation": "Mitochondria generate most of the cell's supply of ATP, used as a source of chemical energy."
        },
        {
          "statement": "DNA is located in the cytoplasm of a eukaryotic cell.",
          "answer": false,
          "explanation": "In eukaryotic cells, DNA is enclosed within the nucleus, not free in the cytoplasm."
        },
        {
          "statement": "Ribosomes are responsible for lipid synthesis.",
          "answer": false,
          "explanation": "Ribosomes are the sites of protein synthesis. Endoplasmic reticulum (SER) synthesizes lipids."
        }
      ]
    },
    {
      "id": "tf_sci_chem",
      "subject": "Science",
      "std": ["8", "9", "10"],
      "title": "Chemical Reactions & Gases",
      "description": "Understand combustion, chemical vs physical changes, and common gases.",
      "questions": [
        {
          "statement": "Oxygen gas is essential for combustion (burning) to take place.",
          "answer": true,
          "explanation": "Oxygen acts as an oxidizing agent and is necessary to sustain fire."
        },
        {
          "statement": "Carbon dioxide gas turns lime water milky.",
          "answer": true,
          "explanation": "CO₂ reacts with lime water (calcium hydroxide) to form insoluble calcium carbonate."
        },
        {
          "statement": "Rusting of iron is a physical change.",
          "answer": false,
          "explanation": "Rusting is a chemical change because a new substance (iron oxide) is formed."
        },
        {
          "statement": "Water is a compound, not an element.",
          "answer": true,
          "explanation": "Water is composed of hydrogen and oxygen atoms chemically bonded in a 2:1 ratio."
        },
        {
          "statement": "Helium gas is highly inflammable.",
          "answer": false,
          "explanation": "Helium is a noble gas and is chemically inert and non-flammable."
        }
      ]
    },
    {
      "id": "tf_math_shapes",
      "subject": "Maths",
      "std": ["6", "7", "8", "9", "10"],
      "title": "Geometry & Shapes",
      "description": "Verify facts about triangles, rectangles, squares, and circles.",
      "questions": [
        {
          "statement": "The sum of all three interior angles of a triangle is always 180 degrees.",
          "answer": true,
          "explanation": "According to the angle sum property, the sum of angles of any triangle is 180°."
        },
        {
          "statement": "A rectangle is a type of square.",
          "answer": false,
          "explanation": "A square is a special type of rectangle where all sides are equal. The reverse is not true."
        },
        {
          "statement": "An equilateral triangle has all three sides of equal length.",
          "answer": true,
          "explanation": "By definition, an equilateral triangle has three equal sides and three 60° angles."
        },
        {
          "statement": "The perimeter of a circle is called its diameter.",
          "answer": false,
          "explanation": "The perimeter of a circle is its circumference. Diameter is the line passing through the center."
        },
        {
          "statement": "The sum of interior angles in a quadrilateral is 360 degrees.",
          "answer": true,
          "explanation": "A quadrilateral can be split into two triangles, each having a sum of 180°, totaling 360°."
        }
      ]
    },
    {
      "id": "tf_math_nums",
      "subject": "Maths",
      "std": ["6", "7", "8", "9", "10"],
      "title": "Number Systems & Algebra",
      "description": "Test basic principles of positive numbers, primes, and rational numbers.",
      "questions": [
        {
          "statement": "Zero is a positive number.",
          "answer": false,
          "explanation": "Zero is neutral; it is neither positive nor negative."
        },
        {
          "statement": "Every prime number is an odd number.",
          "answer": false,
          "explanation": "The number 2 is a prime number and is even. It is the only even prime."
        },
        {
          "statement": "The number 1 is a prime number.",
          "answer": false,
          "explanation": "1 is neither prime nor composite. Prime numbers must be greater than 1."
        },
        {
          "statement": "A rational number can always be expressed in the form of p/q, where q is not zero.",
          "answer": true,
          "explanation": "This is the mathematical definition of a rational number."
        },
        {
          "statement": "The square of a negative number is always negative.",
          "answer": false,
          "explanation": "Multiplying two negative numbers yields a positive product. e.g. (-3) * (-3) = 9."
        }
      ]
    },
    {
      "id": "tf_eng_grammar",
      "subject": "English",
      "std": ["6", "7", "8", "9", "10", "11", "12"],
      "title": "Grammar & Vocabulary Rules",
      "description": "Revise the roles of adjectives, prepositions, articles, and verbs.",
      "questions": [
        {
          "statement": "An adjective is a word that describes or modifies a noun.",
          "answer": true,
          "explanation": "Adjectives give extra information about nouns, like 'blue' sky or 'happy' child."
        },
        {
          "statement": "The word 'and' is a preposition.",
          "answer": false,
          "explanation": "'And' is a coordinating conjunction, used to join words or clauses."
        },
        {
          "statement": "We use the article 'an' before words starting with a silent 'h', such as 'hour'.",
          "answer": true,
          "explanation": "The choice between 'a' and 'an' depends on the starting sound. 'Hour' starts with a vowel sound."
        },
        {
          "statement": "A pronoun is used in place of a noun to avoid repetition.",
          "answer": true,
          "explanation": "Words like 'he', 'she', 'it', 'they' replace nouns to keep sentences clean."
        },
        {
          "statement": "The past participle of 'go' is 'went'.",
          "answer": false,
          "explanation": "'Went' is the simple past tense. The past participle of 'go' is 'gone'."
        }
      ]
    },
    {
      "id": "tf_ss_history",
      "subject": "Social Science",
      "std": ["6", "7", "8", "9", "10"],
      "title": "Indian History & Geography",
      "description": "Verify historical landmarks, states, and geographical facts of India.",
      "questions": [
        {
          "statement": "India gained independence from British rule in the year 1947.",
          "answer": true,
          "explanation": "India became an independent nation on August 15, 1947."
        },
        {
          "statement": "The Ganges is the longest river flowing entirely within India.",
          "answer": true,
          "explanation": "The Ganges is the longest river in India, measuring 2,525 km."
        },
        {
          "statement": "Mount Everest, the highest peak in the world, is located in India.",
          "answer": false,
          "explanation": "Mount Everest is located in the Himalayas on the border between Nepal and Tibet (China)."
        },
        {
          "statement": "Rajasthan is the largest state in India by land area.",
          "answer": true,
          "explanation": "Rajasthan covers 342,239 sq km, making it India's largest state by area."
        },
        {
          "statement": "The Indian Constitution was fully adopted and came into force in the year 1950.",
          "answer": true,
          "explanation": "It came into effect on January 26, 1950, marked as Republic Day."
        }
      ]
    },
    {
      "id": "tf_phy_mechanics",
      "subject": "Physics",
      "std": ["11", "12"],
      "title": "Mechanics & Waves",
      "description": "Advanced Physics testing sound waves, light, gravity, and frictional forces.",
      "questions": [
        {
          "statement": "Sound waves can travel through a vacuum.",
          "answer": false,
          "explanation": "Sound waves are mechanical waves and require a medium (solid, liquid, or gas) to propagate."
        },
        {
          "statement": "Light waves are electromagnetic waves and do not require a medium to travel.",
          "answer": true,
          "explanation": "EM waves travel through empty space. That is how sunlight reaches the Earth."
        },
        {
          "statement": "Acceleration due to gravity (g) is constant everywhere on the surface of Earth.",
          "answer": false,
          "explanation": "g is slightly higher at the poles and lower at the equator due to Earth's rotation and shape."
        },
        {
          "statement": "The speed of light in a vacuum is approximately 3 × 10⁸ meters per second.",
          "answer": true,
          "explanation": "This is a universal physical constant denoted by 'c'."
        },
        {
          "statement": "Frictional force always acts in the direction of motion of an object.",
          "answer": false,
          "explanation": "Frictional force opposes the relative motion between two surfaces in contact."
        }
      ]
    },
    {
      "id": "tf_chem_bonding",
      "subject": "Chemistry",
      "std": ["11", "12"],
      "title": "Bonding & Periodic Properties",
      "description": "Revise chemical bonds, alkaline metals, pH values, and atomic structures.",
      "questions": [
        {
          "statement": "Covalent bonds are formed by the sharing of electrons between atoms.",
          "answer": true,
          "explanation": "Unlike ionic bonds (transfer of electrons), covalent bonds involve mutual sharing of electron pairs."
        },
        {
          "statement": "Sodium is a highly reactive metal stored in water.",
          "answer": false,
          "explanation": "Sodium reacts violently with water. It is stored in kerosene or mineral oil to prevent reaction."
        },
        {
          "statement": "The pH of an acidic solution is always less than 7.",
          "answer": true,
          "explanation": "Solutions with pH < 7 are acidic, pH = 7 is neutral, and pH > 7 are basic."
        },
        {
          "statement": "Helium has the highest ionization energy in the periodic table.",
          "answer": true,
          "explanation": "Helium has a stable closed shell and is closest to the nucleus, making it extremely hard to remove an electron."
        },
        {
          "statement": "An atom must contain equal numbers of protons and electrons to be electrically neutral.",
          "answer": true,
          "explanation": "Protons have +1 charge and electrons have -1 charge. Equal numbers cancel out to neutral."
        }
      ]
    },
    {
      "id": "tf_bio_physiology",
      "subject": "Biology",
      "std": ["11", "12"],
      "title": "Plant & Human Physiology",
      "description": "Analyze chloroplast functions, red blood cells, mitosis, and tissue transport.",
      "questions": [
        {
          "statement": "Photosynthesis occurs primarily in the mitochondria of plant cells.",
          "answer": false,
          "explanation": "Photosynthesis occurs in chloroplasts, which contain chlorophyll. Mitochondria are for cellular respiration."
        },
        {
          "statement": "Red blood cells are responsible for carrying oxygen throughout the body.",
          "answer": true,
          "explanation": "RBCs contain hemoglobin, an iron-rich protein that binds to oxygen molecules."
        },
        {
          "statement": "Mitosis produces four genetically identical daughter cells.",
          "answer": false,
          "explanation": "Mitosis produces two identical diploid cells. Meiosis produces four non-identical haploid gametes."
        },
        {
          "statement": "Insulin is a hormone produced by the pancreas to regulate blood glucose levels.",
          "answer": true,
          "explanation": "Insulin promotes glucose absorption from blood into liver and muscle cells."
        },
        {
          "statement": "Xylem tissues transport water and minerals from roots to leaves.",
          "answer": true,
          "explanation": "Xylem is responsible for water conduction, while Phloem transports prepared food (sugars)."
        }
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

      // Fetch profile for live state
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

      // Standard normalization (e.g. "9th" -> "9")
      String normStd = "10";
      if (_userStandard != null) {
        final match = RegExp(r'(\d+)').firstMatch(_userStandard!);
        if (match != null) {
          normStd = match.group(1)!;
        }
      }

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
      debugPrint("Error loading profile/subjects: $e");
      setState(() {
        _subjects = ["Science", "Maths", "English", "Physics", "Chemistry", "Biology"];
        _isLoading = false;
      });
    }
  }

  String get _normalizedUserStd {
    if (_userStandard == null) return "10";
    final match = RegExp(r'(\d+)').firstMatch(_userStandard!);
    return match != null ? match.group(1)! : _userStandard!;
  }

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
        'title': 'True / False',
        'subject': 'Subject',
        'allSubjects': 'All Subjects',
        'noExercises': 'No matching exercises found',
        'questions': 'Questions',
        'start': 'START',
        'bannerText': 'Read each statement and determine if it is True or False.',
      },
      'gu': {
        'title': 'ખરું / ખોટું',
        'subject': 'વિષય',
        'allSubjects': 'બધા વિષયો',
        'noExercises': 'કોઈ પ્રશ્નો મળ્યા નથી',
        'questions': 'પ્રશ્નો',
        'start': 'શરૂ કરો',
        'bannerText': 'દરેક વિધાન વાંચો અને નક્કી કરો કે તે સાચું છે કે ખોટું.',
      },
      'hi': {
        'title': 'सही / गलत',
        'subject': 'विषय',
        'allSubjects': 'सभी विषय',
        'noExercises': 'कोई अभ्यास नहीं मिला',
        'questions': 'प्रश्न',
        'start': 'शुरू करें',
        'bannerText': 'प्रत्येक कथन को पढ़ें और तय करें कि वह सही है या गलत।',
      },
      'mr': {
        'title': 'चूक / बरोबर',
        'subject': 'विषय',
        'allSubjects': 'सर्व विषय',
        'noExercises': 'कोणत्याही प्रश्नपत्रिका आढळल्या नाहीत',
        'questions': 'प्रश्न',
        'start': 'सुरू करा',
        'bannerText': 'प्रत्येक विधान वाचा आणि ते चूक की बरोबर ते ठरवा.',
      },
      'ta': {
        'title': 'சரி / தவறு',
        'subject': 'பாடம்',
        'allSubjects': 'அனைத்து பாடங்களும்',
        'noExercises': 'பொருந்தும் பயிற்சிகள் எதுவும் இல்லை',
        'questions': 'கேள்விகள்',
        'start': 'தொடங்கு',
        'bannerText': 'ஒவ்வொரு கூற்றையும் படித்து அது சரியா அல்லது தவறா என்பதைத் தீர்மானிக்கவும்.',
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
                MaterialPageRoute(builder: (context) => const TrueFalseHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const CustomLoader()
          : Column(
              children: [
                // Subject Filter Dropdown
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
                // Explanation Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: primary.withOpacity(0.05),
                  child: Text(
                    _getTranslation(context, 'bannerText'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Exercises list
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
            Icons.check_circle_outline_rounded,
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
    final questionsCount = (exercise['questions'] as List).length;

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
                    "$questionsCount ${_getTranslation(context, 'questions')}",
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
                        builder: (context) => TrueFalseGameScreen(
                          exerciseId: exercise['id'] as String,
                          title: title,
                          subject: subject,
                          questionsData: List<Map<String, dynamic>>.from(
                            (exercise['questions'] as List).map(
                              (q) => {
                                "statement": q['statement'] as String,
                                "answer": q['answer'] as bool,
                                "explanation": q['explanation'] as String,
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
