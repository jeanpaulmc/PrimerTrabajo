import 'package:conduent/login/VistaLogin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'listaOrdenTrabajo.dart';

class TipoEquipo {
  final String nombre;
  final String id;
  TipoEquipo({required this.nombre, required this.id});
}

class RegistrarOrdenTrabajo extends StatefulWidget {
  final String usuario;
  final String contrasenia;
  final UserData userData;

  const RegistrarOrdenTrabajo({
    Key? key,
    required this.usuario,
    required this.contrasenia,
    required this.userData,
  }) : super(key: key);

  @override
  _RegistrarOrdenTrabajoState createState() => _RegistrarOrdenTrabajoState();
}

class _RegistrarOrdenTrabajoState extends State<RegistrarOrdenTrabajo> with WidgetsBindingObserver {
  final List<String> placasValidas = [
    '111111', '222222', '12345678', '123456', '345678', '9A1234'
  ];

  final List<String> medioComunicativo = ['WhatsApp', 'Llamada', 'Correo'];

  bool placaValida = false;
  bool medioComunicativoValido = false;

  final TextEditingController placaController = TextEditingController();
  final TextEditingController medioComunicativoController = TextEditingController();
  
  String? placaError;
  String? medioComunicativoError;


  void enviarOPT() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrdePT(
          usuario: widget.usuario,
          contrasenia: widget.contrasenia,
          userData: widget.userData,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Orden de Trabajo'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Placa de Bus
            Row(
              children: [
                const Text('Placa de Bus:'),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 60,
                    child: Autocomplete<String>(
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        controller.addListener(() {
                          setState(() {
                            placaValida = placasValidas.contains(controller.text);
                            if (controller.text.length < 6 || controller.text.length > 8) {
                              placaError = 'La placa debe tener 6 o 8 caracteres';
                            } else {
                              placaError = null;
                            }
                          });
                        });
                        placaController.text = controller.text;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Digite aquí',
                            hintStyle: const TextStyle(
                              color: Colors.black,
                            ),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            errorText: placaError,
                          ),
                          inputFormatters: [LengthLimitingTextInputFormatter(8)],
                        );
                      },
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        return placasValidas.where((placa) => placa.contains(textEditingValue.text));
                      },
                    ),
                  ),
                ),
                if (placaValida)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.check,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),

            // Información del Bus
            if (placaValida)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Emplazamiento: #######'),
                    Text('Consorcio: #######'),
                    Text('Corredor: #######'),
                  ],
                ),
              ),

            // Explicar Problema
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Problema Reportado:'),
                const SizedBox(height: 10),
                Container(
                  height: 100, // Altura mayor para permitir varias líneas
                  child: const TextField(
                    maxLines: null, // Permitir múltiples líneas
                    expands: true, // Permitir expandirse para llenar el espacio
                    textAlign: TextAlign.start, // Alinear texto al inicio
                    style: TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Escriba aquí el problema reportado',
                      hintStyle: TextStyle(
                        color: Colors.black,
                      ),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
              ],
            ),


            // Medio Comunicativo
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Medio Comunicativo:'),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 60,
                    child: Autocomplete<String>(
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        controller.addListener(() {
                          setState(() {
                            medioComunicativoValido = medioComunicativo.contains(controller.text);
                            if (!medioComunicativoValido) {
                              medioComunicativoError = 'Seleccione un medio comunicativo válido';
                            } else {
                              medioComunicativoError = null;
                            }
                          });
                        });
                        medioComunicativoController.text = controller.text;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Digite aquí',
                            hintStyle: const TextStyle(
                              color: Colors.black,
                            ),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            errorText: medioComunicativoError,
                          ),
                        );
                      },
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        return medioComunicativo.where((medio) => medio.contains(textEditingValue.text));
                      },
                    ),
                  ),
                ),
                if (medioComunicativoValido)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.check,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (placaValida && medioComunicativoValido) {
                  enviarOPT();
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'Enviar incidencia',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
