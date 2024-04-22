import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class VistaReporte extends StatefulWidget {
  final String nombreUsuario;
  final String idIncidencia;
  final String idUsuario;

  const VistaReporte({
    Key? key,
    required this.nombreUsuario,
    required this.idIncidencia,
    required this.idUsuario,
  }) : super(key: key);

  @override
  _VistaReporteState createState() => _VistaReporteState();
}

class _VistaReporteState extends State<VistaReporte> {
  String montoMonedas = '';
  String montoBilletes = '';
  String comentarios = '';
  bool _isButtonEnabled = false; 

  @override
  void initState() {
    super.initState();
    _checkComentarios();
  }

  void _checkComentarios() {
    setState(() {
      _isButtonEnabled = comentarios.isNotEmpty;
    });
  }

  void activarReporte() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              SizedBox(height: 20),
              Text('Enviando Reporte...'),
            ],
          ),
        );
      },
    );
    if (montoMonedas.isEmpty) {
      montoMonedas = '0,00';
    }
    if (montoBilletes.isEmpty) {
      montoBilletes = '0,00';
    }
    if (comentarios.isNotEmpty) {
      await _llamarAPI();
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Center(child: Text('Reporte enviado')),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pop(context);
                },
                child: const Center(
                 child: Text('OK'),
                ),
              ),
            ],
          );
        },
      );
    } else {
      print('No se consumió la API porque los comentarios están vacíos.');
    }
  }

  // api de mandado de repote
  Future<void> _llamarAPI() async {
    final url = Uri.parse('http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/updateIncidencia');
    final response = await http.post(
      url,
      body: jsonEncode({
        'idincidencia': widget.idIncidencia,
        'mntbilletes': montoBilletes,
        'mntmonedas': montoMonedas,
        'comentarios': comentarios,
        'idusuario': widget.idUsuario,
      }),
    );
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Se consumió la API correctamente $responseData');
      await _updateEstadoReporte();   
    } else {
      print('Error al consumir la API. Código de estado: ${response.statusCode}');
      // También puedes manejar el error de otra manera
    }
  }

  //api de actualizacion de estado
  Future<void> _updateEstadoReporte() async {
    try {
      var url = Uri.parse('http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/updateEstadoIncidencia');
      var response = await http.post(
        url,
      
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idusuario': widget.idUsuario,
          'idincidencia': widget.idIncidencia,
        }),
      );

      var data = json.decode(response.body);
      var estado = data['estado'];
      var msj = data['msj'];

      print('Estado de la actualización: $estado');
      print('Mensaje de la actualización: $msj');
    } catch (error) {
      print('Error al realizar algo especial: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuario: ${widget.nombreUsuario}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Registro de reporte',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildTextField('Monto de monedas (opcional)', true, (value) {
                setState(() {
                  montoMonedas = value;
                });
              }),
              const SizedBox(height: 10),
              _buildTextField('Monto de billetes (opcional)', true, (value) {
                setState(() {
                  montoBilletes = value;
                });
              }),
              const SizedBox(height: 10),
              _buildTextField('Ingrese comentarios referente a la incidencia', false, (value) {
                setState(() {
                  comentarios = value;
                  _checkComentarios();
                });
              }, maxLines: 10, maxLength: 500), 
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.orange,
          ),
          onPressed: _isButtonEnabled ? activarReporte : null,
          child: const Text(
            'Completar reporte',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, bool isNumeric, Function(String) onChanged, {int maxLines = 1, int maxLength = 100}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontSize: 15, 
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextField(
              keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
              inputFormatters: isNumeric ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))] : null,
              onChanged: onChanged,
              maxLines: maxLines,
              maxLength: maxLength, 
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
