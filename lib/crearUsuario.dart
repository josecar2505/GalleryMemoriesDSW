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
  // ? NOE Instancia de la clase MailjetService
  MailjetService mailjetService = MailjetService(
    apiKey: '96c8efbea2b9f5d70d5e845647d4a660',
    secretKey: '2e1f9344aea05570d1318ed82600c347',
  );

  // Función para manejar el registro de usuario
  void _handleSingUp(BuildContext context) async {
    try {
      // ? NOE Verificar si el correo ya existe en la base de datos
      print("Verificando si $email exsite en la BD");
      bool emailExists = await DB.checkEmailExists(email);
      if (emailExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("El correo ya está registrado."),),
        );
        return;
      }

      // Intenta registrar al usuario con el correo y la contraseña proporcionados
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: contrasena,
      );
      User? user = FirebaseAuth.instance.currentUser;
      var usuario = {
        'idUsuario': user?.uid,
        'nombre': nombre,
        'nickname': email.substring(0, 2),
        'email': email,
        'amigos': amigos,
      };
      // Llama a la función creaUsuario y espera a que se complete
      String idUsuario = await DB.creaUsuario(usuario);

      // ? NOE Enviar correo de bienvenida
      await _sendWelcomeEmail(email, nombre);

      // Muestra un SnackBar con el correo del usuario registrado
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Usuario registrado con ID: $idUsuario"),),);

      // Después de mostrar el SnackBar, navega a la interfaz de inicio de sesión
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => login()),
      );
    } catch (e) {
      // Si hay un error durante el registro, muestra un SnackBar con el mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(         content: Text("Error al registrar usuario: $e"),),);
    }
  }

  // ? NOE Función para enviar el correo de bienvenida utilizando Mailjet
  Future<void> _sendWelcomeEmail(String email, String nombre) async {
    await mailjetService.sendEmail(
      fromEmail: 'nofefloresmo@ittepic.edu.mx',
      fromName: 'Gallery Memories Team',
      toEmail: email,
      toName: nombre,
      subject: 'Bienvenido a Gallery Memories',
      htmlPart: """
          <html>
            <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
              <div style="max-width: 600px; margin: auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);">
                <div style="text-align: center;">
                  <img src="https://img.freepik.com/vector-premium/icono-galeria-fotos-vectorial_723554-144.jpg?w=2000" alt="Gallery Memories Logo" style="width: 100px; margin-bottom: 20px;" />
                  <h2 style="color: #333;">Bienvenido a Gallery Memories, $nombre!</h2>
                </div>
                <p style="color: #555;">
                  Estamos muy emocionados de tenerte con nosotros. Gallery Memories es una plataforma donde puedes colaborar con tu familia y amigos para crear álbumes de fotos inolvidables.
                </p>
                <p style="color: #555;">
                  Con Gallery Memories, puedes:
                </p>
                <ul style="color: #555;">
                  <li>Crear y compartir álbumes de fotos</li>
                  <li>Colaborar con tus seres queridos</li>
                  <li>Guardar y revivir tus momentos más preciados</li>
                </ul>
                <p style="color: #555;">
                  Estamos aquí para ayudarte a capturar y compartir tus recuerdos más valiosos.
                </p>
                <div style="text-align: center; margin: 20px 0;">
                  <a href="https://github.com/josecar2505/GalleryMemoriesDSW" style="background-color: #3498db; color: white; padding: 10px 20px; border-radius: 5px; text-decoration: none;">Empezar</a>
                </div>
                <p style="color: #777; text-align: center;">
                  Si tienes alguna pregunta, no dudes en <a href="mailto:support@gallerymemories.com" style="color: #3498db;">contactarnos</a>.
                </p>
                <p style="color: #777; text-align: center;">
                  ¡Gracias por unirte a nosotros!
                </p>
                <p style="color: #777; text-align: center;">
                  Saludos,<br />
                  El equipo de Gallery Memories
                </p>
              </div>
            </body>
          </html>
        """,
    );
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
                          style: TextStyle(
                              fontSize: 45,
                              color: Colors.white,
                              fontFamily: 'BebasNeue'),
                        ),
                        SizedBox(height: 10,),
                        TextFormField(
                          controller: _username,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Nombre",
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always),
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
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always
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
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always),
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
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                          ),
                          child: Text(
                            "Registrar",
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      ],
                    )),
              ),
            ],
          )),
    );
  }
}
