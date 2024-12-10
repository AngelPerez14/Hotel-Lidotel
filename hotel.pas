program HotelLidotel;

uses crt, sysutils;

const
  // Definición de la cantidad máxima de habitaciones disponibles para cada tipo
  MaxHabitacionesIndividual = 145;
  MaxHabitacionesAcompanado = 144;
  MaxHabitacionesGrupoFamilia = 144;

  // Costos de las diferentes habitaciones
  CostFamilyRoom = 200;
  CostSencilla = 60;
  CostDoble = 120;
  CostSuite = 300;

type
  // Puntero a un registro de cliente
  ClientePtr = ^Cliente;

  // Definición del tipo de datos Cliente (información de cada huésped)
  Cliente = record
    nombre: string[50];
    apellido: string[50];
    cedula: string[20];
    email: string[50];
    telefono: string[20];
    diasEstadia: integer;
    tipoHabitacion: string[50];
    numeroHabitacion: integer;
    costoTotal: real;
    siguiente: ClientePtr; // Enlaza con el siguiente cliente (lista encadenada)
  end;

var
  // Variables para controlar la opción seleccionada en el menú y tipo de reservación
  opcion: integer;
  tipoReservacion: integer;

  // Listas para cada tipo de cliente: individual, acompañado y grupo/familia
  listaIndividual, listaAcompanado, listaGrupoFamilia: ClientePtr;

  // Arreglos que marcan el estado de las habitaciones (true = ocupada, false = libre)
  habitacionesIndividual: array[1..MaxHabitacionesIndividual] of boolean;
  habitacionesAcompanado: array[1..MaxHabitacionesAcompanado] of boolean;
  habitacionesGrupoFamilia: array[1..MaxHabitacionesGrupoFamilia] of boolean;

procedure InicializarHabitaciones();
var
  i: integer;
begin
  // Inicializa todas las habitaciones como libres (false)
  for i := 1 to MaxHabitacionesIndividual do
    habitacionesIndividual[i] := false;
  for i := 1 to MaxHabitacionesAcompanado do
    habitacionesAcompanado[i] := false;
  for i := 1 to MaxHabitacionesGrupoFamilia do
    habitacionesGrupoFamilia[i] := false;
end;

procedure MostrarMenuPrincipal();
begin
  clrscr;
  textcolor(LightBlue);
  writeln('MENU PRINCIPAL');
  textcolor(LightCyan);
  writeln('1. Nuevo Cliente'); // Opción para registrar un nuevo cliente
  writeln('2. Clientes Registrados'); // Opción para ver todos los clientes registrados
  writeln('3. Buscar Cliente'); // Opción para buscar un cliente por cédula
  writeln('4. Cancelar Reserva'); // Opción para cancelar una reserva
  writeln('5. Salir'); // Opción para salir del programa
  writeln('Seleccione una opcion: ');
  readln(opcion); // Lee la opción seleccionada por el usuario
  clrscr;
end;

procedure MostrarMenuTipoReservacion();
begin
  clrscr;
  textcolor(LightBlue);
  writeln('TIPO DE RESERVACION');
  textcolor(LightCyan);
  writeln('1. Individual'); // Opción para reserva individual
  writeln('2. Acompanado'); // Opción para reserva acompañada
  writeln('3. Grupo/Familia'); // Opción para reserva de grupo o familia
  writeln('4. Volver'); // Opción para volver al menú principal
  readln(tipoReservacion); // Lee la opción de tipo de reservación
  clrscr;
end;

// Función para verificar si una cadena de texto contiene solo letras
function EsSoloLetras(cadena: string): boolean;
var
  i: integer;
begin
  for i := 1 to Length(cadena) do
  begin
    // Si la cadena tiene caracteres que no son letras ni espacios, devuelve false
    if not (cadena[i] in ['A'..'Z', 'a'..'z', ' ']) then
    begin
      EsSoloLetras := false;
      Exit;
    end;
  end;
  EsSoloLetras := true;
end;

// Función para verificar si una cadena de texto contiene solo números
function EsSoloNumeros(cadena: string): boolean;
var
  i: integer;
begin
  for i := 1 to Length(cadena) do
  begin
    // Si la cadena tiene caracteres que no son números, devuelve false
    if not (cadena[i] in ['0'..'9']) then
    begin
      EsSoloNumeros := false;
      Exit;
    end;
  end;
  EsSoloNumeros := true;
end;

// Asigna una habitación disponible a un cliente
procedure AsignarHabitacion(var cliente: Cliente; var habitaciones: array of boolean);
var
  i: integer;
