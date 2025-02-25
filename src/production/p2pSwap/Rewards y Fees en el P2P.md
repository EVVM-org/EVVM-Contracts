# Rewards y Fees en el P2P

## Rewards para el Fisher

- **Al poner orden**: 100% del MATE generado
- **Al quitar orden**: 100% del MATE generado
- **Al cerrar orden**: 100% del MATE generado + 10% del Fee

## Fees al usar el Servicio

### fillProportionalFee

1. El comprador debe enviar 0.05% más del monto a enviar (multiplicar por 1.0005)
   - Este fee se muestra como "Incentive Fee" en la UI, y el porcentaje solo se muestra al pasar el mouse (inline message)
   - Respeta los decimales del token
   - Ejemplo: Si un usuario vende 10 MATE por 1000 dólares, el comprador debe enviar 1000 + 0.05% (0.5 dólares)
2. Completa el swap y reparte el fee:
   - 50% a quien abrió la orden
   - 40% al servicio P2P
   - 10% al fisher

### fillFixedFee

- Se utiliza para transacciones de montos altos, poniendo un TOPE al fee
- No se usa para swaps de token/ETH a MATE
- Proceso:
  1. Calcula el 0.05% del monto del swap (multiplica por 0.0005)
  2. Consulta al API de Uniswap el equivalente en ETH del fee
  3. Si el fee es mayor a 0.001 ETH, se limita a 0.001 ETH convertido al token
  4. Verifica que el usuario haya enviado un valor >= "costo swap + fee":
     - Si es ETH, debe ser exacto
     - Si es token, debe ser mayor a "costo swap + 90% del fee"
  5. Si se envía más del 100% del fee, se devuelve el excedente al sender
  6. Completa el swap y reparte el fee:
     - 50% a quien abrió la orden
     - 40% al servicio P2P
     - 10% al fisher
- Se muestra como "Incentive Fee" en la UI, con detalles al pasar el mouse
- Usa disperseCA donde aplica

## Otros detalles

- El Fee es editable (con función de 24 horas de anticipación y aprobación)
- Los porcentajes del `fillProportionalFee` son editables (fisher, user y servicio)
- Los montos del `fillFixedFee` también son editables
- Existe una función `withdraw` multi-token para sacar los diferentes tokens, con la seguridad correspondiente de 24 horas
