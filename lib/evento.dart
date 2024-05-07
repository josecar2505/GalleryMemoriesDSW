import 'package:flutter/material.dart';
import 'package:gallery_memories/serviciosremotos.dart';
import 'package:file_picker/file_picker.dart';

class eventoIndividual extends StatefulWidget {
  final String nombre, tipoEvento,propietario, idEvento, fechaEvento, horaEvento, idUsuarioActual;
  final bool isMine;
  eventoIndividual({required this.nombre, required this.tipoEvento, required this.idEvento, required this.propietario, required this.isMine, required this.fechaEvento, required this.horaEvento, required this.idUsuarioActual});

  @override
  State<eventoIndividual> createState() => _eventoIndividualState();
}

class _eventoIndividualState extends State<eventoIndividual> {
  String bar = "EVENTO";

  void initState() {
    if(widget.isMine){
      bar = "MI EVENTO";
    }else{
      bar = "EVENTO";
    }
  }
  @override
  Widget build(BuildContext context) {
    print("El evento es mio: ${widget.isMine}");
    return Scaffold(
      appBar: AppBar(
        title: Text(bar),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Nombre del evento
            Center(
              child: Text(
                widget.nombre,
                style: TextStyle(color: Colors.red, fontSize: 40, fontFamily: 'BebasNeue', fontWeight: FontWeight.bold),
              ),
            ),
            //Datos del evento
            _buildEventInfo("Anfitrión", widget.propietario),
            _buildEventInfo("Tipo de evento", widget.tipoEvento),
            _buildEventInfo("Fecha", widget.fechaEvento),
            _buildEventInfo("Hora", widget.horaEvento),
            SizedBox(height: 10,),
            // Aquí van las fotos
            Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.lightBlue[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: FutureBuilder(
                // Obtiene las fotos del evento desde el servicio remoto
                future: Storage.obtenerFotos(widget.idEvento),
                builder: (context, listaRegreso) {
                  if (listaRegreso.hasData) {
                    // Si hay datos disponibles, muestra las fotos en un GridView
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,  //Numero de columnas en la cuadricula
                        crossAxisSpacing: 2.0,
                        mainAxisSpacing: 2.0,
                      ),
                      itemCount: listaRegreso.data?.items.length,  //Numero de elementos en la cuadricula
                      itemBuilder: (context, indice) {
                        final nombreImagen = listaRegreso.data!.items[indice].name;
                        return Padding(
                          padding: EdgeInsets.all(3),
                          child: FutureBuilder(
                            future: Storage.obtenerURLimagen(widget.idEvento, nombreImagen),
                            builder: (context, URL) {
                              if (URL.hasData) {
                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        // Almacenar el contexto en una variable local
                                        BuildContext dialogContext = context;
                                        return Dialog(
                                          child: Stack(
                                            children: [
                                              Image.network(URL.data!, fit: BoxFit.contain),
                                              Positioned(
                                                top: 10,
                                                right: 10,
                                                //Codigo del botón para borrar la foto
                                                child: Opacity(
                                                  opacity: puedoBorrarFoto(nombreImagen, widget.isMine) ? 1.0 : 0.0,
                                                  child: IgnorePointer(
                                                    ignoring: puedoBorrarFoto(nombreImagen, widget.isMine) == false,
                                                    child: IconButton(
                                                      onPressed: () {
                                                        // BORRAR FOTO
                                                        showDialog(
                                                            context: context,
                                                            builder: (context){
                                                              return AlertDialog(
                                                                title: Center(
                                                                  child: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                    children: [
                                                                      Icon(Icons.warning_amber_outlined, color: Colors.red),
                                                                      SizedBox(width: 8),
                                                                      Text("Comprobar eliminación.", style: TextStyle(color: Colors.red)),
                                                                    ],
                                                                  ),
                                                                ),
                                                                content: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Text(
                                                                      "¿Está seguro de eliminar esta foto?",
                                                                      style: TextStyle(fontSize: 16),
                                                                    ),
                                                                  ],
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Storage.eliminarImagen(widget.idEvento, nombreImagen).then((value) {
                                                                        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text("IMAGEN ELIMINADA.")));
                                                                        setState(() {});

                                                                        // Usar la variable dialogContext en lugar de context
                                                                        Navigator.of(dialogContext).pop();
                                                                      });
                                                                    },
                                                                    child: Text("Aceptar"),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      // Usar la variable dialogContext en lugar de context
                                                                      Navigator.of(context).pop();
                                                                    },
                                                                    child: Text("Cancelar"),
                                                                  ),
                                                                ],
                                                              );
                                                            }
                                                        );
                                                      } ,
                                                      icon: Icon(Icons.delete, color: Colors.white54,),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },

                                  child: Container(
                                    child: Image.network(URL.data!, fit: BoxFit.cover),
                                  ),
                                );
                              } else if (URL.hasError) {
                                return Text('Error loading image');
                              } else {
                                return CircularProgressIndicator();
                              }
                            },
                          ),
                        );
                      },
                    );
                  } else if (listaRegreso.hasError) {
                    // Return an error widget if there is an error
                    return Text('Error loading data');
                  } else {
                    // Return a loading indicator while the future is still in progress
                    return CircularProgressIndicator();
                  }
                },
              ),
            ),
            // ...
          ],
        ),
      ),

      //Botón para agregar fotos al album
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final archivosAEnviar = await FilePicker.platform.pickFiles(
              allowMultiple: true,
              type: FileType.custom,
              allowedExtensions: ['png', 'jpg', 'jpeg']
          );

          if (archivosAEnviar == null || archivosAEnviar.files.isEmpty) {
            setState(() {ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ERROR! No se seleccionaron ARCHIVOS")));});
            return;
          }

          for (var archivo in archivosAEnviar.files) {
            var path = archivo.path!;
            var nombre = "${widget.idUsuarioActual}${archivo.name}";
            var nombreCarpeta = widget.idEvento;

            Storage.subirFoto(path, nombre, nombreCarpeta).then((value) {
              setState(() {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("FOTO CARGADA CON ÉXITO!")));
              });
            });
          }
        },
        child: Icon(Icons.add),
      ),

    );
  }

  //Componentes para mostrar datos del evento
  Widget _buildEventInfo(String title, String value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  bool puedoBorrarFoto(String nombre, bool esMiEvento){
    if(nombre.contains(widget.idUsuarioActual) || esMiEvento == true){
      return true;
    }else{
      return false;
    }
  }
}
