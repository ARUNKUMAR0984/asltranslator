import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(SpeechToASLApp());
}

class SpeechToASLApp extends StatefulWidget {
  @override
  _SpeechToASLAppState createState() => _SpeechToASLAppState();
}

class _SpeechToASLAppState extends State<SpeechToASLApp> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the mic and start speaking...';
  List<String> _words = [];
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _showVisualFeedback = false;
  
  // Controller for horizontal scrolling
  final ScrollController _scrollController = ScrollController();

  // Color scheme
  final Color primaryColor = Color(0xFF6A4C93);
  final Color secondaryColor = Color(0xFF8D72E1);
  final Color accentColor = Color(0xFFF26A8D);
  final Color backgroundLight = Color(0xFFF5F7FB);
  final Color textDark = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    
    // Animation controller for visual feedback
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (_isListening) {
          _animationController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('Status: $val');
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            _animationController.stop();
          }
        },
        onError: (val) => print('Error: $val'),
      );
      
      if (available) {
        setState(() {
          _isListening = true;
          _showVisualFeedback = true;
        });
        
        // Start animation and vibration feedback
        _animationController.forward();
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 150);
        }
        
        _speech.listen(
          onResult: (val) {
            String spoken = val.recognizedWords;
            setState(() {
              _text = spoken;
              // Split the text into words
              _words = _extractWords(spoken);
              
              // Provide haptic feedback for new words
              if (val.finalResult && spoken.isNotEmpty) {
                Vibration.vibrate(duration: 100);
                
                // Auto-scroll to the end when new words are added
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            });
          },
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _showVisualFeedback = false;
      });
      _animationController.stop();
      _speech.stop();
    }
  }

  List<String> _extractWords(String text) {
    // Remove any special characters and split by spaces
    return text
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
  }

  List<String> _wordToCharacters(String word) {
    // Convert word to uppercase and get characters
    return word.toUpperCase().split('');
  }

  Widget _buildHorizontalASLContainer() {
    return SizedBox(
      height: 350, // Fixed height for the horizontal container
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _words.length,
        itemBuilder: (context, wordIndex) {
          String word = _words[wordIndex];
          List<String> characters = _wordToCharacters(word);
          
          // Create the word container with its content
          Widget wordContainer = Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: 250, // Fixed width for each word container
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Word header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      word.toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                // Character container
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 16,
                        children: characters.asMap().entries.map((entry) {
                          int index = entry.key;
                          String char = entry.value;
                          
                          // Create a color gradient based on character position
                          Color containerColor = HSLColor.fromColor(secondaryColor)
                              .withLightness(0.75 + (index % 5) * 0.05)
                              .toColor();
                          
                          Widget characterWidget = Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      containerColor,
                                      containerColor.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'assests/images/$char.jpg',
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Text(
                                            char,
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  char,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          );
                          
                          // Apply animation to character widget
                          return characterWidget.animate()
                            .fadeIn(
                              delay: Duration(milliseconds: 100 * index), 
                              duration: Duration(milliseconds: 300)
                            )
                            .scale(
                              begin: Offset(0.8, 0.8), 
                              end: Offset(1, 1), 
                              curve: Curves.elasticOut, 
                              duration: Duration(milliseconds: 500)
                            );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
          
          // Apply animation to the entire word container
          return wordContainer.animate()
            .fadeIn(delay: Duration(milliseconds: 200), duration: Duration(milliseconds: 400))
            .slideX(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
        },
      ),
    );
  }

  // Auto-scrolling carousel for words
  Widget _buildAnimatedCarousel() {
    if (_words.isEmpty) {
      return Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              spreadRadius: 2,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sign_language_rounded,
                size: 60,
                color: primaryColor.withOpacity(0.4),
              ),
              SizedBox(height: 16),
              Text(
                "Words will be displayed here\nwith ASL finger spelling",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textDark.withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe, color: primaryColor),
                SizedBox(width: 8),
                Text(
                  "Swipe to see more words",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildHorizontalASLContainer(),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(12, (index) {
              double sinValue = index % 3 == 0 
                  ? _animation.value 
                  : index % 3 == 1 
                      ? (_animation.value + 0.3) % 1 
                      : (1 - _animation.value);
              
              // Create a color gradient for the bars
              Color barColor = index % 3 == 0 
                  ? accentColor 
                  : index % 3 == 1
                      ? primaryColor
                      : secondaryColor;
                      
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 3),
                width: 5,
                height: 45 * sinValue,
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          background: backgroundLight,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: backgroundLight,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
        ),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      darkTheme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          secondary: secondaryColor,
          background: Color(0xFF121212),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.sign_language, size: 28),
              SizedBox(width: 10),
              Text(
                "ASL Translator Pro",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.school, color: primaryColor),
                        SizedBox(width: 10),
                        Text("How to Use"),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInstructionStep(1, "Tap the microphone button to begin listening"),
                        SizedBox(height: 12),
                        _buildInstructionStep(2, "Speak clearly into your device's microphone"),
                        SizedBox(height: 12),
                        _buildInstructionStep(3, "The app will display words with ASL finger spelling"),
                        SizedBox(height: 12),
                        _buildInstructionStep(4, "Swipe horizontally to view all translated words"),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("CLOSE", style: TextStyle(color: primaryColor)),
                      ),
                    ],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    backgroundColor: Colors.white,
                  ),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withOpacity(0.05),
                secondaryColor.withOpacity(0.1),
                backgroundLight,
              ],
              stops: [0.0, 0.3, 1.0],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.text_fields, color: primaryColor),
                              SizedBox(width: 8),
                              Text(
                                "Spoken Text:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            _text,
                            style: TextStyle(
                              fontSize: 24,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 14),
                          if (_showVisualFeedback) _buildWaveform(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  AvatarGlow(
                    animate: _isListening,
                    glowColor: accentColor,
                
                    duration: Duration(milliseconds: 2000),
                    repeat: true,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryColor, secondaryColor],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        onPressed: _listen,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _isListening ? "Tap to stop" : "Tap to speak",
                    style: TextStyle(
                      fontSize: 16,
                      color: textDark.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.language, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "ASL Words",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: _buildAnimatedCarousel(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInstructionStep(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}