begin
  // Recorre todas las habitaciones buscando una libre
  for i := 1 to Length(habitaciones) do
  begin
    if not habitaciones[i] then
    begin
      habitaciones[i] := true; // Marca la habitación como ocupada
      cliente.numeroHabitacion := i; // Asigna el número de la habitación al cliente
      Exit; // Sale una vez que se asigna la habitación
    end;
  end;
  writeln('No hay habitaciones disponibles.'); // Si no hay habitaciones libres
end;

// Calcula el costo total de la estadía del cliente según el tipo de habitación y los días de estadía
procedure CalcularCostoTotal(var cliente: Cliente);
begin
  case cliente.tipoHabitacion of
    '1': cliente.costoTotal := cliente.diasEstadia * CostFamilyRoom; // Cálculo para FAMILY ROOM
    '2': cliente.costoTotal := cliente.diasEstadia * CostSencilla;  // Cálculo para SENCILLA
    '3': cliente.costoTotal := cliente.diasEstadia * CostDoble;     // Cálculo para DOBLE
    '4': cliente.costoTotal := cliente.diasEstadia * CostSuite;     // Cálculo para SUITE
  else
    cliente.costoTotal := 0; // Si el tipo de habitación no es válido, se asigna un costo de 0
  end;
end;

// Guarda los datos del cliente en un archivo de texto (por tipo de habitación)
procedure GuardarClienteEnArchivo(cliente: Cliente; tipo: string);
var
  archivo: Text;
  nombreArchivo: string;
begin
  nombreArchivo := tipo + '.txt'; // El nombre del archivo depende del tipo de cliente (Acompanado, GrupoFamilia, etc.)
  Assign(archivo, nombreArchivo);
  if FileExists(nombreArchivo) then
    Append(archivo) // Si el archivo ya existe, abrelo para agregar más información
  else
    Rewrite(archivo); // Si el archivo no existe, crea uno nuevo
  writeln(archivo, cliente.nombre, ' ', cliente.apellido, ' ', cliente.cedula, ' ', cliente.email, ' ', cliente.telefono, ' ', cliente.diasEstadia, ' ', cliente.tipoHabitacion, ' ', cliente.numeroHabitacion, ' ', cliente.costoTotal:0:2);
  Close(archivo); // Cierra el archivo después de escribir los datos
end;

// Registra un cliente individualmente en la lista correspondiente
procedure registrarCliente(var lista: ClientePtr; var habitaciones: array of boolean; tipo: string);
var
  nuevo: ClientePtr;
  actual: ClientePtr;
  habitacionValida: boolean;
begin
  new(nuevo); // Crea un nuevo cliente en memoria

  // Valida el nombre del cliente (solo puede contener letras)
  repeat
    writeln('Ingrese nombre: ');
    readln(nuevo^.nombre);
    clrscr;
    if not EsSoloLetras(nuevo^.nombre) then
      writeln('El nombre solo puede contener letras.');
  until EsSoloLetras(nuevo^.nombre);

  // Valida el apellido del cliente (solo puede contener letras)
  repeat
    writeln('Ingrese apellido: ');
    readln(nuevo^.apellido);
    clrscr;
    if not EsSoloLetras(nuevo^.apellido) then
      writeln('El apellido solo puede contener letras.');
  until EsSoloLetras(nuevo^.apellido);

  // Valida la cédula del cliente (solo puede contener números)
  repeat
    writeln('Ingrese cedula: ');
    readln(nuevo^.cedula);
    clrscr;
    if not EsSoloNumeros(nuevo^.cedula) then
      writeln('La cedula solo puede contener numeros.');
  until EsSoloNumeros(nuevo^.cedula);

  writeln('Ingrese email: ');
  readln(nuevo^.email);
  clrscr;

  // Valida el teléfono del cliente (solo puede tener 11 dígitos)
  repeat
    writeln('Ingrese telefono: ');
    readln(nuevo^.telefono);
    clrscr;
    if not EsSoloNumeros(nuevo^.telefono) or (Length(nuevo^.telefono) <> 11) then
      writeln('El telefono solo puede contener 11 numeros.');
  until EsSoloNumeros(nuevo^.telefono) and (Length(nuevo^.telefono) = 11);

  writeln('Ingrese cantidad de dias de estadia: ');
  readln(nuevo^.diasEstadia);
  clrscr;

  // Valida el tipo de habitación seleccionada
  repeat
    writeln('Seleccione la habitacion:');
    writeln('1. FAMILY ROOM');
    writeln('2. SENCILLA');
    writeln('3. DOBLE');
    writeln('4. SUITE');
    readln(nuevo^.tipoHabitacion);
    clrscr;
    habitacionValida := (nuevo^.tipoHabitacion = '1') or 
                        (nuevo^.tipoHabitacion = '2') or 
                        (nuevo^.tipoHabitacion = '3') or 
                        (nuevo^.tipoHabitacion = '4');
    if not habitacionValida then
      writeln('Seleccione un tipo de habitacion valido.');
  until habitacionValida;
  
  nuevo^.siguiente := nil; // Inicia la lista enlazada de clientes

  AsignarHabitacion(nuevo^, habitaciones); // Asigna una habitación al cliente
  
  CalcularCostoTotal(nuevo^); // Calcula el costo total de la estadía

  // Añade el nuevo cliente a la lista correspondiente
  if lista = nil then
    lista := nuevo // Si la lista está vacía, el cliente es el primero
  else
  begin
    actual := lista;
    while actual^.siguiente <> nil do
      actual := actual^.siguiente;
    actual^.siguiente := nuevo; // Agrega el nuevo cliente al final de la lista
  end;

  GuardarClienteEnArchivo(nuevo^, tipo); // Guarda la información del cliente en el archivo correspondiente

  writeln('Cliente registrado exitosamente! Numero de habitacion asignado: ', nuevo^.numeroHabitacion);
  writeln('Costo total de la estadia: $', nuevo^.costoTotal:0:2);
  writeln('Presione Enter para continuar...');
  readln;
  clrscr;
