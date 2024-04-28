import 'package:gallery_memories/serviciosremotos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class crearusuario extends StatefulWidget {
  const crearusuario({super.key});

  @override
  State<crearusuario> createState() => _crearusuarioState();
}

class _crearusuarioState extends State<crearusuario> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _forKey = GlobalKey<FormState>();
  TextEditingController _emailCont = TextEditingController();
  TextEditingController _contrasenaCont = TextEditingController();
  TextEditingController _username = TextEditingController();
  String email = "";
  String contrasena = "";
  String nombre = "";
  final amigos = [];

  // Función para manejar el registro de usuario
  void _handleSingUp(BuildContext context) async {
    try {
      // Intenta registrar al usuario con el correo y la contraseña proporcionados
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: contrasena,
      );
      User? user = FirebaseAuth.instance.currentUser;
      var usuario = {
        'idUsuario': user?.uid,
        'nombre': nombre,
        'nickname': email.substring(0,2),
        'email': email,
        'amigos':amigos,
      };
      // Llama a la función creaUsuario y espera a que se complete
      String idUsuario = await DB.creaUsuario(usuario);

      // Muestra un SnackBar con el correo del usuario registrado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Usuario registrado con ID: $idUsuario"),
        ),
      );

      // Después de mostrar el SnackBar, navega a la interfaz de inicio de sesión
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => login()),
      );
    } catch (e) {
      // Si hay un error durante el registro, muestra un SnackBar con el mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al registrar usuario: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Servicio Autenticación"),
      ),
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
            padding: EdgeInsets.only(top: 50),
            children: [
              Padding(
                padding: EdgeInsets.all(30),
                child: Form(
                    key: _forKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                  'https://cdn-icons-png.flaticon.com/512/6387/6387969.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Text(
                          "Crear Usuario",
                          style: TextStyle(fontSize: 45, color: Colors.white, fontFamily: 'BebasNeue'),
                        ),
                        SizedBox(height: 10,),
                        TextFormField(
                          controller: _username,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Nombre",
                              floatingLabelBehavior: FloatingLabelBehavior.always
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Ingrese un nombre de usuario";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              nombre = value;
                            });
                          },
                        ),
                        SizedBox(height: 20,),
                        TextFormField(
                          controller: _emailCont,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Email",
                              floatingLabelBehavior: FloatingLabelBehavior.always
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
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _contrasenaCont,
                          keyboardType: TextInputType.text,
                          obscureText: true,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Contraseña",
                              floatingLabelBehavior: FloatingLabelBehavior.always
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
                        SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {
                            // Al presionar el botón, valida el formulario y maneja el registro
                            if (_forKey.currentState!.validate()) {
                              _handleSingUp(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          ),
                          child: Text("Registrar", style: TextStyle(
                              fontSize: 18
                          ),
                          ),
                        )
                      ],
                    )
                ),
              ),
            ],
          )

      ),
    );
  }
}

