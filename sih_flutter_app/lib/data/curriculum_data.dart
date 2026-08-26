class LessonContent {
  final String titleEn;
  final String titleHi;
  final String titleSat;
  final String competencyId;
  final String learningOutcomeEn;
  final String learningOutcomeHi;

  const LessonContent({
    required this.titleEn,
    required this.titleHi,
    required this.titleSat,
    this.competencyId = '',
    this.learningOutcomeEn = '',
    this.learningOutcomeHi = '',
  });
}

class WorksheetQuestion {
  final String instructionEn;
  final String instructionHi;
  final String instructionSat;
  final String prompt;
  final String answer;

  const WorksheetQuestion({
    required this.instructionEn,
    required this.instructionHi,
    required this.instructionSat,
    required this.prompt,
    required this.answer,
  });
}

class CurriculumData {
  static const Map<int, Map<String, List<LessonContent>>> curriculum = {
    1: {
      'Mathematics': [
        LessonContent(
          titleEn: 'Counting 1–10',
          titleHi: 'वस्तुओं की गिनती 1–10',
          titleSat: 'ᱮᱞ ᱑–᱑᱐',
          competencyId: 'FLN-M1-01',
          learningOutcomeEn:
              'Count concrete physical and visual objects from 1 to 10 with one-to-one correspondence.',
          learningOutcomeHi:
              '1 से 10 तक की ठोस और दृश्य वस्तुओं को एक-एक करके सही क्रम में गिनना।',
        ),
        LessonContent(
          titleEn: 'Number Recognition 1–10',
          titleHi: 'संख्या पहचान 1–10',
          titleSat: 'ᱮᱞ ᱩᱨᱩᱢ ᱑–᱑᱐',
          competencyId: 'FLN-M1-02',
          learningOutcomeEn:
              'Recognize, identify, and name numerals from 1 to 10 in standard and mother-tongue script.',
          learningOutcomeHi:
              '1 से 10 तक के संख्या अंकों को पहचानना और मातृभाषा में उनका नाम बोलना।',
        ),
        LessonContent(
          titleEn: 'Number Matching 1–10',
          titleHi: 'संख्या और मात्रा मिलान',
          titleSat: 'ᱮᱞ ᱟᱨ ᱡᱤᱱᱤᱥ ᱢᱮᱞᱟᱣ',
          competencyId: 'FLN-M1-03',
          learningOutcomeEn:
              'Match numerals 1–10 with their corresponding collections and quantities of objects.',
          learningOutcomeHi:
              '1 से 10 तक के अंकों को उनकी संगत वस्तुओं के समूह और मात्रा से मिलाना।',
        ),
      ],
      'Language': [
        LessonContent(
          titleEn: 'Letters and Sounds',
          titleHi: 'अक्षर और ध्वनियाँ',
          titleSat: 'ᱪᱤᱠᱤ ᱟᱨ ᱥᱟᱰ',
        ),
        LessonContent(
          titleEn: 'Simple Words',
          titleHi: 'सरल शब्द',
          titleSat: 'ᱥᱟᱫᱷᱟᱨᱚᱱ ᱥᱟᱵᱫ',
        ),
        LessonContent(
          titleEn: 'Listening and Speaking',
          titleHi: 'सुनना और बोलना',
          titleSat: 'ᱟᱸᱡᱚᱢ ᱟᱨ ᱨᱚᱲ',
        ),
      ],
      'EVS': [
        LessonContent(
          titleEn: 'My Family',
          titleHi: 'मेरा परिवार',
          titleSat: 'ᱤᱧ ᱨᱮᱱᱟᱜ ᱯᱟᱹᱨᱤᱵᱟᱨ',
        ),
        LessonContent(
          titleEn: 'My School',
          titleHi: 'मेरा विद्यालय',
          titleSat: 'ᱤᱧ ᱨᱮᱱᱟᱜ ᱥᱠᱩᱞ',
        ),
        LessonContent(
          titleEn: 'Plants Around Us',
          titleHi: 'हमारे आसपास के पौधे',
          titleSat: 'ᱟᱢᱟᱜ ᱫᱷᱟᱨᱮ ᱥᱟᱜ',
        ),
      ],
    },
    2: {
      'Mathematics': [
        LessonContent(
          titleEn: 'Counting and Ordering 1–10',
          titleHi: 'संख्या क्रमबद्धता 1–10',
          titleSat: 'ᱮᱞ ᱠᱚ ᱞᱟᱭᱤᱱ ᱫᱚᱦᱚ',
          competencyId: 'FLN-M2-01',
          learningOutcomeEn:
              'Count, arrange, and order numbers 1–10 in ascending and descending sequence, identifying missing numbers.',
          learningOutcomeHi:
              '1 से 10 तक की संख्याओं को आगे और पीछे के क्रम में लगाना तथा छूटी हुई संख्याएँ पहचानना।',
        ),
        LessonContent(
          titleEn: 'Addition Within 10',
          titleHi: '10 तक का जोड़',
          titleSat: '᱑᱐ ᱦᱟᱹᱵᱤᱡ ᱡᱚᱲ',
          competencyId: 'FLN-M2-02',
          learningOutcomeEn:
              'Combine two groups of objects and calculate sums up to 10 using concrete materials and symbols.',
          learningOutcomeHi:
              'ठोस वस्तुओं और चित्रों की सहायता से दो समूहों को मिलाकर 10 तक का जोड़ करना।',
        ),
        LessonContent(
          titleEn: 'Number Comparison 1–10',
          titleHi: 'संख्या तुलना: बड़ा, छोटा',
          titleSat: 'ᱮᱞ ᱠᱚ ᱛᱩᱞᱟᱹᱡᱚᱠᱷᱟ',
          competencyId: 'FLN-M2-03',
          learningOutcomeEn:
              'Compare two numbers or quantities up to 10 using concepts of greater than, less than, and equal to.',
          learningOutcomeHi:
              '10 तक की दो संख्याओं या मात्राओं की तुलना करके बड़ा, छोटा या बराबर बताना।',
        ),
      ],
      'Language': [
        LessonContent(
          titleEn: 'Reading Simple Sentences',
          titleHi: 'सरल वाक्य पढ़ना',
          titleSat: 'ᱥᱟᱫᱷᱟᱨᱚᱱ ᱟᱹᱭᱟᱹᱛ ᱯᱟᱲᱦᱟᱣ',
        ),
        LessonContent(
          titleEn: 'New Words',
          titleHi: 'नए शब्द',
          titleSat: 'ᱱᱟᱣᱟ ᱥᱟᱵᱫ',
        ),
        LessonContent(
          titleEn: 'Story Listening',
          titleHi: 'कहानी सुनना',
          titleSat: 'ᱠᱟᱹᱦᱱᱤ ᱟᱸᱡᱚᱢ',
        ),
      ],
      'EVS': [
        LessonContent(
          titleEn: 'Animals Around Us',
          titleHi: 'हमारे आसपास के जानवर',
          titleSat: 'ᱟᱢᱟᱜ ᱫᱷᱟᱨᱮ ᱡᱤᱣ',
        ),
        LessonContent(titleEn: 'Water', titleHi: 'पानी', titleSat: 'ᱫᱟᱜ'),
        LessonContent(
          titleEn: 'Healthy Food',
          titleHi: 'स्वस्थ भोजन',
          titleSat: 'ᱥᱮᱨᱮᱡ ᱡᱚᱢ',
        ),
      ],
    },
    3: {
      'Mathematics': [
        LessonContent(
          titleEn: 'Addition and Subtraction Within 10',
          titleHi: 'जोड़ और घटाव (10 के भीतर)',
          titleSat: 'ᱡᱚᱲ ᱟᱨ ᱠᱟᱹᱴ',
          competencyId: 'FLN-M3-01',
          learningOutcomeEn:
              'Fluently perform both addition and subtraction operations within 10 to solve combined arithmetic tasks.',
          learningOutcomeHi:
              '10 के भीतर जोड़ और घटाव दोनों संक्रियाओं को धाराप्रवाह रूप से हल करना।',
        ),
        LessonContent(
          titleEn: 'Number Patterns',
          titleHi: 'संख्या पैटर्न',
          titleSat: 'ᱮᱞ ᱯᱮᱴᱟᱨᱱ',
          competencyId: 'FLN-M3-02',
          learningOutcomeEn:
              'Identify, extend, and construct repeating and growing number patterns (e.g. skip counting by 2s).',
          learningOutcomeHi:
              'संख्याओं के दोहराव और वृद्धि पैटर्न (जैसे 2-2 की छलांग) को पहचानना और आगे बढ़ाना।',
        ),
        LessonContent(
          titleEn: 'Simple Word Problems Within 10',
          titleHi: 'सरल शब्द समस्याएँ (10 के भीतर)',
          titleSat: 'ᱥᱟᱫᱷᱟᱨᱚᱱ ᱠᱟᱛᱷᱟ ᱦᱤᱥᱟᱹᱵᱽ',
          competencyId: 'FLN-M3-03',
          learningOutcomeEn:
              'Formulate mathematical operations and solve everyday contextual word problems involving numbers up to 10.',
          learningOutcomeHi:
              'दैनिक जीवन के संदर्भ वाले सरल व्यावहारिक एवं शाब्दिक प्रश्नों को समझकर 10 के भीतर हल करना।',
        ),
      ],
      'Language': [
        LessonContent(
          titleEn: 'Reading a Story',
          titleHi: 'कहानी पढ़ना',
          titleSat: 'ᱠᱟᱹᱦᱱᱤ ᱯᱟᱲᱦᱟᱣ',
        ),
        LessonContent(
          titleEn: 'Sentence Building',
          titleHi: 'वाक्य बनाना',
          titleSat: 'ᱟᱹᱭᱟᱹᱛ ᱵᱟᱱᱟᱣ',
        ),
        LessonContent(
          titleEn: 'Word Meaning',
          titleHi: 'शब्द का अर्थ',
          titleSat: 'ᱥᱟᱵᱫ ᱨᱮᱱᱟᱜ ᱢᱮᱱᱟᱜ',
        ),
      ],
      'EVS': [
        LessonContent(
          titleEn: 'Our Community',
          titleHi: 'हमारा समुदाय',
          titleSat: 'ᱟᱢᱟᱜ ᱥᱚᱢᱟᱡ',
        ),
        LessonContent(
          titleEn: 'Plants and Animals',
          titleHi: 'पौधे और जानवर',
          titleSat: 'ᱥᱟᱜ ᱟᱨ ᱡᱤᱣ',
        ),
        LessonContent(
          titleEn: 'Clean Water and Air',
          titleHi: 'स्वच्छ पानी और हवा',
          titleSat: 'ᱥᱟᱯᱷᱟ ᱫᱟᱜ ᱟᱨ ᱦᱟᱣᱟ',
        ),
      ],
    },
  };

