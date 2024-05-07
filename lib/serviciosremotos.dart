import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

var baseremota = FirebaseFirestore.instance;
var carpetaRemota = FirebaseStorage.instance;

class DB{
  static Future<List<String>> recuperarDatos(String uid) async {
    var query = await baseremota.collection("usuarios").where('idUsuario', isEqualTo: uid).get();
    List<String> temporal = List.filled(2, ''); // Inicializa la lista con dos elementos vacíos.

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
    DocumentReference usuarioRef = baseremota.collection("usuarios").doc(idUsuario);

    // Establecer los datos del usuario en el documento con el ID especificado
    await usuarioRef.set(usuario);

    // Devolver el ID del usuario como confirmación
    return idUsuario;
  }

  static creaEvento(Map<String, dynamic> evento) async {
    DocumentReference eventoRef = await baseremota.collection("eventos").add(evento);
    return eventoRef.id;
  }

  static Future<List<Map<String, dynamic>>> obtenerEventos(String uid) async {
    List<Map<String, dynamic>> temp = [];
    var query = await baseremota.collection("eventos").where('propietario', isEqualTo: uid).get();

    for (var element in query.docs) {
      Map<String, dynamic> dato = element.data();
      dato['id'] = element.id;

      var documentoUsuario = await baseremota.collection("usuarios").doc(dato['propietario']).get();
      // Si encuentra la colección del ID del usuario, sustituye el campo 'propietario' por el nombre del usuario
      if (documentoUsuario.exists) {
        var nombrePropietario = documentoUsuario.data()?['nombre'];
        dato['propietario'] = nombrePropietario;
      } else {
        print("No se encontró ningún documento de usuario con el ID ${dato['propietario']}");
      }

      temp.add(dato);
    }

    return temp;
  }

  static Future<List> buscarInvitacion(String idinvitacion) async {
    List temp = [];

    try {
      var documento = await baseremota.collection("eventos").doc(idinvitacion).get();

      if (documento.exists) {
        // El documento existe, puedes acceder a sus datos
        var datos = documento.data();  //Datos de la colección "eventos"

        //Obtener ID del propietario
        var idPropietario = datos?['propietario'];

        //Obtener el nombre del usuario con el idPropietario
        var documentoUsuario = await baseremota.collection("usuarios").doc(idPropietario).get();

        //Si encuentra la colección del el ID del usuario, sustituye el campo propietario por el nombre del usuario
        if(documentoUsuario.exists){
          var nombrePropietario = documentoUsuario.data()?['nombre'];
          datos?['propietario'] = nombrePropietario;
        }else{
          print("No se encontró ningún documento de usuario con el ID $idPropietario");
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
      var eventoSnapshot = await baseremota.collection("eventos").doc(idEvento).get();

      if (eventoSnapshot.exists) {
        // Verificar si el documento existe antes de acceder a sus datos
        Map<String, dynamic>? eventoData = eventoSnapshot.data();

        if (eventoData != null) {
          String propietarioEvento = eventoData['propietario'];

          if (propietarioEvento == uid) {
            // Si el usuario es el propietario del evento, no puede registrarse como invitado
            print("Eres el propietario de este evento, no puedes registrarte como invitado!!!");
            return false;
          }

          List<dynamic> invitados = eventoData['invitados'] ?? [];
          if (!invitados.contains(uid)) {
            // Si el usuario no está en la lista de invitados, agréguelo
            invitados.add(uid);
            await baseremota.collection("eventos").doc(idEvento).update({'invitados': invitados});
            print("Invitado agregado con éxito al evento con ID $idEvento");
            return true;
          } else {
            print("El usuario ya está registrado como invitado en este evento.");
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

  static Future<List<Map<String, dynamic>>> misInvitaciones(String uid) async{
    List<Map<String, dynamic>> temp = [];
    var query = await baseremota.collection("eventos").where('invitados', arrayContains: uid).where('estatus', isEqualTo: true).get();

    for (var element in query.docs) {
      Map<String, dynamic> dato = element.data();
      dato['id'] = element.id;

      // Obtener el nombre del propietario del evento
      var propietarioEvento = dato['propietario'];
      var documentoUsuario = await baseremota.collection("usuarios").doc(propietarioEvento).get();
      // Si encuentra el documento del usuario, sustituye el campo 'propietario' por el nombre del usuario
      if (documentoUsuario.exists) {
        var nombrePropietario = documentoUsuario.data()?['nombre'];
        dato['propietario'] = nombrePropietario;
      } else {
        print("No se encontró ningún documento de usuario con el ID $propietarioEvento");
      }

      temp.add(dato);
    }

    return temp;
  }

  static Future<Map<String, dynamic>> obtenerDatosEvento(String idEvento) async {
    try {
      // Obtener el documento del evento desde Firebase usando el ID del evento
      var documentoEvento = await baseremota.collection("eventos").doc(idEvento).get();
      if (documentoEvento.exists) {
        // Extraer los datos del documento del evento
        Map<String, dynamic> datosEvento = documentoEvento.data() as Map<String, dynamic>;

        // Obtener el nombre del propietario del evento
        var documentoUsuario = await baseremota.collection("usuarios").doc(datosEvento['propietario']).get();
        if (documentoUsuario.exists) {
          var nombrePropietario = documentoUsuario.data()?['nombre'];
          datosEvento['propietario'] = nombrePropietario;
        } else {
          print("No se encontró ningún documento de usuario con el ID ${datosEvento['propietario']}");
        }

        // Si es necesario, puedes hacer ajustes adicionales aquí antes de devolver los datos del evento

        return datosEvento;
      } else {
        // El evento no fue encontrado en Firebase
        throw Exception("El evento con el ID $idEvento no fue encontrado en Firebase.");
      }
    } catch (error) {
      // Manejar cualquier error que ocurra durante la obtención de los datos del evento
      throw Exception("Error al obtener los datos del evento: $error");
    }
  }

}

class Storage {
  static Future<String?> obtenerPrimeraImagenDeAlbum(String nombreCarpeta) async {
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

  static Future subirFoto(String path, String nombreImagen, String nombreCarpeta) async {
    var file = File(path);

    return await carpetaRemota.ref("$nombreCarpeta/$nombreImagen").putFile(file);
  }

  static Future<String> obtenerURLimagen(String nombreCarpeta,String nombre)async{
    return await carpetaRemota.ref("$nombreCarpeta/$nombre").getDownloadURL();
  }

  static Future<ListResult>  obtenerFotos(nombreCarpeta) async{
      String carpeta = nombreCarpeta;
      return await carpetaRemota.ref(carpeta).listAll();
  }

  static Future<void> eliminarImagen(String nombreCarpeta, String nombreImagen) async {
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
