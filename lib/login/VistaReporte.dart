import 'dart:convert';
import 'dart:io';
import 'package:conduent/login/VistaLogin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class VistaReporte extends StatefulWidget {
  final String nombreUsuario;
  final String idIncidencia;
  final String idUsuario;

  const VistaReporte({
    Key? key,
    required this.nombreUsuario,
    required this.idIncidencia,
    required this.idUsuario,
    required UserData userData,
  }) : super(key: key);

  @override
  _VistaReporteState createState() => _VistaReporteState();
}

class _VistaReporteState extends State<VistaReporte> {
  String montoMonedas = '';
  String montoBilletes = '';
  String comentarios = '';
  bool _isButtonEnabled = false;
  late String fechafinal;

  List<XFile> fotosSeleccionadas = [];
  List<String> fotosBase64List = [];

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
    if (montoMonedas.isEmpty) {
      montoMonedas = '0,00';
    }
    if (montoBilletes.isEmpty) {
      montoBilletes = '0,00';
    }
    if (comentarios.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('¿Desea completar el reporte?'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.orange),
                            ),
                            SizedBox(height: 20),
                            Text('Enviando Reporte...'),
                          ],
                        ),
                      );
                    },
                  );
                  await _llamarAPI();
                },
                child: const Text('Si'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('No'),
              ),
            ],
          );
        },
      );
    } else {
      print('No se consumió la API porque los comentarios están vacíos.');
    }
  }

  void printtt() {
    print('${fotosBase64List}');
  }

  //api para mandar informacion de api
  Future<void> _llamarAPI() async {
    try {
      var url = Uri.parse(
          'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/updateIncidencia');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idincidencia': widget.idIncidencia,
          'mntbilletes': montoBilletes,
          'mntmonedas': montoMonedas,
          'comentarios': comentarios,
          'idusuario': widget.idUsuario,
          'imagenes': fotosBase64List,
        }),
      );
      var data = json.decode(response.body);
      print('Se subio reporte XD');
      await _updateEstadoReporte();
    } catch (error) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error al enviar el reporte'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
    }
  }

  //api para cambiar estado a Finalizado
  Future<void> _updateEstadoReporte() async {
    try {
      var url = Uri.parse(
          'http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/updateEstadoIncidencia');
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
      print('Se actualizo XD');

      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Reporte enviado'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
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
              _buildTextField(
                  'Ingrese comentarios referente a la incidencia', false,
                  (value) {
                setState(() {
                  comentarios = value;
                  _checkComentarios();
                });
              }, maxLines: 10, maxLength: 500),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  ///galeria
                  ElevatedButton.icon(
                    onPressed: () async {
                      final List<XFile> imagenes =
                          await ImagePicker().pickMultiImage();
                      if (imagenes != null) {
                        for (var imagen in imagenes) {
                          final bytes = await imagen.readAsBytes();
                          final fotoBase64 = base64Encode(bytes);
                          print('Foto en base64: $fotoBase64');
                          setState(() {
                            fotosSeleccionadas.add(imagen);
                            fotosBase64List.add(fotoBase64);
                          });
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.drive_folder_upload,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Seleccionar Fotos',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),

                  const SizedBox(width: 10),

                  ///camara
                  ElevatedButton.icon(
                    onPressed: () async {
                      final XFile? foto = await ImagePicker()
                          .pickImage(source: ImageSource.camera);
                      if (foto != null) {
                        final bytes = await foto.readAsBytes();
                        final fotoBase64 = base64Encode(bytes);
                        print('Foto en base64: $fotoBase64');
                        setState(() {
                          fotosSeleccionadas.add(foto);
                          fotosBase64List.add(fotoBase64);
                        });
                      }
                    },
                    icon: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Tomar Foto',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              fotosSeleccionadas.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'Fotos seleccionadas:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: fotosSeleccionadas.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 5,
                                        blurRadius: 7,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: GestureDetector(
                                    onLongPress: () {
                                      setState(() {
                                        fotosSeleccionadas.removeAt(index);
                                        fotosBase64List.removeAt(index);
                                      });
                                    },
                                    child: AnimatedOpacity(
                                      opacity: 1.0,
                                      duration: Duration(seconds: 2),
                                      child: Image.file(
                                        File(fotosSeleccionadas[index].path),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : SizedBox.shrink(),
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

          //onPressed: printtt,
          onPressed: _isButtonEnabled ? activarReporte : null,
          child: const Text(
            'Completar reporte',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String labelText, bool isNumeric, Function(String) onChanged,
      {int maxLines = 1, int maxLength = 100}) {
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
              keyboardType:
                  isNumeric ? TextInputType.number : TextInputType.text,
              inputFormatters: isNumeric
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))]
                  : null,
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