end;

// Registra dos clientes para una reserva acompañada
procedure registrarClienteAcompanado(var lista: ClientePtr; var habitaciones: array of boolean);
begin
  writeln('Registro del primer cliente:');
  registrarCliente(lista, habitaciones, 'Acompanado');
  writeln('Registro del acompanante:');
  registrarCliente(lista, habitaciones, 'Acompanado');
end;

// Registra varios clientes para una reserva de grupo o familia
procedure registrarClienteGrupoFamilia(var lista: ClientePtr; var habitaciones: array of boolean);
var
  numAdultos, numHijos, i: integer;
begin
  writeln('Ingrese la cantidad de adultos: ');
  readln(numAdultos);
  clrscr;
  for i := 1 to numAdultos do
  begin
    writeln('Registro del adulto ', i, ':');
    registrarCliente(lista, habitaciones, 'GrupoFamilia');
  end;

  writeln('Tiene hijos? (s/n)');
  if readkey = 's' then
  begin
    writeln;
    writeln('Ingrese la cantidad de hijos: ');
    readln(numHijos);
    clrscr;
    for i := 1 to numHijos do
    begin
      writeln('Registro del hijo ', i, ':');
      registrarCliente(lista, habitaciones, 'GrupoFamilia');
    end;
  end;
end;

// Muestra los datos de todos los clientes registrados en las listas
procedure mostrarClientes(lista: ClientePtr);
var
  actual: ClientePtr;
begin
  actual := lista;
  while actual <> nil do
  begin
    writeln('Nombre: ', actual^.nombre);
    writeln('Apellido: ', actual^.apellido);
    writeln('Cedula: ', actual^.cedula);
    writeln('Email: ', actual^.email);
    writeln('Telefono: ', actual^.telefono);
    writeln('Dias de estadia: ', actual^.diasEstadia);
    writeln('Tipo de habitacion: ', actual^.tipoHabitacion);
    writeln('Numero de habitacion: ', actual^.numeroHabitacion);
    writeln('Costo total: $', actual^.costoTotal:0:2);
    writeln('----------------------------------');
    actual := actual^.siguiente;
  end;
end;

// Muestra los datos de todos los clientes registrados, organizados por tipo de reserva
procedure mostrarTodosLosClientes();
begin
  clrscr;
  writeln('Clientes Individuales:');
  mostrarClientes(listaIndividual);
  writeln('Clientes Acompanados:');
  mostrarClientes(listaAcompanado);
  writeln('Clientes de Grupo/Familia:');
  mostrarClientes(listaGrupoFamilia);
end;

// Busca a un cliente por su cédula en las listas de clientes
procedure buscarCliente(lista: ClientePtr);
var
  cedulaBuscada: string[20];
  encontrado: boolean;
  actual: ClientePtr;
begin
  encontrado := false;
  writeln('Ingrese la cedula del cliente a buscar: ');
  readln(cedulaBuscada);
  actual := lista;
  while (actual <> nil) and (not encontrado) do
  begin
    if actual^.cedula = cedulaBuscada then
    begin
      writeln('Cliente encontrado:');
      writeln('Nombre: ', actual^.nombre);
      writeln('Apellido: ', actual^.apellido);
      writeln('Cedula: ', actual^.cedula);
      writeln('Email: ', actual^.email);
      writeln('Telefono: ', actual^.telefono);
      writeln('Dias de estadia: ', actual^.diasEstadia);
      writeln('Tipo de habitacion: ', actual^.tipoHabitacion);
      writeln('Numero de habitacion: ', actual^.numeroHabitacion);
      writeln('Costo total: $', actual^.costoTotal:0:2);
      encontrado := true;
    end;
    actual := actual^.siguiente;
  end;
  if not encontrado then
    writeln('Cliente no encontrado.');
  writeln('Presione Enter para continuar...');
  readln;
  clrscr;