  static const Map<int, Map<String, List<WorksheetQuestion>>> worksheets = {
    1: {
      'Mathematics': [
        WorksheetQuestion(
          instructionEn: 'Count the objects',
          instructionHi: 'वस्तुओं को गिनिए।',
          instructionSat: 'ᱡᱤᱱᱤᱥ ᱠᱚ ᱮᱞ ᱢᱮ᱾',
          prompt: '● ● ●',
          answer: '3',
        ),
        WorksheetQuestion(
          instructionEn: 'Choose the bigger number',
          instructionHi: 'बड़ी संख्या चुनिए।',
          instructionSat: 'ᱢᱟᱨᱟᱝ ᱮᱞ ᱵᱟᱪᱷᱟᱣ ᱢᱮ᱾',
          prompt: '2   5',
          answer: '5',
        ),
        WorksheetQuestion(
          instructionEn: 'Complete the number',
          instructionHi: 'संख्या पूरी कीजिए।',
          instructionSat: 'ᱮᱞ ᱯᱩᱨᱟᱹ ᱢᱮ᱾',
          prompt: '1, 2, __, 4',
          answer: '3',
        ),
      ],
      'Language': [
        WorksheetQuestion(
          instructionEn: 'Match the letter',
          instructionHi: 'अक्षर का मिलान कीजिए।',
          instructionSat: 'ᱪᱤᱠᱤ ᱢᱮᱞᱟᱣ ᱢᱮ᱾',
          prompt: 'क — ___',
          answer: 'क',
        ),
        WorksheetQuestion(
          instructionEn: 'Read the word',
          instructionHi: 'शब्द पढ़िए।',
          instructionSat: 'ᱥᱟᱵᱫ ᱯᱟᱲᱦᱟᱣ ᱢᱮ᱾',
          prompt: 'घर',
          answer: 'घर',
        ),
        WorksheetQuestion(
          instructionEn: 'Choose the word',
          instructionHi: 'सही शब्द चुनिए।',
          instructionSat: 'ᱥᱟᱹᱨᱤ ᱥᱟᱵᱫ ᱵᱟᱪᱷᱟᱣ ᱢᱮ᱾',
          prompt: 'घर / पेड़',
          answer: 'घर',
        ),
      ],
      'EVS': [
        WorksheetQuestion(
          instructionEn: 'Name a family member',
          instructionHi: 'परिवार के सदस्य का नाम लिखिए।',
          instructionSat: 'ᱯᱟᱹᱨᱤᱵᱟᱨ ᱨᱮᱱ ᱢᱤᱫ ᱦᱚᱲ ᱨᱮᱜᱮ ᱚᱞ ᱢᱮ᱾',
          prompt: '____________',
          answer: '',
        ),
        WorksheetQuestion(
          instructionEn: 'Choose the plant',
          instructionHi: 'पौधे को चुनिए।',
          instructionSat: 'ᱥᱟᱜ ᱵᱟᱪᱷᱟᱣ ᱢᱮ᱾',
          prompt: '🌳   🐄   ☀️',
          answer: '🌳',
        ),
        WorksheetQuestion(
          instructionEn: 'My school',
          instructionHi: 'मेरे विद्यालय का नाम लिखिए।',
          instructionSat: 'ᱤᱧ ᱨᱮᱱᱟᱜ ᱥᱠᱩᱞ ᱨᱮᱱᱟᱜ ᱧᱩᱛ ᱚᱞ ᱢᱮ᱾',
          prompt: '____________',
          answer: '',
        ),
      ],
    },
    2: {
      'Mathematics': [
        WorksheetQuestion(
          instructionEn: 'Count the objects',
          instructionHi: 'वस्तुओं को गिनिए।',
          instructionSat: 'ᱡᱤᱱᱤᱥ ᱠᱚ ᱮᱞ ᱢᱮ᱾',
          prompt: '● ● ● ●',
          answer: '4',
        ),
        WorksheetQuestion(
          instructionEn: 'Add the numbers',
          instructionHi: 'संख्याओं को जोड़िए।',
          instructionSat: 'ᱮᱞ ᱠᱚ ᱡᱚᱲ ᱢᱮ᱾',
          prompt: '3 + 2 = ___',
          answer: '5',
        ),
        WorksheetQuestion(
          instructionEn: 'Subtract',
          instructionHi: 'घटाव कीजिए।',
          instructionSat: 'ᱠᱟᱹᱴ ᱢᱮ᱾',
          prompt: '7 − 3 = ___',
          answer: '4',
        ),
      ],
      'Language': [
        WorksheetQuestion(
          instructionEn: 'Read the sentence',
          instructionHi: 'वाक्य पढ़िए।',
          instructionSat: 'ᱟᱹᱭᱟᱹᱛ ᱯᱟᱲᱦᱟᱣ ᱢᱮ᱾',
          prompt: 'राम घर जाता है।',
          answer: '',
        ),
        WorksheetQuestion(
          instructionEn: 'Choose the new word',
          instructionHi: 'सही शब्द चुनिए।',
          instructionSat: 'ᱥᱟᱹᱨᱤ ᱥᱟᱵᱫ ᱵᱟᱪᱷᱟᱣ ᱢᱮ᱾',
          prompt: 'पानी / पत्थर',
          answer: 'पानी',
        ),
        WorksheetQuestion(
          instructionEn: 'Complete the sentence',
          instructionHi: 'वाक्य पूरा कीजिए।',
          instructionSat: 'ᱟᱹᱭᱟᱹᱛ ᱯᱩᱨᱟᱹ ᱢᱮ᱾',
          prompt: 'मैं स्कूल ___।',
          answer: 'जाता हूँ',
        ),
      ],
      'EVS': [
        WorksheetQuestion(
          instructionEn: 'Name an animal',
          instructionHi: 'एक जानवर का नाम लिखिए।',
          instructionSat: 'ᱢᱤᱫ ᱡᱤᱣ ᱨᱮᱱᱟᱜ ᱧᱩᱛ ᱚᱞ ᱢᱮ᱾',
          prompt: '____________',
          answer: '',
        ),
        WorksheetQuestion(
          instructionEn: 'Choose healthy food',
          instructionHi: 'स्वस्थ भोजन चुनिए।',
          instructionSat: 'ᱥᱮᱨᱮᱡ ᱡᱚᱢ ᱵᱟᱪᱷᱟᱣ ᱢᱮ᱾',
          prompt: 'फल / बहुत मिठाई',
          answer: 'फल',
        ),
        WorksheetQuestion(
          instructionEn: 'Water is used for',
          instructionHi: 'पानी का उपयोग किसके लिए होता है?',
          instructionSat: 'ᱫᱟᱜ ᱚᱠᱟ ᱞᱟᱹᱜᱤᱫ ᱵᱮᱣᱦᱟᱨ ᱚᱜᱼᱟ?',
          prompt: 'पीना / पत्थर',
          answer: 'पीना',
        ),
      ],
    },
    3: {
      'Mathematics': [
        WorksheetQuestion(
          instructionEn: 'Add',
          instructionHi: 'जोड़ कीजिए।',
          instructionSat: 'ᱡᱚᱲ ᱢᱮ᱾',
          prompt: '24 + 15 = ___',
          answer: '39',
        ),
        WorksheetQuestion(
          instructionEn: 'Multiply',
          instructionHi: 'गुणा कीजिए।',
          instructionSat: 'ᱜᱩᱱ ᱢᱮ᱾',
          prompt: '4 × 3 = ___',
          answer: '12',
        ),
        WorksheetQuestion(
          instructionEn: 'Divide',
          instructionHi: 'भाग कीजिए।',
          instructionSat: 'ᱦᱟᱹᱴᱤ ᱢᱮ᱾',
          prompt: '12 ÷ 3 = ___',
          answer: '4',
        ),
      ],
      'Language': [
        WorksheetQuestion(
          instructionEn: 'Read the story title',
          instructionHi: 'कहानी का शीर्षक पढ़िए।',
          instructionSat: 'ᱠᱟᱹᱦᱱᱤ ᱨᱮᱱᱟᱜ ᱧᱩᱛ ᱯᱟᱲᱦᱟᱣ ᱢᱮ᱾',
          prompt: 'ईमानदार बच्चा',
          answer: '',
        ),
        WorksheetQuestion(
          instructionEn: 'Build a sentence',
          instructionHi: 'वाक्य बनाइए।',
          instructionSat: 'ᱟᱹᱭᱟᱹᱛ ᱵᱟᱱᱟᱣ ᱢᱮ᱾',
          prompt: 'बच्चे / खेलते / हैं',
          answer: 'बच्चे खेलते हैं।',
        ),
        WorksheetQuestion(
          instructionEn: 'Word meaning',
          instructionHi: 'शब्द का अर्थ लिखिए।',
          instructionSat: 'ᱥᱟᱵᱫ ᱨᱮᱱᱟᱜ ᱢᱮᱱᱟᱜ ᱚᱞ ᱢᱮ᱾',
          prompt: 'जल = ______',
          answer: 'पानी',
        ),
      ],
      'EVS': [
        WorksheetQuestion(
          instructionEn: 'Community helper',
          instructionHi: 'एक समुदाय सहायक का नाम लिखिए।',
          instructionSat: 'ᱥᱚᱢᱟᱡ ᱨᱮᱱ ᱢᱤᱫ ᱥᱟᱦᱟᱭᱤᱡ ᱨᱮᱱᱟᱜ ᱧᱩᱛ ᱚᱞ ᱢᱮ᱾',
          prompt: '____________',
          answer: '',
        ),
        WorksheetQuestion(
          instructionEn: 'Choose a plant',
          instructionHi: 'पौधे को चुनिए।',
          instructionSat: 'ᱥᱟᱜ ᱵᱟᱪᱷᱟᱣ ᱢᱮ᱾',
          prompt: 'पेड़ / कार / गेंद',
          answer: 'पेड़',
        ),
        WorksheetQuestion(
          instructionEn: 'Clean water',
          instructionHi: 'स्वच्छ पानी क्यों जरूरी है?',
          instructionSat: 'ᱥᱟᱯᱷᱟ ᱫᱟᱜ ᱪᱮᱫ ᱞᱟᱹᱜᱤᱫ ᱡᱟᱨᱩᱨᱤᱭᱟ?',
          prompt: 'स्वास्थ्य के लिए',
          answer: 'स्वास्थ्य के लिए',
        ),
      ],
    },
  };
}
