import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class GroceryPage extends StatefulWidget {
  const GroceryPage({super.key});

  @override
  State<GroceryPage> createState() => _GroceryPageState();
}

class _GroceryPageState extends State<GroceryPage> {
  final TextEditingController _textController = TextEditingController();
  final List<String> groceryList = [];

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
    );

    if (!available) {
      debugPrint('Speech not available');
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      localeId: 'en_US', // เปลี่ยนเป็น en_US ถ้าพูดอังกฤษ
      onResult: (result) {
        setState(() {
          _textController.text = result.recognizedWords;
        });
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  // ✍️ Process text or voice input
  void _addGroceryItem() {
    if (_textController.text.isEmpty) return;

    List<String> items = _textController.text.split(RegExp(r',|และ'));
    setState(() {
      groceryList.addAll(items.map((e) => e.trim()));
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Grocery Planner')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'พิมพ์หรือพูดรายการของ',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  onPressed: () {
                    _isListening ? _stopListening() : _startListening();
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addGroceryItem,
              child: const Text('เพิ่มรายการ'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: groceryList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: Text(groceryList[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
