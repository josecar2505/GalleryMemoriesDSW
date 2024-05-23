import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'package:http/http.dart'
    as http; // ? NOE Importa el paquete http para manejar MailJet

var baseremota = FirebaseFirestore.instance;
var carpetaRemota = FirebaseStorage.instance;

class DB {
  static Future<List<String>> recuperarDatos(String uid) async {
    var query = await baseremota
        .collection("usuarios")
        .where('idUsuario', isEqualTo: uid)
        .get();
    List<String> temporal =
        List.filled(2, ''); // Inicializa la lista con dos elementos vacíos.

    query.docs.forEach((element) {
      Map<String, dynamic> mapa = element.data();
      temporal[0] = mapa['nombre'];
      temporal[1] = mapa['nickname'];
    });

    return temporal;
  }

  static Future<String> creaUsuario(Map<String, dynamic> usuario) async {
    String idUsuario = usuario['idUsuario']; // Obtener el ID del usuario

    // Crear una referencia al documento con el ID del usuario
    DocumentReference usuarioRef =
        baseremota.collection("usuarios").doc(idUsuario);

    // Establecer los datos del usuario en el documento con el ID especificado
    await usuarioRef.set(usuario);

    // Devolver el ID del usuario como confirmación
    return idUsuario;
  }

  static Future<void> eliminaUsuario(String uid) async {
    try {
      //1. Borrar todos los eventos creados por el usuario
      var eventosCreados = await baseremota
          .collection('eventos')
          .where('propietario', isEqualTo: uid)
          .get();
      for (var doc in eventosCreados.docs) {
        await baseremota.collection('eventos').doc(doc.id).delete();
      }

      // 2. Borrarse como invitado de todos los eventos en los que se encuentre
      var eventosInvitadoSnapshot =
          await baseremota.collection('eventos').get();
      for (var doc in eventosInvitadoSnapshot.docs) {
        var datosEvento = doc.data() as Map<String, dynamic>;
        List<dynamic> invitados = datosEvento['invitados'] ?? [];
        int datosOriginales = datosEvento['invitados'].length;

        // Remover el mapa del invitado con el idInvitado igual a uid
        print("Antes de eliminar: $invitados");
        invitados.removeWhere((invitado) => invitado['idInvitado'] == uid);
        print("Después de eliminar: $invitados");

        // Actualizar la lista de invitados solo si se hizo una modificación
        if (invitados.length != datosOriginales) {
          await baseremota
              .collection('eventos')
              .doc(doc.id)
              .update({'invitados': invitados});
          print("Actualización realizada en el evento: ${doc.id}");
        }
      }

      //3. Eliminar información del usuario (tabla usuarios)
      await baseremota.collection('usuarios').doc(uid).delete();
    } catch (e) {
      print('Error al eliminar el usuario: $e');
    }
  }

  static Future<void> eliminarEvento(String idEvento) async {
    try {
      await baseremota.collection('eventos').doc(idEvento).delete();
    } catch (e) {
      print("Error al eliminar el evento: $e");
    }
  }

  static creaEvento(Map<String, dynamic> evento) async {
    DocumentReference eventoRef =
        await baseremota.collection("eventos").add(evento);
    return eventoRef.id;
  }

  static Future<List<Map<String, dynamic>>> obtenerEventos(String uid) async {
    List<Map<String, dynamic>> temp = [];
    var query = await baseremota
        .collection("eventos")
        .where('propietario', isEqualTo: uid)
        .get();

    for (var element in query.docs) {
      Map<String, dynamic> dato = element.data();
      dato['id'] = element.id;

      var documentoUsuario = await baseremota
          .collection("usuarios")
          .doc(dato['propietario'])
          .get();
      // Si encuentra la colección del ID del usuario, sustituye el campo 'propietario' por el nombre del usuario
      if (documentoUsuario.exists) {
        var nombrePropietario = documentoUsuario.data()?['nombre'];
        dato['propietario'] = nombrePropietario;
      } else {
        print(
            "No se encontró ningún documento de usuario con el ID ${dato['propietario']}");
      }

      temp.add(dato);
    }

    return temp;
  }

