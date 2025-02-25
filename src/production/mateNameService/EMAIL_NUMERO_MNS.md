Agregar al NameService la función generica para agregar email y teléfono.

Los smart contracts solo pueden ser accedidos mediante el MNS (Mate Name Service) 
******************************************************************************************************
# Funcion registerEmail/Phone

1. La función recibe (al menos) estos parametros: 

string: email/telefono
decimal: timestampUser
signature: firma_address_pide(email/telefono-timestampUser)
signature: firmaAutoridad(firma_address_pide-email/telefono-timestampAutoridad)
decimal: timestampAutoridad

2. Extrae el address que solicita (user) de la firma y con eso verifica:
-email/telefono
-timestampUser (ponerle un lapso equivalente a 1 hora para utilizar la autorización)
-Address que pide el email/telefono

3. Extrae el address de la Autoridad que firma y con eso veifica:
-Autoridad firmante (debe coincidir con la whitelisteada).
-Legitimidad del Email para el Addres que lo pide.
-Timestamp vigente (ponerle un lapso equivalente a 1 hora para utilizar la autorización)

4. Si todo sale bien: 
    a) Si no estaba se lo da automáticamente y se ecompenza al fisher con (50 * MATEreward) + priorityFee
    b) si ya estaba se abre una transferWindow (de 24 horas) donde el dueño actual (anterior) puede cancelarla con una función functionReverse, si esto no sucede el nuevo dueño puede hacer el functionClaim con una transacción firmada normal a las 24 horas y se le paga al fisher con (25 * MATEreward) + priorityFee.

# Funcion functionReverse

1. La functionReverse recibe:
string: email/telefono
decimal: timestampUser
signature: firma_address_pide(4bytes-email/telefono-timestampUser)

2. Verifica si el email/telefono esta en transferWindow de ser así la cancela (borra la inicialización), el que lo pedía PIERDE el dinero. Esta transacción no necesita MATE tokens. y se le paga al fisher con (25 * MATEreward) + priorityFee.

# Funcion functionClaim

1. La functionClaim recibe:
string: email/telefono

2. Con eso se verifica el estado y se completa el claim, se reparte el pago pendiente al fisher que lo ejecuta (la mitad del total del pago por traspaso/registro) y se le paga al fisher con (25 * MATEreward) + priorityFee.


******************************************************************************************************
Nota 1: Verificar bien que el % de rewards en estas acciones porque son 2 step (se debe dividir aun mas el reward estandar en 25*MATEreward+priorityFee por cada una de las 2 txs).

Nota 2: Los SC de ambos casos y la Autoridad debe ser editable.

Pensar bien: 
1. Expresiones regulares de validación de email y teléfono.
2. Renovaciones innecesarias, no hay.
3. Metadatos(?), interesante y tiene sentido que haya.
4. No hay ofertas.
******************************************************************************************************