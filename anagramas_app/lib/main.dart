import 'package:flutter/material.dart';

void main() {
  runApp(const AnagramApp());
}

class AnagramApp extends StatelessWidget {
  const AnagramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Verificador de Anagramas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AnagramHomePage(),
    );
  }
}

class AnagramHomePage extends StatefulWidget {
  const AnagramHomePage({super.key});

  @override
  State<AnagramHomePage> createState() => _AnagramHomePageState();
}

class _AnagramHomePageState extends State<AnagramHomePage> {
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _secondController = TextEditingController();

  String _resultMessage = '';
  bool _isAnagram = false;

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  String _normalize(String input) {
    final onlyLetters = input.toLowerCase().replaceAll(
      RegExp(r'[^a-záéíóúüñ]'),
      '',
    );
    final chars = onlyLetters.split('')..sort();
    return chars.join();
  }

  void _checkAnagrams() {
    final text1 = _firstController.text;
    final text2 = _secondController.text;

    if (text1.trim().isEmpty || text2.trim().isEmpty) {
      setState(() {
        _resultMessage = 'Por favor ingresa las dos palabras o frases.';
        _isAnagram = false;
      });
      return;
    }

    final normalized1 = _normalize(text1);
    final normalized2 = _normalize(text2);

    if (normalized1.isEmpty || normalized2.isEmpty) {
      setState(() {
        _resultMessage =
            'Las entradas deben contener al menos una letra para poder evaluar.';
        _isAnagram = false;
      });
      return;
    }

    setState(() {
      if (normalized1 == normalized2) {
        _isAnagram = true;
        _resultMessage = '¡Son anagramas!';
      } else {
        _isAnagram = false;
        _resultMessage = 'No son anagramas.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificador de Anagramas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'App anagramas profesor Fray.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _firstController,
              decoration: const InputDecoration(
                labelText: 'Primera palabra o frase',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _secondController,
              decoration: const InputDecoration(
                labelText: 'Segunda palabra o frase',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _checkAnagrams(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _checkAnagrams,
                child: const Text('Verificar'),
              ),
            ),
            const SizedBox(height: 24),
            if (_resultMessage.isNotEmpty)
              Center(
                child: Text(
                  _resultMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isAnagram ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
