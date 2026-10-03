import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../widgets/language_toggel.dart';
import '../models/pesticide_model.dart';
import '../models/source_model.dart';
import '../widgets/pesticide_card.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? spokenText;
  final String? detectedCrop;
  final String? detectedDisease;
  final List<String> actionItems;
  final List<PesticideModel> pesticides;
  final List<SourceModel> sources;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.spokenText,
    this.detectedCrop,
    this.detectedDisease,
    this.actionItems = const [],
    this.pesticides = const [],
    this.sources = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with SingleTickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isListening = false;
  bool _isSpeaking = false;
  String? _currentlyPlayingMessageText;
  bool _isLoading = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial AI greeting message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isEnglish = Provider.of<AppStateProvider>(context, listen: false).isEnglish;
      _addInitialGreeting(isEnglish);
    });
  }

  void _addInitialGreeting(bool isEnglish) {
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          isUser: false,
          text: isEnglish
              ? "Namaste! I am your Phytivra Agri AI Voice Assistant. Speak or type your crop problem, symptom, or question."
              : "नमस्ते! मैं आपका फाइटिवरा कृषि एआई वॉइस सहायक हूँ। बोलकर या लिखकर अपनी फसल की समस्या या लक्षण बताएं।",
          spokenText: isEnglish
              ? "Hello! Speak or type your crop symptom."
              : "नमस्ते! बोलकर अपनी फसल की समस्या बताएं।",
          actionItems: isEnglish
              ? [
                  "Tap the microphone button to speak in Hindi or English.",
                  "Or select one of the suggested questions below.",
                ]
              : [
                  "हिंदी या अंग्रेजी में बोलने के लिए माइक बटन दबाएं।",
                  "या नीचे दिए गए सुझावों में से चुनें।",
                ],
        ),
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Sends a query either from voice or text input
  Future<void> _handleQuery(String queryText) async {
    final text = queryText.trim();
    if (text.isEmpty) return;

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final isEnglish = appState.isEnglish;
    final lang = appState.languageCode;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _textController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // 1. Attempt to call FastAPI ML /voice/chat endpoint
      final uri = Uri.parse("http://127.0.0.1:8001/voice/chat");
      final response = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: json.encode({"query": text, "language": lang}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _handleServerSuccessResponse(data);
        return;
      }
    } catch (_) {
      // Fallback locally if external service is offline
    }

    // Local AI Reasoning Fallback
    _handleLocalFallbackResponse(text, isEnglish);
  }

  void _handleServerSuccessResponse(Map<String, dynamic> data) {
    List<PesticideModel> parsedPests = [];
    if (data['pesticides'] is List) {
      parsedPests = (data['pesticides'] as List)
          .whereType<Map<String, dynamic>>()
          .map((p) => PesticideModel.fromJson(p))
          .toList();
    }

    List<SourceModel> parsedSources = [];
    if (data['sources'] is List) {
      parsedSources = (data['sources'] as List)
          .whereType<Map<String, dynamic>>()
          .map((s) => SourceModel.fromJson(s))
          .toList();
    }

    List<String> actions = [];
    if (data['action_items'] is List) {
      actions = (data['action_items'] as List).map((e) => e.toString()).toList();
    }

    setState(() {
      _isLoading = false;
      _messages.add(
        ChatMessage(
          isUser: false,
          text: data['reply_text'] ?? "Analysis completed.",
          spokenText: data['spoken_text'],
          detectedCrop: data['detected_crop'],
          detectedDisease: data['detected_disease'],
          actionItems: actions,
          pesticides: parsedPests,
          sources: parsedSources,
        ),
      );
    });
    _scrollToBottom();
  }

  void _handleLocalFallbackResponse(String text, bool isEnglish) {
    final queryLower = text.toLowerCase();

    bool isBlight = queryLower.contains('yellow') ||
        queryLower.contains('पील') ||
        queryLower.contains('blight') ||
        queryLower.contains('झुलसा') ||
        queryLower.contains('धब्बे') ||
        queryLower.contains('spot');

    bool isMildew = queryLower.contains('powder') ||
        queryLower.contains('white') ||
        queryLower.contains('सफेद') ||
        queryLower.contains('mildew');

    String replyText;
    String spokenText;
    String? crop;
    String? disease;
    List<String> actions = [];
    List<PesticideModel> pests = [];
    List<SourceModel> sources = [];

    if (isBlight) {
      crop = "Tomato";
      disease = "Early Blight";
      replyText = isEnglish
          ? "Based on your description of yellowing leaves and concentric spots, this indicates Early Blight (Alternaria solani). Apply Mancozeb 63% + Carbendazim 12% WP (Saaf) at 2g/L."
          : "पत्तियों पर पीले धब्बे और झुलसन के लक्षण टमाटर के अगेती झुलसा (अर्ली ब्लाइट) रोग की पुष्टि करते हैं। साफ फफूंदनाशक (2 ग्राम प्रति लीटर पानी) का छिड़काव करें।";
      spokenText = isEnglish
          ? "Symptoms match Early Blight on Tomato. Spray Saaf fungicide at 2 grams per liter."
          : "टमाटर में अगेती झुलसा रोग है। 2 ग्राम प्रति लीटर साफ फफूंदनाशक का छिड़काव करें।";
      actions = isEnglish
          ? [
              "Prune and safely destroy lower infected leaves.",
              "Avoid wetting leaves during irrigation.",
              "Repeat spray after 7-10 days if symptoms persist."
            ]
          : [
              "संक्रमित निचली पत्तियों को तोड़कर नष्ट करें।",
              "सिंचाई के समय पत्तियों पर पानी न पड़ने दें।",
              "लक्षण जारी रहने पर 7-10 दिनों बाद छिड़काव दोहराएं।"
            ];
      pests = [
        PesticideModel(
          id: 1,
          name: "Saaf (Mancozeb 63% + Carbendazim 12% WP)",
          companyName: "UPL Ltd.",
          activeIngredient: "Mancozeb 63% + Carbendazim 12% WP",
          description: isEnglish
              ? "Proven contact and systemic fungicide for controlling blights and leaf spots."
              : "पत्तियों के धब्बों और झुलसा रोग के नियंत्रण हेतु प्रमाणित फफूंदनाशक।",
          dosage: "1.5 - 2.0 g/L",
          sprayMethod: "Foliar spray",
          priceRange: "₹380 - ₹480 per 500g",
          packingSize: "500g",
          precautions: "Wear gloves and mask. 7 days withholding interval.",
          sourceType: "government",
          sourceUrl: "https://cibrc.gov.in",
        )
      ];
      sources = [
        SourceModel(
          title: "CIBRC Approved Pesticide Register",
          url: "https://cibrc.gov.in",
          sourceType: "government",
          verified: true,
        )
      ];
    } else if (isMildew) {
      crop = "Vegetable";
      disease = "Powdery Mildew";
      replyText = isEnglish
          ? "White powdery coating indicates Powdery Mildew. Spray Wettable Sulfur 80% WDG at 2 to 3 grams per liter."
          : "सफेद पाउडर जैसी फफूंद चूर्णिल आसिता (पाउडरी मिल्ड्यू) है। घुलनशील गंधक (सल्फर 80% WDG) 2-3 ग्राम प्रति लीटर पानी में मिलाकर छिड़कें।";
      spokenText = isEnglish
          ? "White coating is Powdery Mildew. Use Wettable Sulfur 2 grams per liter."
          : "सफेद फफूंद के लिए घुलनशील सल्फर का छिड़काव करें।";
      actions = isEnglish
          ? ["Ensure proper plant spacing for sunlight and ventilation."]
          : ["खेत में उचित धूप और हवा की व्यवस्था रखें।"];
      pests = [
        PesticideModel(
          id: 10,
          name: "Sulfex (Wettable Sulfur 80% WDG)",
          companyName: "Excel Crop Care",
          activeIngredient: "Wettable Sulfur 80% WDG",
          description: isEnglish
              ? "Contact fungicide and acaricide for powdery mildew control."
              : "चूर्णिल आसिता के नियंत्रण हेतु प्रभावी फफूंदनाशक।",
          dosage: "2.0 - 3.0 g/L",
          sprayMethod: "Foliar spray",
          priceRange: "₹160 - ₹220 per 500g",
          packingSize: "500g",
          precautions: "Do not spray during intense afternoon heat (>35°C).",
          sourceType: "official",
          sourceUrl: "https://cibrc.gov.in",
        )
      ];
    } else {
      crop = "Crop Field";
      disease = "General Inquiry";
      replyText = isEnglish
          ? "We have recorded your query: '$text'. For an accurate diagnosis and verified prescription, we recommend capturing a close-up photo of the leaf using the Scanner."
          : "आपका प्रश्न दर्ज किया गया: '$text'। सटीक पहचान और दवा की सही जानकारी के लिए कृपया कैमरे से पत्ती की साफ फोटो लेकर स्कैन करें।";
      spokenText = isEnglish
          ? "Please take a clear photo of the leaf for exact diagnosis."
          : "सटीक दवा के लिए कृपया कैमरे से पत्ती की फोटो स्कैन करें।";
      actions = isEnglish
          ? ["Open Photo Scanner to upload an affected leaf image."]
          : ["पत्ती की फोटो स्कैन करने के लिए कैमरा खोलें।"];
    }

    setState(() {
      _isLoading = false;
      _messages.add(
        ChatMessage(
          isUser: false,
          text: replyText,
          spokenText: spokenText,
          detectedCrop: crop,
          detectedDisease: disease,
          actionItems: actions,
          pesticides: pests,
          sources: sources,
        ),
      );
    });
    _scrollToBottom();
  }

  /// Simulates voice speech capture with pulsating listening wave
  void _startVoiceListening() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final isEnglish = appState.isEnglish;

    setState(() {
      _isListening = true;
    });

    // Simulated speech recognition recognition delay
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });

      final sampleSpokenQuery = isEnglish
          ? "My tomato leaves have yellow spots with dark concentric rings, what should I spray?"
          : "टमाटर की पत्तियों पर पीले धब्बे और काले छल्ले दिख रहे हैं, कौन सी दवा छिड़कें?";

      _handleQuery(sampleSpokenQuery);
    });
  }

  /// Simulates audio text-to-speech playback for the farmer
  void _playAudioResponse(ChatMessage message) {
    if (_isSpeaking && _currentlyPlayingMessageText == message.text) {
      setState(() {
        _isSpeaking = false;
        _currentlyPlayingMessageText = null;
      });
      return;
    }

    setState(() {
      _isSpeaking = true;
      _currentlyPlayingMessageText = message.text;
    });

    // Auto-stop speech animation after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _currentlyPlayingMessageText == message.text) {
        setState(() {
          _isSpeaking = false;
          _currentlyPlayingMessageText = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isEnglish = appState.isEnglish;

    final List<String> suggestions = isEnglish
        ? [
            "Yellow spots on tomato leaves",
            "Best pesticide for Early Blight",
            "White powder on leaves",
            "Saaf dosage per liter"
          ]
        : [
            "टमाटर की पत्तियों पर पीले धब्बे",
            "अर्ली ब्लाइट की असरदार दवा",
            "पत्तियों पर सफेद पाउडर",
            "साफ दवा का सही डोज"
          ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.record_voice_over, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(isEnglish ? "Agri AI Voice Assistant" : "कृषि एआई वॉइस सहायक"),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: LanguageToggleWidget(
              isEnglish: isEnglish,
              onToggle: (val) => appState.toggleLanguage(val),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Voice Suggestions horizontal bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: const Color(0xFFF1F8E9),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates, size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: 6),
                  Text(
                    isEnglish ? "Quick Voice Prompts:" : "त्वरित प्रश्न:",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...suggestions.map(
                    (sugg) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        avatar: const Icon(Icons.mic, size: 14, color: AppTheme.primaryGreen),
                        label: Text(sugg, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFA5D6A7)),
                        onPressed: () => _handleQuery(sugg),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildLoadingBubble(isEnglish);
                }
                final message = _messages[index];
                return _buildMessageItem(message, isEnglish);
              },
            ),
          ),

          // Listening overlay wave if active
          if (_isListening) _buildListeningWaveIndicator(isEnglish),

          // Bottom Voice & Text Bar
          _buildInputBar(isEnglish),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble(bool isEnglish) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC8E6C9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
            ),
            const SizedBox(width: 12),
            Text(
              isEnglish ? "Agri AI is reasoning..." : "कृषि एआई विचार कर रहा है...",
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningWaveIndicator(bool isEnglish) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: const Icon(Icons.mic, color: Colors.red, size: 28),
          ),
          const SizedBox(width: 12),
          Text(
            isEnglish ? "Listening... Speak your crop symptoms now" : "सुन रहे हैं... फसल के लक्षण बोलें",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message, bool isEnglish) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade900.withOpacity(0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.record_voice_over, color: Colors.white70, size: 16),
            ],
          ),
        ),
      );
    }

    // AI Response Message Card
    final bool isAudioActive = _isSpeaking && _currentlyPlayingMessageText == message.text;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(
            color: isAudioActive ? AppTheme.primaryGreen : const Color(0xFFC8E6C9),
            width: isAudioActive ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Header with Voice Playback button
            Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.lightGreen,
                  child: Icon(Icons.smart_toy, size: 14, color: AppTheme.primaryGreen),
                ),
                const SizedBox(width: 8),
                Text(
                  isEnglish ? "Phytivra Agri AI" : "फाइटिवरा कृषि एआई",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const Spacer(),
                // Audio Speak / Wave Button
                InkWell(
                  onTap: () => _playAudioResponse(message),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAudioActive ? AppTheme.primaryGreen : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAudioActive ? Icons.volume_up : Icons.play_circle_outline,
                          size: 16,
                          color: isAudioActive ? Colors.white : AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAudioActive
                              ? (isEnglish ? "Speaking..." : "बोल रहे हैं...")
                              : (isEnglish ? "Listen" : "सुनें"),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAudioActive ? Colors.white : AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Detected Diagnosis Badges
            if (message.detectedDisease != null) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (message.detectedCrop != null)
                    Chip(
                      label: Text("Crop: ${message.detectedCrop}", style: const TextStyle(fontSize: 11, color: Colors.green)),
                      backgroundColor: const Color(0xFFE8F5E9),
                      visualDensity: VisualDensity.compact,
                    ),
                  Chip(
                    label: Text("Condition: ${message.detectedDisease}", style: const TextStyle(fontSize: 11, color: Colors.red)),
                    backgroundColor: Colors.red.shade50,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Message text
            Text(
              message.text,
              style: const TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.35),
            ),

            // Actionable Steps
            if (message.actionItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBE7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDCEDC8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnglish ? "Recommended Actions:" : "सुझाए गए कदम:",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    ...message.actionItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ", style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                            Expanded(child: Text(item, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Associated Pesticides
            if (message.pesticides.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                isEnglish ? "Verified Chemical / Organic Treatment:" : "प्रमाणित कीटनाशक / उपचार:",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 6),
              ...message.pesticides.map(
                (p) => PesticideCard(
                  pesticide: p,
                  isEnglish: isEnglish,
                ),
              ),
            ],

            // Direct Scan Leaf Shortcut Button
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt, size: 16, color: AppTheme.primaryGreen),
              label: Text(
                isEnglish ? "Scan Crop Leaf with Camera" : "कैमरे से पत्ती स्कैन करें",
                style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/upload');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isEnglish) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Voice Microphone Pulsing Button
            GestureDetector(
              onTap: _startVoiceListening,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.red : AppTheme.primaryGreen,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : AppTheme.primaryGreen).withOpacity(0.4),
                          blurRadius: _isListening ? 12 : 6,
                          spreadRadius: _isListening ? 3 : 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 26,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),

            // Text input field
            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: _handleQuery,
                decoration: InputDecoration(
                  hintText: isEnglish
                      ? "Speak or type crop symptoms..."
                      : "फसल के लक्षण बोलें या लिखें...",
                  hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFC8E6C9)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FBF9),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send icon button
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.primaryGreen),
              onPressed: () => _handleQuery(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}