  static Future<List> buscarInvitacion(String idinvitacion) async {
    List temp = [];

    try {
      var documento =
          await baseremota.collection("eventos").doc(idinvitacion).get();

      if (documento.exists) {
        // El documento existe, puedes acceder a sus datos
        var datos = documento.data(); //Datos de la colección "eventos"

        //Obtener ID del propietario
        var idPropietario = datos?['propietario'];

        //Obtener el nombre del usuario con el idPropietario
        var documentoUsuario =
            await baseremota.collection("usuarios").doc(idPropietario).get();

        //Si encuentra la colección del el ID del usuario, sustituye el campo propietario por el nombre del usuario
        if (documentoUsuario.exists) {
          var nombrePropietario = documentoUsuario.data()?['nombre'];
          datos?['propietario'] = nombrePropietario;
        } else {
          print(
              "No se encontró ningún documento de usuario con el ID $idPropietario");
        }
        print("Datos del documento con ID $idinvitacion: $datos");

        temp.add(datos);
      } else {
        // El documento no existe
        print("No se encontró ningún documento con el ID $idinvitacion");
      }
    } catch (e) {
      // Manejar el error según sea necesario
      print("Error al obtener el documento: $e");
    }

    return temp;
  }

  static Future<bool> agregarInvitado(String idEvento, String uid) async {
    try {
      // Referencia al documento en la colección "eventos"
      var eventoSnapshot =
          await baseremota.collection("eventos").doc(idEvento).get();

      if (eventoSnapshot.exists) {
        // Verificar si el documento existe antes de acceder a sus datos
        Map<String, dynamic>? eventoData = eventoSnapshot.data();

        if (eventoData != null) {
          String propietarioEvento = eventoData['propietario'];

          if (propietarioEvento == uid) {
            // Si el usuario es el propietario del evento, no puede registrarse como invitado
            print(
                "Eres el propietario de este evento, no puedes registrarte como invitado.");
            return false;
          }

          List<dynamic> invitados = eventoData['invitados'] ?? [];
          if (!invitados.any((invitado) => invitado['idInvitado'] == uid)) {
            // Si el usuario no está en la lista de invitados, agréguelo
            invitados.add({'idInvitado': uid, 'acceso': true});
            await baseremota
                .collection("eventos")
                .doc(idEvento)
                .update({'invitados': invitados});
            print("Invitado agregado con éxito al evento con ID $idEvento");
            return true;
          } else {
            print(
                "El usuario ya está registrado como invitado en este evento.");
            return false;
          }
        } else {
          print("El documento está vacío o no contiene datos.");
          return false;
        }
      } else {
        print("El documento con ID $idEvento no existe.");
        return false;
      }
    } catch (e) {
      // Manejar el error según sea necesario
      print("Error al agregar invitado: $e");
      return false;
    }
  }

  static Future<void> eliminarInvitado(
      String idEvento, String idInvitado) async {
    try {
      // Obtener el documento actual
      DocumentSnapshot eventoSnapshot =
          await baseremota.collection('eventos').doc(idEvento).get();

      if (eventoSnapshot.exists) {
        // Obtener los datos actuales del evento
        Map<String, dynamic> datosEvento =
            eventoSnapshot.data() as Map<String, dynamic>;

        // Obtener la lista de invitados
        List<dynamic> invitados = datosEvento['invitados'] ?? [];

        // Eliminar el invitado de la lista de invitados
        invitados
            .removeWhere((invitado) => invitado['idInvitado'] == idInvitado);

        // Actualizar el campo 'invitados' en Firestore
        await baseremota
            .collection('eventos')
            .doc(idEvento)
            .update({'invitados': invitados});

        print('Invitado eliminado correctamente.');
      } else {
        print('El evento con ID $idEvento no existe.');
      }
    } catch (error) {
      print('Error al eliminar el invitado: $error');
    }
  }

