import 'package:flutter/material.dart';
import 'package:gallery_memories/serviciosremotos.dart';
import 'package:file_picker/file_picker.dart';

class eventoIndividual extends StatefulWidget {
  final String nombre, tipoEvento,propietario, idEvento, fechaEvento, horaEvento;
  final bool isMine;
  eventoIndividual({required this.nombre, required this.tipoEvento, required this.idEvento, required this.propietario, required this.isMine, required this.fechaEvento, required this.horaEvento});

  @override
  State<eventoIndividual> createState() => _eventoIndividualState();
}

class _eventoIndividualState extends State<eventoIndividual> {
  void initState() {

  }
  @override
  Widget build(BuildContext context) {
    print("El evento es mio: ${widget.isMine}");
    return Scaffold(
      appBar: AppBar(
        title: Text("EVENTO"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            // Aquí van las fotos
            Container(
              height: 400,
              color: Colors.white54,
              child: FutureBuilder(
                // Obtiene las fotos del evento desde el servicio remoto
                future: Storage.obtenerFotos(widget.idEvento),
                builder: (context, listaRegreso) {
                  if (listaRegreso.hasData) {
                    // Si hay datos disponibles, muestra las fotos en un GridView
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: listaRegreso.data?.items.length,
                      itemBuilder: (context, indice) {
                        final nombreImagen = listaRegreso.data!.items[indice].name;
                        return Padding(
                          padding: EdgeInsets.all(10),
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
                                                child: Opacity(
                                                  opacity: widget.isMine ? 1.0 : 0.0,
                                                  child: IgnorePointer(
                                                    ignoring: !widget.isMine,
                                                    child: IconButton(
                                                      icon: Icon(Icons.delete, color: Colors.white),
                                                      onPressed: () {
                                                        // BORRAR FOTO
                                                      },
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
            var nombre = archivo.name!;
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

  Widget _buildEventInfo(String title, String value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(8),
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
}
