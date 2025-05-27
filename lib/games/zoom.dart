import 'package:flutter/material.dart';
import 'dart:async';
import '../games_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Single enum for difficulty levels
enum QuizDifficulty { beginner, intermediate, advanced, adaptive }

class Question {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  const Question({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });
}

class ZoomQuizGame extends StatelessWidget {
  const ZoomQuizGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zoom Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D8CFF), // Zoom Blue
          primary: const Color(0xFF2D8CFF),
          secondary: const Color(0xFF0E71EB), // Zoom Dark Blue
          background: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF232333),
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF232333)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/difficulty': (context) => const DifficultySelectionScreen(),
        '/quiz':
            (context) => const QuizScreen(difficulty: QuizDifficulty.beginner),
        '/games': (context) => GamesPage(),
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam_rounded,
                size: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 40),
              const Text(
                'Zoom',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Knowledge Quiz',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 60),
              // Difficulty selection section
              Column(
                children: [
                  const Text(
                    'Select Difficulty',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Difficulty buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDifficultyButton(
                        context,
                        'Beginner',
                        Colors.green,
                        QuizDifficulty.beginner,
                      ),
                      const SizedBox(width: 12),
                      _buildDifficultyButton(
                        context,
                        'Intermediate',
                        Colors.orange,
                        QuizDifficulty.intermediate,
                      ),
                      const SizedBox(width: 12),
                      _buildDifficultyButton(
                        context,
                        'Advanced',
                        Colors.red,
                        QuizDifficulty.advanced,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Adaptive Mode button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => QuizScreen(
                                difficulty: QuizDifficulty.adaptive,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Adaptive Mode'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Go Back button
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/games');
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(
    BuildContext context,
    String text,
    Color color,
    QuizDifficulty difficulty,
  ) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(difficulty: difficulty),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(text),
    );
  }
}

class DifficultySelectionScreen extends StatelessWidget {
  const DifficultySelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Difficulty'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Choose Your Challenge Level',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF232333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              DifficultyCard(
                title: 'Beginner',
                description: 'Basic Zoom features and functions',
                icon: Icons.school,
                color: Colors.green,
                onTap: () => _navigateToQuiz(context, QuizDifficulty.beginner),
              ),
              const SizedBox(height: 16),
              DifficultyCard(
                title: 'Intermediate',
                description: 'Moderately challenging Zoom knowledge',
                icon: Icons.trending_up,
                color: Colors.blue,
                onTap:
                    () => _navigateToQuiz(context, QuizDifficulty.intermediate),
              ),
              const SizedBox(height: 16),
              DifficultyCard(
                title: 'Advanced',
                description: 'Complex Zoom features and best practices',
                icon: Icons.star,
                color: Colors.red,
                onTap: () => _navigateToQuiz(context, QuizDifficulty.advanced),
              ),
              const SizedBox(height: 16),
              DifficultyCard(
                title: 'Adaptive',
                description: 'Questions adjust based on your performance',
                icon: Icons.psychology,
                color: Colors.purple,
                onTap: () => _navigateToQuiz(context, QuizDifficulty.adaptive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToQuiz(BuildContext context, QuizDifficulty difficulty) {
    Navigator.pushNamed(context, '/quiz', arguments: difficulty);
  }
}

class DifficultyCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DifficultyCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final QuizDifficulty difficulty;

  const QuizScreen({Key? key, required this.difficulty}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  bool hasAnswered = false;
  int? selectedAnswerIndex;
  Timer? _timer;
  int _secondsRemaining = 20;
  bool _timerActive = false;
  late QuizDifficulty currentDifficulty;
  List<Question> currentQuestions = [];

  // Adaptive quiz variables
  int consecutiveCorrect = 0;
  int consecutiveWrong = 0;
  QuizDifficulty adaptiveLevel = QuizDifficulty.beginner;

  final List<Question> beginnerQuestions = [
    Question(
      question: 'How do you join a Zoom meeting?',
      options: [
        'Click the meeting link or enter meeting ID',
        'Send an email to the host',
        'Call the host on phone',
        'Wait for automatic invitation',
      ],
      correctAnswerIndex: 0,
      explanation:
          'You can join a Zoom meeting by clicking the meeting link provided or entering the meeting ID.',
    ),
    // Add more beginner questions here
  ];

  final List<Question> intermediateQuestions = [
    Question(
      question: 'What is a Zoom breakout room?',
      options: [
        'A virtual waiting area',
        'A separate session for small group discussion',
        'A chat room',
        'A break timer',
      ],
      correctAnswerIndex: 1,
      explanation:
          'Breakout rooms allow hosts to split meetings into smaller group sessions.',
    ),
    // Add more intermediate questions here
  ];

  final List<Question> advancedQuestions = [
    Question(
      question: 'Which setting allows you to reduce background noise in Zoom?',
      options: [
        'Echo cancellation',
        'Background suppression',
        'Noise suppression',
        'Audio filtering',
      ],
      correctAnswerIndex: 2,
      explanation:
          'Noise suppression helps reduce background noise during Zoom meetings.',
    ),
    // Add more advanced questions here
  ];

  @override
  void initState() {
    super.initState();
    currentDifficulty = widget.difficulty;
    _loadQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadQuestions() {
    setState(() {
      switch (currentDifficulty == QuizDifficulty.adaptive
          ? adaptiveLevel
          : currentDifficulty) {
        case QuizDifficulty.beginner:
          currentQuestions = beginnerQuestions;
          break;
        case QuizDifficulty.intermediate:
          currentQuestions = intermediateQuestions;
          break;
        case QuizDifficulty.advanced:
          currentQuestions = advancedQuestions;
          break;
        case QuizDifficulty.adaptive:
          // This case is handled by the ternary operator above
          break;
      }
      currentQuestions.shuffle();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 20;
      _timerActive = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _timer?.cancel();
    setState(() {
      _timerActive = false;
      hasAnswered = true;
      // Consider it a wrong answer if time runs out
      if (selectedAnswerIndex == null) {
        _updateAdaptiveDifficulty(false);
      }
    });
  }

  void _updateAdaptiveDifficulty(bool wasCorrect) {
    if (currentDifficulty != QuizDifficulty.adaptive) return;

    setState(() {
      if (wasCorrect) {
        consecutiveCorrect++;
        consecutiveWrong = 0;
        if (consecutiveCorrect >= 3) {
          if (adaptiveLevel == QuizDifficulty.beginner) {
            adaptiveLevel = QuizDifficulty.intermediate;
          } else if (adaptiveLevel == QuizDifficulty.intermediate) {
            adaptiveLevel = QuizDifficulty.advanced;
          }
          consecutiveCorrect = 0;
          _loadQuestions();
        }
      } else {
        consecutiveWrong++;
        consecutiveCorrect = 0;
        if (consecutiveWrong >= 2) {
          if (adaptiveLevel == QuizDifficulty.advanced) {
            adaptiveLevel = QuizDifficulty.intermediate;
          } else if (adaptiveLevel == QuizDifficulty.intermediate) {
            adaptiveLevel = QuizDifficulty.beginner;
          }
          consecutiveWrong = 0;
          _loadQuestions();
        }
      }
    });
  }

  void _handleAnswer(int answerIndex) {
    if (hasAnswered) return;

    _timer?.cancel();
    setState(() {
      selectedAnswerIndex = answerIndex;
      hasAnswered = true;
      _timerActive = false;

      if (answerIndex ==
          currentQuestions[currentQuestionIndex].correctAnswerIndex) {
        score++;
        _updateAdaptiveDifficulty(true);
      } else {
        _updateAdaptiveDifficulty(false);
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < currentQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        hasAnswered = false;
        selectedAnswerIndex = null;
        _startTimer();
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Quiz Complete!'),
            content: Text('Your score: $score/${currentQuestions.length}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Return to Menu'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentQuestions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = currentQuestions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Question ${currentQuestionIndex + 1}/${currentQuestions.length}',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: _timerActive ? _secondsRemaining / 20 : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _secondsRemaining > 5 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              question.question,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedAnswerIndex == index;
                  final isCorrect = index == question.correctAnswerIndex;
                  final showResult = hasAnswered;

                  Color? backgroundColor;
                  if (showResult) {
                    if (isCorrect) {
                      backgroundColor = Colors.green.withOpacity(0.3);
                    } else if (isSelected) {
                      backgroundColor = Colors.red.withOpacity(0.3);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed:
                          hasAnswered ? null : () => _handleAnswer(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: backgroundColor,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        question.options[index],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (hasAnswered) ...[
              const SizedBox(height: 20),
              Text(
                question.explanation,
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _nextQuestion,
                child: Text(
                  currentQuestionIndex < currentQuestions.length - 1
                      ? 'Next Question'
                      : 'See Results',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Result Screen with Supabase integration
class ResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final QuizDifficulty difficulty;

  const ResultScreen({
    Key? key,
    required this.score,
    required this.totalQuestions,
    required this.difficulty,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // Supabase client
  final supabase = Supabase.instance.client;
  bool _isSaving = false;
  bool _resultsSaved = false;
  String? _errorMessage;

  int get passThreshold => (widget.totalQuestions * 100 * 0.6).round();
  bool get isPassed => widget.score >= passThreshold;

  @override
  void initState() {
    super.initState();
    // Save results when screen loads
    saveQuizResults();
  }

  String _getDifficultyString() {
    switch (widget.difficulty) {
      case QuizDifficulty.beginner:
        return 'Beginner';
      case QuizDifficulty.intermediate:
        return 'Intermediate';
      case QuizDifficulty.advanced:
        return 'Advanced';
      case QuizDifficulty.adaptive:
        return 'Adaptive';
    }
  }

  // Function to save quiz results to Supabase
  Future<void> saveQuizResults() async {
    // Only save if results haven't been saved yet
    if (_resultsSaved) return;

    try {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      // Get current user
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isSaving = false;
        });
        return;
      }

      // Calculate max possible score
      final int maxPossibleScore = widget.totalQuestions * 100;

      // Insert quiz result
      await supabase.from('quiz_results').insert({
        'user_id': currentUser.id,
        'platform': 'Zoom', // Hardcoded for this specific quiz
        'difficulty': _getDifficultyString(),
        'score': widget.score,
        'max_possible_score': maxPossibleScore,
        'passed': isPassed,
      });

      setState(() {
        _resultsSaved = true;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save results: ${e.toString()}';
        _isSaving = false;
      });
      debugPrint('Error saving quiz results: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate performance
    final int maxPossibleScore = widget.totalQuestions * 100;
    final double percentage = (widget.score / maxPossibleScore) * 100;
    String feedback;
    Color feedbackColor;

    if (percentage >= 80) {
      feedback = 'Excellent!';
      feedbackColor = Colors.green;
    } else if (percentage >= 60) {
      feedback = 'Good job!';
      feedbackColor = Colors.blue;
    } else if (percentage >= 40) {
      feedback = 'Not bad!';
      feedbackColor = Colors.orange;
    } else {
      feedback = 'Keep practicing!';
      feedbackColor = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home),
          color: Colors.white,
          onPressed: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60), // Space for app bar
                Text(
                  isPassed ? 'You Passed!' : 'Quiz Completed',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_getDifficultyString()} Level',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                // Pass/Fail message
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isPassed ? Colors.green : Colors.red.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPassed
                        ? 'You have passed! Click below to learn a new tutorial.'
                        : 'You need more practice. Return to tutorial or try again.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.score.toString(),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'points',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  feedback,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: feedbackColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 30),
                // Saving status
                if (_isSaving)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Saving results...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                if (_resultsSaved)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Results saved!',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 30),
                // Action buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/difficulty', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/games', (route) => false);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Back to Games'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
