class LessonContent {
  final String titleEn;
  final String titleHi;
  final String titleSat;

  const LessonContent({
    required this.titleEn,
    required this.titleHi,
    required this.titleSat,
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
          titleEn: 'Numbers 1–10',
          titleHi: 'संख्याएँ 1–10',
          titleSat: 'ᱮᱞ ᱑–᱑᱐',
        ),
        LessonContent(
          titleEn: 'Counting Objects',
          titleHi: 'वस्तुओं की गिनती',
          titleSat: 'ᱡᱤᱱᱤᱥ ᱮᱞ',
        ),
        LessonContent(titleEn: 'Shapes', titleHi: 'आकार', titleSat: 'ᱟᱠᱟᱨ'),
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
          titleEn: 'Numbers 1–10',
          titleHi: 'संख्याएँ 1–10',
          titleSat: 'ᱮᱞ ᱑–᱑᱐',
        ),
        LessonContent(titleEn: 'Addition', titleHi: 'जोड़', titleSat: 'ᱡᱚᱲ'),
        LessonContent(
          titleEn: 'Subtraction',
          titleHi: 'घटाव',
          titleSat: 'ᱠᱟᱹᱴ',
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
          titleEn: 'Numbers up to 100',
          titleHi: '100 तक की संख्याएँ',
          titleSat: '᱑᱐᱐ ᱦᱟᱵᱤᱡ ᱮᱞ',
        ),
        LessonContent(
          titleEn: 'Multiplication',
          titleHi: 'गुणा',
          titleSat: 'ᱜᱩᱱ',
        ),
        LessonContent(titleEn: 'Division', titleHi: 'भाग', titleSat: 'ᱦᱟᱹᱴᱤ'),
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
