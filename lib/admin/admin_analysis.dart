// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'admin_newuserchart.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  // Supabase client
  final supabase = Supabase.instance.client;

  // User count state
  int userCount = 0;
  bool isLoading = true;
  String? errorMessage;
  double? growthRate;

  // New users data for bar chart
  List<UserGrowthData> userGrowthData = [];
  bool isLoadingChart = true;

  // Quiz game data for pie chart
  Map<String, QuizResultData> quizResultsData = {};
  List<String> availablePlatforms = [];
  String selectedQuizPlatform = '';
  bool isLoadingQuizData = true;

  @override
  void initState() {
    super.initState();
    // Fetch user count when the page loads
    fetchUserCount();
    fetchUserGrowthData();
    fetchQuizResults();
  }

  // Function to fetch user count from Supabase
  Future<void> fetchUserCount() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get current user count
      final response = await supabase.from('users').select('id');

      // Get count from one month ago for growth calculation
      final DateTime oneMonthAgo = DateTime.now().subtract(
        const Duration(days: 30),
      );
      final pastResponse = await supabase
          .from('users')
          .select('id')
          .lt('created_at', oneMonthAgo.toIso8601String());

      // Calculate current count and growth rate
      final currentCount = response.length;
      final pastCount = pastResponse.length;

      double growth = 0;
      if (pastCount > 0) {
        growth = ((currentCount - pastCount) / pastCount) * 100;
      }

      setState(() {
        userCount = currentCount;
        growthRate = growth;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load user count: ${e.toString()}';
        isLoading = false;
      });
      debugPrint('Error fetching user count: $e');
    }
  }

  // Function to fetch user growth data (new users over time)
  Future<void> fetchUserGrowthData() async {
    try {
      setState(() {
        isLoadingChart = true;
      });

      // Get data for the last 6 months
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

      // Format date to ISO string for Supabase query
      final fromDate = sixMonthsAgo.toIso8601String();

      // Query users created after our starting date
      final response = await supabase
          .from('users')
          .select('created_at')
          .gte('created_at', fromDate)
          .order('created_at', ascending: true);

      // Group by month
      Map<String, int> monthlyCounts = {};

      // Initialize the last 6 months with zero counts
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = DateFormat('yyyy-MM').format(month);
        monthlyCounts[monthKey] = 0;
      }

      // Count users by creation month
      for (final user in response) {
        final createdAt = DateTime.parse(user['created_at']);
        final monthKey = DateFormat('yyyy-MM').format(createdAt);

        if (monthlyCounts.containsKey(monthKey)) {
          monthlyCounts[monthKey] = (monthlyCounts[monthKey] ?? 0) + 1;
        } else {
          monthlyCounts[monthKey] = 1;
        }
      }

      // Convert to our data class format
      List<UserGrowthData> data = [];
      monthlyCounts.forEach((monthKey, count) {
        final parts = monthKey.split('-');
        final month = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
        data.add(UserGrowthData(month: month, newUsers: count));
      });

      // Sort by date
      data.sort((a, b) => a.month.compareTo(b.month));

      setState(() {
        userGrowthData = data;
        isLoadingChart = false;
      });
    } catch (e) {
      debugPrint('Error fetching user growth data: $e');
      setState(() {
        isLoadingChart = false;
      });
    }
  }

  // Function to fetch quiz results data from Supabase
  Future<void> fetchQuizResults() async {
    try {
      setState(() {
        isLoadingQuizData = true;
      });

      // Query all quiz results
      final response = await supabase
          .from('quiz_results')
          .select('platform, passed')
          .order('created_at', ascending: false);

      // Process the data by platform
      Map<String, QuizResultData> resultsMap = {};
      Set<String> platforms = {};

      for (final result in response) {
        final platform = result['platform'] as String;
        final passed = result['passed'] as bool;

        platforms.add(platform);

        if (!resultsMap.containsKey(platform)) {
          resultsMap[platform] = QuizResultData(passed: 0, failed: 0);
        }

        if (passed) {
          resultsMap[platform]!.passed++;
        } else {
          resultsMap[platform]!.failed++;
        }
      }

      // Update state with the fetched data
      setState(() {
        quizResultsData = resultsMap;
        availablePlatforms = platforms.toList()..sort();
        selectedQuizPlatform =
            availablePlatforms.isNotEmpty ? availablePlatforms.first : '';
        isLoadingQuizData = false;
      });
    } catch (e) {
      debugPrint('Error fetching quiz results: $e');
      setState(() {
        isLoadingQuizData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF), // Ghost white color
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed header section
            const Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Text(
                'Data Analysis',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF27445D),
                ),
              ),
            ),

            // User count tracking box - with loading state
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.symmetric(
                vertical: 14.0,
                horizontal: 20.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF3B6EA5).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B6EA5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Color(0xFF3B6EA5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Users',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF3B6EA5),
                            ),
                          ),
                        )
                      else if (errorMessage != null)
                        const Text(
                          'Error loading data',
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        )
                      else
                        Text(
                          userCount.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B6EA5),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (!isLoading && errorMessage == null && growthRate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: growthRate! >= 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            growthRate! >= 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 14,
                            color: growthRate! >= 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${growthRate!.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color:
                                  growthRate! >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isLoading || errorMessage != null)
                    Container(
                      width: 70, // Maintain consistent width
                    ),
                ],
              ),
            ),

            // Refresh button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  fetchUserCount();
                  fetchUserGrowthData();
                  fetchQuizResults();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3B6EA5),
                ),
              ),
            ),

            // Analytics Overview Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: const Text(
                'Analytics Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B6EA5),
                ),
              ),
            ),

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // New Users Bar Chart - UPDATED WITH ENHANCED CHART
                    Container(
                      height: 320,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF3B6EA5).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Senior Surfers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B6EA5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Monthly growth analysis',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          if (isLoadingChart)
                            const Expanded(
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            Expanded(
                              // Using the enhanced UserGrowthChart
                              child: UserGrowthChart(data: userGrowthData),
                            ),
                        ],
                      ),
                    ),

                    // Quiz Game Results Pie Chart
                    Container(
                      height: 320,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF3B6EA5).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Game Quiz Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B6EA5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pass/Fail rates by platform',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          // Platform selector
                          if (isLoadingQuizData)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (availablePlatforms.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'No quiz data available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 48,
                              child: DropdownButtonFormField<String>(
                                value: selectedQuizPlatform,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                items: availablePlatforms.map((platform) {
                                  return DropdownMenuItem<String>(
                                    value: platform,
                                    child: Text(platform),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedQuizPlatform = value;
                                    });
                                  }
                                },
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Pie chart and legend
                          Expanded(
                            child: isLoadingQuizData
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : availablePlatforms.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No quiz data to display',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          // Pie chart on the left
                                          Expanded(
                                            flex: 3,
                                            child: QuizResultsPieChart(
                                              data: quizResultsData[
                                                  selectedQuizPlatform]!,
                                            ),
                                          ),

                                          // Legend on the right
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                // Passed indicator
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 16,
                                                      height: 16,
                                                      decoration:
                                                          const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Color(
                                                          0xFF3B6EA5,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text(
                                                      'Passed',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                // Failed indicator
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 16,
                                                      height: 16,
                                                      decoration:
                                                          const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Color(
                                                          0xFFE57373,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text(
                                                      'Failed',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 24),
                                                // Stats
                                                Text(
                                                  'Total: ${quizResultsData[selectedQuizPlatform]!.total}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Pass Rate: ${quizResultsData[selectedQuizPlatform]!.passRate.toStringAsFixed(1)}%',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF3B6EA5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ],
                      ),
                    ),

                    // Additional Quiz Analytics
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF3B6EA5).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Platform Performance Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B6EA5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Comparative analysis of all platforms',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          if (isLoadingQuizData)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (availablePlatforms.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.0),
                                child: Text(
                                  'No quiz data available to compare',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: availablePlatforms.length,
                              itemBuilder: (context, index) {
                                final platform = availablePlatforms[index];
                                final data = quizResultsData[platform]!;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        platform,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: data.passed / data.total,
                                        backgroundColor: const Color(
                                          0xFFE57373,
                                        ).withOpacity(0.3),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF3B6EA5),
                                        ),
                                        minHeight: 10,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Passed: ${data.passed}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color.fromARGB(
                                                255,
                                                55,
                                                190,
                                                96,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Failed: ${data.failed}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFFE57373),
                                            ),
                                          ),
                                          Text(
                                            'Pass Rate: ${data.passRate.toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quiz Results Pie Chart Widget
class QuizResultsPieChart extends StatelessWidget {
  final QuizResultData data;

  const QuizResultsPieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PieChartPainter(passed: data.passed, failed: data.failed),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${data.passRate.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B6EA5),
              ),
            ),
            const Text(
              'Pass Rate',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for pie chart
class PieChartPainter extends CustomPainter {
  final int passed;
  final int failed;

  PieChartPainter({required this.passed, required this.failed});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = (passed + failed).toDouble();
    final double passedAngle = 2 * math.pi * (passed / total);

    final Paint passedPaint = Paint()
      ..color = const Color(0xFF3B6EA5)
      ..style = PaintingStyle.fill;

    final Paint failedPaint = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.fill;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) * 0.4;

    // Handle edge case where there's no data
    if (total <= 0) {
      // Draw empty circle with dotted border
      final Paint emptyPaint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, emptyPaint);
      return;
    }

    // Draw passed section
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top
      passedAngle,
      true,
      passedPaint,
    );

    // Draw failed section
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + passedAngle, // Start after passed section
      2 * math.pi - passedAngle,
      true,
      failedPaint,
    );

    // Draw inner circle for donut effect
    final Paint innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      radius * 0.6, // Inner circle radius
      innerCirclePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Data Classes

class QuizResultData {
  int passed;
  int failed;

  QuizResultData({required this.passed, required this.failed});

  int get total => passed + failed;
  double get passRate => total > 0 ? (passed / total) * 100 : 0;
}
