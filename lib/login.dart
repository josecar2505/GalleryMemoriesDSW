import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gallery_memories/inicioApp.dart';
import 'package:gallery_memories/crearUsuario.dart';

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _forKey = GlobalKey<FormState>();
  TextEditingController _emailCont = TextEditingController();
  TextEditingController _contrasenaCont = TextEditingController();

  String email = "";
  String contrasena = "";

  void _iniciarSesion() async {
    try {
      // Intenta iniciar sesión utilizando el método signInWithEmailAndPassword de FirebaseAuth.
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, // Email del usuario proporcionado para iniciar sesión.
        password: contrasena, // Contraseña del usuario proporcionada para iniciar sesión.
      );

      // Muestra un mensaje de bienvenida utilizando un SnackBar con el email del usuario que inició sesión.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bienvenido: ${userCredential.user!.email}"),),
      );

      // Una vez que el usuario ha iniciado sesión con éxito, navega a la pantalla de inicio de la aplicación.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => inicioApp()), // Navega a la pantalla inicioApp.
      );
    } catch (e) {
      // Si ocurre un error durante el inicio de sesión, se captura y se muestra un mensaje de error.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al Iniciar Sesión, Usuario o Contraseña incorrectas."),),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF3498DB),
              Color.fromARGB(256, 55, 199, 250),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
            padding: EdgeInsets.only(top: 90),
            children:[
              Padding(
                padding: EdgeInsets.all(10),
                child: Form(
                  key: _forKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(
                                'https://lh3.googleusercontent.com/PR4YNyUGM1GVHd8AF0_QzyPQWUntGWlixfaviDsXVinwoGrwzpaynpNiV6OgQwE8vCM=s180'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),  //Imagen de la APP
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Text(
                              "Gallery Memories",
                              style: TextStyle(
                                fontSize: 38,
                                color: Colors.white,
                                fontFamily: 'BebasNeue',
                              ),
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _emailCont,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Email",
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Ingrese un correo";
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  email = value;
                                });
                              },
                            ),
                            SizedBox(height: 15),
                            TextFormField(
                              controller: _contrasenaCont,
                              keyboardType: TextInputType.text,
                              obscureText: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Contraseña",
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Ingrese la contraseña";
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  contrasena = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () {
                          if (_forKey.currentState!.validate()) {
                            _iniciarSesion();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        child: Text(
                          "Autenticar",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => crearusuario()),
                          );
                        },
                        child: Text(
                          "¿No tienes una cuenta? Regístrate aquí",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
        ),
      ),

    );
  }
}
