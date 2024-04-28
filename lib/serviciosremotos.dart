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

  static Future agregarInvitado(String id, String uid) async {
    try {
      // Referencia al documento en la colección "eventos"
      var referenciaEvento = await baseremota.collection("eventos").doc(id).get().then((value) {
        if (value.exists) {
          // Verificar si el documento existe antes de acceder a sus datos
          Map<String, dynamic>? mapa = value.data();

          if (mapa != null && mapa.isNotEmpty) {
            List<dynamic> idInvitado = mapa['invitados'] ?? [];
            idInvitado.add(uid);

            baseremota.collection("eventos").doc(id).update({'invitados': idInvitado});
          } else {
            print("El documento está vacío o no contiene datos.");
          }
        } else {
          print("El documento con ID $id no existe.");
        }
      });

      print("Invitado agregado con éxito al evento con ID $id");
    } catch (e) {
      // Manejar el error según sea necesario
      print("Error al agregar invitado: $e");
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

}
