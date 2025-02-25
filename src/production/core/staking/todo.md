# Sistema de Staking y Pago de Yields

## Direcciones Involucradas
1. **Activator**: 
   - Inicialmente: EOA (Externally Owned Account)
   - Futuro: Smart Contract (SC) `Activator.sol`
   - Función: Paga, deposita, transfiere y activa
   - Nota: Implementar controles para el cambio de EOA a SC

2. **Estimator**: 
   - Tipo: Smart Contract (SC) `Estimator.sol`

3. **sMATE**: 
   - Tipo: Smart Contract (SC) `sMATE.sol`

## Procesos

### Llegada del Dinero del Yield
1. `Activator.sol` transfiere tokens al contrato `sMATE.sol`:
   - Usa EVVM
   - No necesita notificar a `sMATE.sol` (a menos que sea necesario)

2. `Activator.sol` ejecuta función en `Estimator.sol`:
   - Avisa que se puede pagar
   - Proporciona:
     - Total de tokens a distribuir
     - Timestamp del corte
     - Promedio de sMATE stakeado
   - Función bloqueada (solo `Activator.sol` puede ejecutar)
   - `Estimator.sol` guarda:
     - Timestamp
     - Datos para cálculos futuros
   - `Estimator.sol` actualiza el contador de épocas

### Usuario Cobra su Yield
1. Usuario llama a `gimmeYiel` en `sMATE.sol` (permissionless)
2. `sMATE.sol` consulta a `Estimator.sol`:
   - Pregunta cuánto puede cobrar la dirección del usuario
3. `Estimator.sol` calcula:
   - Consulta array de staking en `sMATE.sol` para la dirección
   - Verifica timestamp límite
   - Comprueba la época actual en el índice 0 (bytes256)
   - Devuelve a `sMATE.sol`: dirección, dirección del token, cantidad y época
4. `sMATE.sol` procesa el pago:
   - Actualiza el índice 0 (bytes256) con la época actual
   - Transfiere los fondos al usuario

## Manejo de Épocas
- El índice 0 del array de staking usa bytes256 para indicar la época actual
- Comienza desde 0x000000000...03 y aumenta con cada nueva época
- `Estimator.sol` mantiene el contador de la época actual
- Formato del índice 0: 0x000000000...XX, donde XX es el número de época en hexadecimal

## Notas Adicionales
- Sistema mejorable y actualizable
- Posibilidad futura de pagar en diferentes tokens
- Importancia de guardar registros para futuras versiones
- `Estimator.sol` es responsable de incrementar y gestionar el número de época
- Al procesar pagos, se verifica y actualiza la época en el índice 0 del array de staking


# Sistema de Staking y Pago de Yields (raw text)

Para el tema de staking, pago de Yields y demás necesitaremos involucrar 3 addresses:

1) "Activator" address que paga/deposita/transfere y activa, es un EOA y luego será un SC (crearle controles en ese sentido y también el address) * esto debería aplicarse a todo SC/EOA control.
2) "Estimator" SC
3) "sMATE" SC

---------------------------------------------

PROCESOS:

LLEGA EL DINERO DEL YIELD
1) Activator transfiere al contrato sMATE el dinero en el token "address" usando la EVVM, ni le avisa (a menos que lo creas importante por algo).
2) Activator ejecuta la función correspondiente en "Estimator" (sin definir aun) avisándole que ya puede pagar y el total del token "address" a distribuir, el timestamp del corte y cuanto sMATE stakeado de promedio hubo (hagamos que Estimator guarde el timestamp, y estos datos para hacer ese dummie nomás), bloqueada para que solo Activator pueda ejecutarla (configurable según punto 1º anterior).

Nota: como todo es mejorable y upgradeable aquí Estimator puede incluso pagar en diferentes tokens durante diferentes períodos de Yield en un futuro a cuentas que nunca reclamaron, lo importante es tener guardados los registros correspondientes, aunque luego al reemplazar el Estimator en futuras versiones el storage también puede pre-cargarse, ahora enfoquemos en que todos hacen las cosas bien y cobran en cada ronda.


UN USUARIO QUIERE COBRAR
1) Llama a la función gimmeYiel del sMATE, permissionless.
2) sMATE le pregunta a Estimator cuanto tiene para cobrar este "address"?
3) Estimator (no necesita filtrar nada está función) consulta on-chain array de staking para "address" en sMATE, revisa el timestamp límite (corte) y busca que no haya un 0x03 marcando que ya cobró, etc... hace las cuentas y le devuele a sMATE: address, token_address, amount y epoca
4) sMATE marca 0x03 en el array del address (pagado) y le transfiere los fondos.


- index 0 en vez de bytes1 usaremos bytes256 este nos servira para indicar en que epoca va 
- el contador de epocas lo tiene el estimator y se lo devolvera al 
