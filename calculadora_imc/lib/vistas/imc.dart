import 'package:flutter/material.dart';

class IMCCalculator extends StatefulWidget {
  const IMCCalculator({super.key});

  @override
  State<IMCCalculator> createState() => _IMCCalculatorState();
}

class _IMCCalculatorState extends State<IMCCalculator> {
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _alturaController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _resultadoIMC = "";
  String _categoria = "";

  void _calcularIMC() {
    if (_formKey.currentState!.validate()) {
      double peso = double.parse(_pesoController.text);
      double altura = double.parse(_alturaController.text);

      double imc = peso / (altura * altura);

      setState(() {
        _resultadoIMC = "Tu IMC es: ${imc.toStringAsFixed(2)}";

        if (imc < 18.5) {
          _categoria = "Categoría: Bajo peso";
        } else if (imc >= 18.5 && imc <= 24.9) {
          _categoria = "Categoría: Peso normal";
        } else if (imc >= 25.0 && imc <= 29.9) {
          _categoria = "Categoría: Sobrepeso";
        } else {
          _categoria = "Categoría: Obesidad";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calculadora de IMC"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Ingresa tu peso y altura para calcular tu IMC.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _pesoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Peso (kg)",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Ingrese el peso";
                  final n = double.tryParse(value);
                  if (n == null) return "Ingrese un número válido";
                  if (n <= 0) return "El peso debe ser positivo";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _alturaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Altura (m)",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Ingrese la altura";
                  final n = double.tryParse(value);
                  if (n == null) return "Ingrese un número válido";
                  if (n <= 0) return "La altura debe ser positiva";
                  return null;
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _calcularIMC,
                  child: const Text("Calcular IMC"),
                ),
              ),
              const SizedBox(height: 30),

              Text(
                _resultadoIMC,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _categoria,
                style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
