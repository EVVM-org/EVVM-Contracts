// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    Nota: si implementaremos de esta manera para que pueda implementar la lógica adicional en otro contrato
    debemos usar este abstract como una especie de libreria en el logica adicional asi sabe como se tiene que manejar
    el storage en el contrato base
 */
abstract contract Storage {
    uint256 number;
    address owner;
    bool paused;
    mapping(uint256 => uint256) calc;

    // Solo guardamos una implementación a la vez
    address currentImplementation;

    event ImplementationUpdated(address oldImpl, address newImpl);
    event NumberChanged(uint256 newValue);
}

contract Base is Storage {
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    modifier notPaused() {
        if (paused) {
            revert();
        }
        _;
    }

    function add() external notPaused {
        number += 1;
        emit NumberChanged(number);
    }

    function add_Calc(uint256 id) external notPaused {
        calc[id]++;
    }

    function getNumber() external view returns (uint256) {
        return number;
    }

    function getCalc(uint256 id) external view returns (uint256) {
        return calc[id];
    }

    /// Funciones de proxy //////////////////////////////////////

    // Función simplificada para actualizar implementación
    function upgrade(address _newImpl) external onlyOwner {
        if (_newImpl == currentImplementation)
            revert("Es la misma implementacion");
        if (currentImplementation == address(0))
            revert("Implementacion invalida");

        address oldImpl = currentImplementation;
        currentImplementation = _newImpl;

        emit ImplementationUpdated(oldImpl, _newImpl);
    }

    fallback() external {
        if (currentImplementation == address(0))
            revert("Implementacion invalida");

        /*
        assembly {
            2. Copiamos los datos de la llamada
            calldatacopy(0, 0, calldatasize())
            
            3. Hacemos delegatecall a la implementación
            let result := delegatecall(
                gas(),                                  // Enviamos todo el gas disponible
                sload(currentImplementation.slot),      // Dirección de la implementación
                0,                                      // Inicio de la memoria donde están los datos
                calldatasize(),                         // Tamaño de los datos
                0,                                      // Donde guardaremos la respuesta
                0                                       // Tamaño inicial de la respuesta
            )
            
            4. Copiamos la respuesta
            returndatacopy(0, 0, returndatasize())
            
            5. Manejamos el resultado
            switch result
            case 0 { revert(0, returndatasize()) }     // Si falló, revertimos
            default { return(0, returndatasize()) }     // Si funcionó, retornamos

            ? nota personal:
            ? como es que en yul se puede hacer un switch y NO EN SOLIDITY lcdtm -_-U

        }

        */

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(
                gas(),
                sload(currentImplementation.slot),
                0,
                calldatasize(),
                0,
                0
            )

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}


// Implementación de la lógica adicional

interface ILogic {
    function mul(uint256 x) external;

    function mul_Calc(uint256 id, uint256 x) external;
}

contract LogicV1 is Storage, ILogic {
    modifier notPaused() {
        require(!paused, "El contrato esta pausado");
        _;
    }

    // Implementamos la función multiply
    function mul(uint256 x) external override notPaused {
        require(x > 0, "El multiplicador debe ser mayor a 0");
        number = number * x;
        emit NumberChanged(number);
    }

    // También podemos llamar a add() del contrato base
    /*function add() external notPaused {
        number += 1;
        emit NumberChanged(number);
    }*/

    function mul_Calc(uint256 id, uint256 x) external override notPaused {
        calc[id] = calc[id] * x;
    }
}
