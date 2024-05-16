import 'package:flutter/material.dart';
import 'package:gallery_memories/inicioApp.dart';
import 'package:gallery_memories/serviciosremotos.dart';
import 'package:file_picker/file_picker.dart';

class eventoIndividual extends StatefulWidget {
  String nombre, tipoEvento,propietario, idEvento, fechaEvento, horaEvento, idUsuarioActual;
  final bool isMine;
  eventoIndividual({required this.nombre, required this.tipoEvento, required this.idEvento, required this.propietario, required this.isMine, required this.fechaEvento, required this.horaEvento, required this.idUsuarioActual});

  @override
  State<eventoIndividual> createState() => _eventoIndividualState();
}

class _eventoIndividualState extends State<eventoIndividual> {
  String bar = "EVENTO";
  String estatusEvento = "";

  void setStatus() async {
    bool? estado = await DB.obtenerEstado(widget.idEvento);

    setState(() {
      if (estado == true) {
        estatusEvento = "CERRAR EVENTO";
      } else {
        estatusEvento = "ABRIR EVENTO";
      }
    });
  }

  void initState() {
    if(widget.isMine){
      bar = "MI EVENTO";
    }else{
      bar = "EVENTO";
    }

    setStatus();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    print("El evento es mio: ${widget.isMine}");
    return Scaffold(
      appBar: AppBar(
        title: Text(bar),
        actions: [
          Opacity(opacity: widget.isMine ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !widget.isMine,
            child: IconButton(
                icon: Icon(Icons.edit),
                onPressed: (){
                  _mostrarFormularioEdicion(context);
                }
            ),
          ),)
        ],
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
            Center(
              child: Opacity(
                  opacity: widget.isMine ? 1.0 : 0.0,
                  child: IgnorePointer(ignoring: !widget.isMine,
                    child: TextButton(
                      onPressed: () {
                        DB.cambiarEstado(widget.idEvento).then((value) {
                          setState(() async {
                            bool? estado = await DB.obtenerEstado(widget.idEvento);
                            if (estado == true) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("EVENTO ABIERTO")));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("EVENTO CERRADO")));
                            }
                            setStatus();
                          });
                        });
                      },
                      child: Text(estatusEvento),
                    ),
                  )
              ),
            ),
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
            //BOTON PARA CERRAR EL EVENTO


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

  void _mostrarFormularioEdicion(BuildContext context) async {
    // Crear controladores para los campos de texto con los valores actuales
    TextEditingController nombreController = TextEditingController(text: widget.nombre);
    TextEditingController tipoEventoController = TextEditingController(text: widget.tipoEvento);
    TextEditingController fechaController = TextEditingController(text: widget.fechaEvento);
    TextEditingController horaController = TextEditingController(text: widget.horaEvento);

    // Mostrar el diálogo de edición
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar evento'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campos de texto para editar los detalles del evento
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(labelText: 'Nombre del evento'),
                ),
                TextField(
                  controller: tipoEventoController,
                  decoration: InputDecoration(labelText: 'Tipo de evento'),
                ),
                TextField(
                  controller: fechaController,
                  decoration: InputDecoration(labelText: "Fecha",),
                  readOnly: true,
                  onTap: () {
                    _selectDate(fechaController);
                  },
                ),
                TextField(
                  controller: horaController,
                  decoration: InputDecoration(labelText: "Hora",),
                  readOnly: true,
                  onTap: () {
                    _selectTime(horaController);
                  },
                ),
              ],
            ),
          ),
          actions: [
            // Botón para guardar los cambios
            TextButton(
              onPressed: () async {
                // Actualizar el evento en la base de datos con los nuevos valores
                await DB.actualizarEvento(widget.idEvento, nombreController.text, tipoEventoController.text, fechaController.text, horaController.text);

                // Recuperar los nuevos datos del evento
                Map<String, dynamic> nuevoEvento = await DB.obtenerDatosEvento(widget.idEvento);

                // Asignar los nuevos valores a las variables de estado
                setState(() {
                  widget.nombre = nuevoEvento['nombre'];
                  widget.tipoEvento = nuevoEvento['tipoEvento'];
                  widget.fechaEvento = nuevoEvento['fechaEvento'];
                  widget.horaEvento = nuevoEvento['horaEvento'];
                });

                // Cerrar el diálogo de edición
                Navigator.of(context).pop();
              },
              child: Text('Guardar'),
            ),
            // Botón para cancelar la edición
            TextButton(
              onPressed: () {
                // Cerrar el diálogo de edición sin guardar los cambios
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Componente para seleccionar fecha en formato DD/Mes/YYYY
  Future<void> _selectDate(TextEditingController controlador) async {
    // Lista de nombres de meses en español
    final List<String> _meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    // Mostrar el selector de fecha
    DateTime? _picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    // Si el usuario selecciona una fecha
    if (_picked != null) {
      // Formatear la fecha seleccionada en formato DD/Mes/YYYY
      String day = _picked.day.toString().padLeft(2, '0'); // Añade un cero al día si es necesario
      String month = _meses[_picked.month - 1]; // Obtiene el nombre del mes
      String year = _picked.year.toString(); // Obtiene el año
      String formattedDate = '$day/$month/$year';

      // Actualizar el estado del controlador de texto con la fecha seleccionada
      setState(() {
        controlador.text = formattedDate;
      });
    }
  }

// Componente para seleccionar hora en formato de 12 horas
  Future<void> _selectTime(TextEditingController controlador) async {
    // Mostrar el selector de hora
    TimeOfDay? _picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(), // Hora inicial es la hora actual
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    // Si el usuario selecciona una hora
    if (_picked != null) {
      // Convertir la hora seleccionada a formato de 12 horas
      String formattedTime = _formatTime(_picked.hour, _picked.minute);

      // Actualizar el estado del controlador de texto con la hora seleccionada
      setState(() {
        controlador.text = formattedTime;
      });
    }
  }

// Función para formatear la hora en formato de 12 horas
  String _formatTime(int hour, int minute) {
    String period = 'AM';
    if (hour >= 12) {
      period = 'PM';
      hour = hour % 12;
    }
    if (hour == 0) {
      hour = 12;
    }
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
