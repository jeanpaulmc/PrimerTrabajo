import 'dart:async';

import 'package:conduent/login/enviar_view_matenimiento.dart';
import 'package:conduent/login/enviar_view_personal.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  static String id = 'login_view';

  @override
  State<LoginView> createState() => _LoginViewState();

  static of(Element loginViewContext) {}
}

class UserData {
  final String idUsuario;
  final String nombreUsuario;
  final String idSeccion;
  final String idTipoUsuario;

  UserData({
    required this.idUsuario,
    required this.nombreUsuario,
    required this.idSeccion, 
    required this.idTipoUsuario,
  });
}

class _LoginViewState extends State<LoginView> {
  TextEditingController usuario = TextEditingController();
  TextEditingController contrasenia = TextEditingController();
  bool _isSecurePassword = true;
  late FlutterActivityRecognition activityRecognition;
  late StreamSubscription<Activity> _activityStreamSubscription;

  @override
  void initState() {
    super.initState();
    _requestPermissionsOnFirstRun();
    activityRecognition = FlutterActivityRecognition.instance;
    _subscribeToActivityStream();
  }

  void _requestPermissionsOnFirstRun() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool('isFirstRun') ?? true;

    if (isFirstRun) {
      await _requestBackgroundActivityPermission();
      await _requestNotificationPermission();
      await _requestPermissions();
      await prefs.setBool('isFirstRun', false);
    }
  }

  
  Future<void> _requestPermissions() async {
    // Solicitar permiso de cámara
    await Permission.camera.request();

    // Solicitar permisos de almacenamiento externo
    await Permission.storage.request();
  }

  Future<bool> isPermissionGrants(Permission permission) async {
    PermissionStatus status = await permission.status;
    if (status == PermissionStatus.permanentlyDenied) {
      debugPrint('Permission is permanently denied.');
      return false;
    } else if (status != PermissionStatus.granted) {
      PermissionStatus newStatus = await permission.request();
      if (newStatus != PermissionStatus.granted) {
        debugPrint('Permission is denied.');
        return false;
      }
    }
    return true;
  }

  Future<void> _requestBackgroundActivityPermission() async {
    bool isPermissionGranted = await isPermissionGrants(Permission.activityRecognition);
    if (!isPermissionGranted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Permitir actividad en segundo plano'),
            content: Text('¿Desea permitir que la aplicación acceda a la actividad en segundo plano?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  await isPermissionGrants(Permission.activityRecognition);
                  Navigator.of(context).pop();
                },
                child: Text('Sí'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _requestNotificationPermission() async {
    bool isPermissionGranted = await isPermissionGrants(Permission.notification);
    if (!isPermissionGranted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Permitir notificaciones'),
            content: const Text('¿ Desea permitir que la aplicación envíe notificaciones?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  await isPermissionGrants(Permission.notification);
                  Navigator.of(context).pop();
                },
                child: Text('Sí'),
              ),
            ],
          );
        },
      );
    }
  }

  void _subscribeToActivityStream() {
    _activityStreamSubscription = activityRecognition.activityStream
      .handleError(_handleError)
      .listen(_onActivityReceive);
  }

  void _handleError(Object error) {
    debugPrint('Error on activity stream: $error');
  }

  void _onActivityReceive(Activity activity) {
    debugPrint('Activity received: ${activity.type}');
    // Handle received activity here
  }

  @override
  void dispose() {
    _activityStreamSubscription.cancel();
    super.dispose();
  }

  void ingresar() async {
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
              Text('Iniciando sesión...'),
            ],
          ),
        );
      },
    );

    var url = Uri.parse('http://200.37.244.149:8002/acsgestionequipos/ApiRestIncidencia/validarLoginMovil');

    String miContrasenia = contrasenia.text;
    var sha256Result = sha256.convert(utf8.encode(miContrasenia));
    String contraseniaEncriptadaBase64 = base64.encode(utf8.encode(sha256Result.toString()));

    var body = {
      "usuario": usuario.text,
      "contrasenia": contraseniaEncriptadaBase64,
    };

    print('Body: $body');

    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    ).timeout(const Duration(seconds: 20));

    Navigator.of(context).pop(); // Ocultar el diálogo de inicio de sesión

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      int estado = data['estado'];
      String msj = data['msj'];

      if (estado == 1) {
        var idTipoUsuario = data['result'][0]['ID_TIPOUSUARIO'];
        var idUsuario = data['result'][0]['ID_USUARIO'];
        var nombreUsuario = data['result'][0]['NOMBRE'];
        var idSeccion = data['result'][0]['ID_SESSION'];

        print('Estado: $estado');
        print('Mensaje: $msj');
        print('Id Usuario: $idUsuario');
        print('Nombre: $nombreUsuario');
        print('Seccion: $idSeccion');

        print('Response Incio Seccion Login: ${response.body}');

        UserData userData = UserData(
          idUsuario: idUsuario,
          nombreUsuario: nombreUsuario,
          idSeccion: idSeccion,
          idTipoUsuario: idTipoUsuario,
        );

        if (idTipoUsuario == '5' || idTipoUsuario == '6' || idTipoUsuario == '7') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EnviarPersonal(
                userData: userData,
                usuario: usuario.text,
                contrasenia: contrasenia.text,
              ),
            ),
          );
          ///// CAMBIAR ADMIN  || idTipoUsuario == '1'
        } else if (idTipoUsuario == '8' || idTipoUsuario == '1') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EnviarMantenimiento(    
                userData: userData,
                usuario: usuario.text,
                contrasenia: contrasenia.text,
              ),
            ),
          );
        }
      } else {
        // Error en el inicio de sesión
        mostrarError('Usuario o contraseña incorrectas.');
      }
    } else {
      // Error en la solicitud HTTP
      mostrarError('Error en la solicitud: ${response.statusCode}');
    }
  }

  void mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200.0,
                  width: 300.0,
                  child: Image.asset(
                    'assets/conduent.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(
                    top: AppBar().preferredSize.height + 15,
                    bottom: 5,
                  ),
                  child: AppBar(
                    title: const Text('Bienvenido al registro de seguimiento', style: TextStyle(fontSize: 20)),
                  ),
                ),
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/user.png',
                        height: 24,
                        width: 24,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: usuario,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            labelStyle: TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.w700,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/block.png',
                        height: 24,
                        width: 24,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: contrasenia,
                          obscureText: _isSecurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.w700,
                            ),
                            suffixIcon: togglePassword(),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                SizedBox(
                  width: 400,
                  child: ElevatedButton(
                    onPressed: () {
                      if (usuario.text.isNotEmpty && contrasenia.text.isNotEmpty) {
                        ingresar();
                      } else {
                        mostrarError('Por favor, ingrese usuario y contraseña');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      'Iniciar sesión',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget togglePassword() {
    return IconButton(
      onPressed: () {
        setState(() {
          _isSecurePassword = !_isSecurePassword;
        });
      },
      icon: _isSecurePassword ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off),
      color: Colors.grey,
    );
  }
}