end;

// Cancela una reserva de cliente buscando su cédula y liberando la habitación
procedure cancelarReserva(var lista: ClientePtr; var habitaciones: array of boolean);
var
  cedulaBuscada: string[20];
  encontrado: boolean;
  actual, anterior: ClientePtr;
begin
  encontrado := false;
  writeln('Ingrese la cedula del cliente cuya reserva desea cancelar: ');
  readln(cedulaBuscada);
  actual := lista;
  anterior := nil;
  while (actual <> nil) and (not encontrado) do
  begin
    if actual^.cedula = cedulaBuscada then
    begin
      if anterior = nil then
        lista := actual^.siguiente
      else
        anterior^.siguiente := actual^.siguiente;
      habitaciones[actual^.numeroHabitacion] := false; // Libera la habitación
      dispose(actual); // Elimina el cliente de la memoria
      writeln('Reserva cancelada exitosamente.');
      encontrado := true;
    end
    else
    begin
      anterior := actual;
      actual := actual^.siguiente;
    end;
  end;
  if not encontrado then
    writeln('Cliente no encontrado.');
  writeln('Presione Enter para continuar...');
  readln;
  clrscr;
end;

begin
  // Inicializa las listas de clientes como vacías
  listaIndividual := nil;
  listaAcompanado := nil;
  listaGrupoFamilia := nil;

  // Inicializa las habitaciones como libres
  InicializarHabitaciones();

  // Pantalla de bienvenida
  textcolor(White); 
  writeln('Bienvenido al Hotel Lidotel');
  readln;

  // Bucle principal del menú
  repeat
    MostrarMenuPrincipal(); // Muestra el menú principal
    case opcion of
      1: begin
           repeat
             MostrarMenuTipoReservacion(); // Muestra el menú para seleccionar tipo de reservación
             case tipoReservacion of
               1: begin
                    registrarCliente(listaIndividual, habitacionesIndividual, 'Individual'); // Registro de cliente individual
                    Break;
                  end;
               2: begin
                    registrarClienteAcompanado(listaAcompanado, habitacionesAcompanado); // Registro de cliente acompañado
                    Break;
                  end;
               3: begin
                    registrarClienteGrupoFamilia(listaGrupoFamilia, habitacionesGrupoFamilia); // Registro de grupo/familia
                    Break;
                  end;
             end;
           until tipoReservacion = 4;
         end;
      2: begin
           mostrarTodosLosClientes(); // Muestra todos los clientes registrados
           writeln('Presione Enter para volver al menu principal...');
           readln;
           clrscr;
         end;
      3: begin
           repeat
             writeln('Seleccione la lista de clientes:');
             writeln('1. Individual');
             writeln('2. Acompanado');
             writeln('3. Grupo/Familia');
             writeln('4. Volver');
             readln(tipoReservacion);
             clrscr;
             case tipoReservacion of
  1: buscarCliente(listaIndividual); // Buscar un cliente en la lista de individuales
  2: buscarCliente(listaAcompanado); // Buscar un cliente en la lista de acompañados
  3: buscarCliente(listaGrupoFamilia); // Buscar un cliente en la lista de grupo/familia
end;
until tipoReservacion = 4;
end;
4: begin
  repeat
    writeln('Seleccione la lista de clientes:');
    writeln('1. Individual');
    writeln('2. Acompanado');
    writeln('3. Grupo/Familia');
    writeln('4. Volver');
    readln(tipoReservacion);
    clrscr;
    case tipoReservacion of
      1: cancelarReserva(listaIndividual, habitacionesIndividual); // Cancelar reserva de individual
      2: cancelarReserva(listaAcompanado, habitacionesAcompanado); // Cancelar reserva de acompañado
      3: cancelarReserva(listaGrupoFamilia, habitacionesGrupoFamilia); // Cancelar reserva de grupo/familia
    end;
  until tipoReservacion = 4;
end;
5: begin
  writeln('Gracias por visitar el Hotel Lidotel. Esperamos verlo pronto!');
  writeln('Presione Enter para salir...');
  readln;
end;
end;
until opcion = 5;
// El programa termina cuando se selecciona la opcion 5 (Salir)
end.