  static Future<List<Map<String, dynamic>>> misInvitaciones(String uid) async {
    List<Map<String, dynamic>> temp = [];

    try {
      var query = await baseremota
          .collection("eventos")
          .where('invitados',
              arrayContains: {'idInvitado': uid, 'acceso': true})
          .where('estatus', isEqualTo: true)
          .get();

      for (var element in query.docs) {
        Map<String, dynamic> dato = element.data();
        dato['id'] = element.id;
        // Obtener el nombre del propietario del evento
        var propietarioEvento = dato['propietario'];
        var documentoUsuario = await baseremota
            .collection("usuarios")
            .doc(propietarioEvento)
            .get();
        // Si encuentra el documento del usuario, sustituye el campo 'propietario' por el nombre del usuario
        if (documentoUsuario.exists) {
          var nombrePropietario = documentoUsuario.data()?['nombre'];
          dato['propietario'] = nombrePropietario;
        } else {
          print(
              "No se encontró ningún documento de usuario con el ID $propietarioEvento");
        }

        temp.add(dato);
      }

      return temp;
    } catch (e) {
      print('Error al obtener invitaciones del usuario: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> obtenerDatosEvento(
      String idEvento) async {
    try {
      // Obtener el documento del evento desde Firebase usando el ID del evento
      var documentoEvento =
          await baseremota.collection("eventos").doc(idEvento).get();
      if (documentoEvento.exists) {
        // Extraer los datos del documento del evento
        Map<String, dynamic> datosEvento =
            documentoEvento.data() as Map<String, dynamic>;

        // Obtener el nombre del propietario del evento
        var documentoUsuario = await baseremota
            .collection("usuarios")
            .doc(datosEvento['propietario'])
            .get();
        if (documentoUsuario.exists) {
          var nombrePropietario = documentoUsuario.data()?['nombre'];
          datosEvento['propietario'] = nombrePropietario;
        } else {
          print(
              "No se encontró ningún documento de usuario con el ID ${datosEvento['propietario']}");
        }

        // Si es necesario, puedes hacer ajustes adicionales aquí antes de devolver los datos del evento

        return datosEvento;
      } else {
        // El evento no fue encontrado en Firebase
        throw Exception(
            "El evento con el ID $idEvento no fue encontrado en Firebase.");
      }
    } catch (error) {
      // Manejar cualquier error que ocurra durante la obtención de los datos del evento
      throw Exception("Error al obtener los datos del evento: $error");
    }
  }

  static Future cambiarEstado(String id) async {
    try {
      // Referencia al documento en la colección "eventos"
      var referenciaEvento =
          await baseremota.collection("eventos").doc(id).get();

      if (referenciaEvento.exists) {
        // Verificar si el documento existe antes de acceder a sus datos
        Map<String, dynamic>? mapa = referenciaEvento.data();

        if (mapa != null && mapa.isNotEmpty) {
          // Cambiar el valor del campo "estatus" a false
          var valor = !mapa['estatus'];
          baseremota.collection("eventos").doc(id).update({'estatus': valor});
        } else {
          print("El documento está vacío o no contiene datos.");
        }
      } else {
        print("El documento con ID $id no existe.");
      }

      print("Evento cerrado con éxito. Campo 'estatus' cambiado a false.");
    } catch (e) {
      // Manejar el error según sea necesario
      print("Error al cerrar el evento: $e");
    }
  }

  static Future<bool?> obtenerEstado(String id) async {
    try {
      // Referencia al documento en la colección "eventos"
      var referenciaEvento =
          await baseremota.collection("eventos").doc(id).get();

      if (referenciaEvento.exists) {
        // Verificar si el documento existe antes de acceder a sus datos
        Map<String, dynamic>? mapa = referenciaEvento.data();

        if (mapa != null && mapa.isNotEmpty && mapa.containsKey('estatus')) {
          // Obtener el valor actual del campo "estatus"
          var estado = mapa['estatus'];
          return estado;
        } else {
          print(
              "El documento está vacío, no contiene datos o no tiene el campo 'estatus'.");
          return null; // Indica que no se pudo obtener el estado
        }
      } else {
        print("El documento con ID $id no existe.");
        return null; // Indica que no se pudo obtener el estado
      }
    } catch (e) {
      // Manejar el error según sea necesario
      print("Error al obtener el estado del evento: $e");
      return null; // Indica que no se pudo obtener el estado
    }
  }

  static Future<void> actualizarDatosUsuario(
      String uid, String nuevoNombre, String nuevoNickname) async {
    try {
      var query = await baseremota
          .collection("usuarios")
          .where('idUsuario', isEqualTo: uid)
          .get();
      if (query.docs.isNotEmpty) {
        // Obtener el ID del primer documento que cumple con la consulta
        var idDocumento = query.docs.first.id;
        await baseremota.collection("usuarios").doc(idDocumento).update({
          'nombre': nuevoNombre,
          'nickname': nuevoNickname,
        });
        print("No hay al encontrar el documento del usuario $uid");
      } else {
        print("Error al encontrar el documento del usuario $uid");
        return null;
      }
    } catch (e) {
      print("Error al obtener el ID del documento: $e");
      return null;
    }
  }

  static Future<void> actualizarEvento(
      eventoId, String nombre, String tipo, String fecha, String hora) async {
    try {
      var query = await baseremota.collection("eventos").doc(eventoId).get();

      if (query.exists) {
        // Actualizar los datos del evento
        await baseremota.collection("eventos").doc(eventoId).update({
          'nombre': nombre,
          'tipoEvento': tipo,
          'fechaEvento': fecha,
          'horaEvento': hora
        });
        print("Evento actualizado correctamente.");
      } else {
        print("No se encontró ningún evento con el ID $eventoId.");
      }
    } catch (e) {
      print("Error al actualizar el evento: $e");
    }
  }

  static Future<List<dynamic>> obtenerListaInvitados(String idEvento) async {
    try {
      // Obtener la referencia al documento de invitados en Firebase
      DocumentSnapshot<Map<String, dynamic>> invitadosSnapshot =
          await FirebaseFirestore.instance
              .collection('eventos')
              .doc(idEvento)
              .get();

      // Verificar si el documento existe y tiene datos
      if (invitadosSnapshot.exists) {
        // Obtener la lista de invitados del campo 'invitados' en el documento
        List<dynamic> invitadosList = invitadosSnapshot.data()?['invitados'];

        // Crear una lista para almacenar los datos modificados de invitados
        List<Map<String, dynamic>> invitadosConNombre = [];

        // Iterar sobre la lista de invitados
        for (var invitado in invitadosList) {
          String idInvitado = invitado['idInvitado'];
          bool tieneAcceso = invitado['acceso'];

          // Obtener el nombre del usuario correspondiente al idInvitado
          DocumentSnapshot<Map<String, dynamic>> usuarioSnapshot =
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(idInvitado)
                  .get();

          // Verificar si el usuario existe y tiene datos
          if (usuarioSnapshot.exists) {
            // Obtener el nombre del usuario
            String nombreUsuario = usuarioSnapshot.data()?['nombre'];

            // Agregar el nombre del usuario al mapa de invitado
            Map<String, dynamic> invitadoConNombre = {
              'idInvitado': idInvitado,
              'acceso': tieneAcceso,
              'nombre': nombreUsuario,
            };

            // Agregar el mapa de invitado a la lista de invitados con nombre
            invitadosConNombre.add(invitadoConNombre);
          }
        }

        return invitadosConNombre;
      } else {
        // Devolver una lista vacía si el documento no existe
        return [];
      }
    } catch (e) {
      // Manejar el error si ocurre al obtener los datos de Firebase
      print('Error al obtener la lista de invitados: $e');
      return [];
    }
  }

  static Future<void> actualizarAccesoInvitado(
      String idEvento, String idInvitado, bool nuevoAcceso) async {
    try {
      // Obtener la referencia al documento del evento en la base de datos
      var eventoDoc = baseremota.collection('eventos').doc(idEvento);

      // Obtener los datos del documento
      var eventoSnapshot = await eventoDoc.get();

      // Verificar si el documento existe y contiene datos
      if (eventoSnapshot.exists) {
        // Obtener el arreglo de invitados del documento
        List<dynamic> invitadosList = eventoSnapshot.data()?['invitados'];

        // Buscar el invitado por su ID
        for (var invitado in invitadosList) {
          if (invitado['idInvitado'] == idInvitado) {
            // Actualizar el acceso del invitado
            invitado['acceso'] = nuevoAcceso;

            // Guardar los cambios en Firestore
            await eventoDoc.update({'invitados': invitadosList});

            print('Acceso actualizado para el invitado con ID: $idInvitado');
            return;
          }
        }

        // Si no se encontró el invitado
        print('No se encontró el invitado con ID: $idInvitado');
      } else {
        print('El documento del evento no existe');
      }
    } catch (e) {
      // Manejar el error si ocurre al actualizar los datos en la base de datos
      print('Error al actualizar el acceso del invitado: $e');
      throw e;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerComentarios(
      String idEvento, String nombreImagen) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('comentarios')
        .doc(idEvento)
        .collection('imagenes')
        .doc(nombreImagen)
        .collection('comments')
        .get();

    List<Map<String, dynamic>> comentarios = [];

    for (var doc in snapshot.docs) {
      var data = doc.data();
      var usuarioSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(data['usuario'])
          .get();

      if (usuarioSnapshot.exists) {
        var usuarioData = usuarioSnapshot.data();
        data['nombreUsuario'] = usuarioData?['nombre'] ?? 'Usuario desconocido';
      } else {
        data['nombreUsuario'] = 'Usuario desconocido';
      }

      comentarios.add(data);
    }

    return comentarios;
  }

  static Future<void> agregarComentario(String idEvento, String nombreImagen,
      String comentario, String usuario) async {
    await FirebaseFirestore.instance
        .collection('comentarios')
        .doc(idEvento)
        .collection('imagenes')
        .doc(nombreImagen)
        .collection('comments')
        .add({
      'comentario': comentario,
      'usuario': usuario,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ? NOE Método para verificar si un correo electrónico ya está registrado
  static Future<bool> checkEmailExists(String email) async {
    var query = await baseremota
        .collection("usuarios")
        .where('email', isEqualTo: email)
        .get();
    return query.docs.isNotEmpty;
  }
}

class Storage {
  static Future<String?> obtenerPrimeraImagenDeAlbum(
      String nombreCarpeta) async {
    try {
      // Obtén la lista de elementos en la carpeta (imágenes)
      ListResult result = await carpetaRemota.ref(nombreCarpeta).list();

      // Ordena las imágenes por nombre
      result.items.sort((a, b) => a.name.compareTo(b.name));

      // Si hay al menos una imagen, devuelve la URL de la primera
      if (result.items.isNotEmpty) {
        return await result.items.first.getDownloadURL();
      } else {
        // Si no hay imágenes, puedes devolver una URL predeterminada o null
        return null;
      }
    } catch (e) {
      print('Error al obtener la primera imagen del álbum: $e');
      return "Nohay";
    }
  }

  static Future<String?> obtenerFotoPerfil(
      String nombreCarpeta, String nombre) async {
    try {
      // Obtén la referencia del archivo de la imagen
      print("Buscando en $nombreCarpeta/$nombre");
      Reference ref = carpetaRemota.ref('$nombreCarpeta/$nombre.jpg');

      // Obtiene los metadatos del archivo
      final metadata = await ref.getMetadata();

      // Verifica si los metadatos tienen información sobre el archivo
      if (metadata.size != null) {
        // Si el archivo existe, devuelve su URL de descarga
        return await ref.getDownloadURL();
      } else {
        // Si el archivo no existe, devuelve null
        return null;
      }
    } catch (e) {
      // Maneja cualquier error que pueda ocurrir durante la operación
      print('Error al obtener la imagen del álbum: $e');
      return null;
    }
  }

  static Future subirFoto(
      String path, String nombreImagen, String nombreCarpeta) async {
    var file = File(path);

    return await carpetaRemota
        .ref("$nombreCarpeta/$nombreImagen")
        .putFile(file);
  }

  static Future<String?> obtenerURLimagen(
      String nombreCarpeta, String nombre) async {
    try {
      return await carpetaRemota.ref("$nombreCarpeta/$nombre").getDownloadURL();
    } catch (error) {
      print('Error al obtener la URL de descarga de la imagen: $error');
      // Si se produce un error, puedes devolver una URL predeterminada o null según tu caso
      return null;
    }
  }

  static Future<ListResult> obtenerFotos(nombreCarpeta) async {
    String carpeta = nombreCarpeta;
    return await carpetaRemota.ref(carpeta).listAll();
  }

  static Future<void> eliminarImagen(
      String nombreCarpeta, String nombreImagen) async {
    try {
      // Obtener la referencia del archivo a eliminar
      var referenciaArchivo = carpetaRemota.ref("$nombreCarpeta/$nombreImagen");

      // Eliminar el archivo
      await referenciaArchivo.delete();

      print("Imagen eliminada correctamente.");
    } catch (error) {
      print("Error al eliminar la imagen: $error");
      // Puedes manejar el error de acuerdo a tus necesidades
    }
  }
}

// ? NOE Clase para enviar correos electrónicos con MailJet
class MailjetService {
  final String apiKey;
  final String secretKey;

  MailjetService({required this.apiKey, required this.secretKey});

  Future<void> sendEmail({
    required String fromEmail,
    required String fromName,
    required String toEmail,
    required String toName,
    required String subject,
    required String htmlPart,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.mailjet.com/v3.1/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Basic ' + base64Encode(utf8.encode('$apiKey:$secretKey')),
      },
      body: jsonEncode({
        'Messages': [
          {
            'From': {
              'Email': fromEmail,
              'Name': fromName,
            },
            'To': [
              {
                'Email': toEmail,
                'Name': toName,
              }
            ],
            'Subject': subject,
            'HTMLPart': htmlPart,
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      print('Correo enviado correctamente.');
    } else {
      print('Error al enviar el correo: ${response.body}');
    }
  }
}
