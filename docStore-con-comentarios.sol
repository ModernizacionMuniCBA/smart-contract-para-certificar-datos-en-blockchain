// Declaración de la versión mínima necesaria del compilador de Solidity para compilar este contrato.
pragma solidity ^0.4.13;

// Se declara el contrato Owned
// El contrato Owned básicamente administra el permiso para almacenar información en el contrato docStore,
contract Owned {
    // Se declara una variable pública de tipo 'address' llamada owner. En ella se almacenará el wallet address
    // del propietario (owner) del contrato, quien es el que tendrá acceso para escribir en el contrato.
    address public owner;

    // Se declara un modificador, onlyOwner. Los modificadores son condiciones que se aplican a las funciones
    // para que éstas se ejecuten sólo si se cumple con la condición del modificador.
    modifier onlyOwner() {

        // Se utiliza la funcion require(), que a su vez llama a la función isOwner pasándole el parámetro msg.sender.
        // msg.sender es una variable propia del lenguaje Solidity que contiene el wallet address de quien inició la transacción.
        // En este caso, este modificador requiere que el que envía la transacción sea el owner. Si no es así, el require
        // directamente finalizará la ejecución del código.
        require(isOwner(msg.sender));

        // El caracter _ indica que se ejecutará la función a la cual se le aplicó el modificador (en el caso de que se cumpla
        // la condición del require que tiene arriba)
        _;
    }

    // Se declara la función pública Owned(). La función homónima al contrato se ejecuta automáticamente al finalizar
    // el deploy del contrato en la red de Ethereum.
    function Owned() public {

        // Se utiliza la función homónima al contrato para que, apenas se hace el deploy, el msg.sender (es decir, la wallet address
        // que inició la transacción del deploy) pasa a ser el owner del contrato. Esto se logra asignando el valor de msg.sender
        // a la variable owner que se declaró al principio del contrato.
        owner = msg.sender;
    }

    // Se declara la función pública de sólo lectura isOwner(), que recibe un parámetro de tipo address llamado addr, y que devuelve un
    // valor de tipo bool como resultado. A través de esta función, es posible consultar si un wallet address específico es el owner
    // (propietario) del contrato. Esta función es utilizada por el modificador onlyOwner() declarado previamente para permitir almacenar
    // datos en el contrato únicamente al owner del mismo.
    function isOwner(address addr) view public returns(bool) {

        // La función devuelve el resultado de la comparación del wallet address consultado (true = es propietario, false = no es propietario)
        return addr == owner;
    }

    // Se declara la función pública transferOwnership(), que recibe un parámetro de tipo address llamado newOwner. Mediante esta función es
    // posible nombrar como owner (propietario) del contrato a otro wallet Address, que suplanta al actual. Al final de la primera línea,
    // en la declaración de la función, se le aplica el modificador onlyOwner(), para que sólo pueda ejecutar esta función el actual owner
    // del contrato.
    function transferOwnership(address newOwner) public onlyOwner {

        // Si el address del nuevo owner es válido, distinto al address del contrato
        if (newOwner != address(this)) {

            // Se asigna como owner al address ingresado como newOwner
            owner = newOwner;
        }
    }
}

// El contrato docStore es el contrato principal, donde se almacena la información concerniente a cada documento que se ha guardado, y la lógica
// para escribir y leer esa información. En la declaración del contrato se agrega 'is Owned', para que herede el almacenamiento, los modificadores y
// las funciones del contrato Owned, declarado previamente.
contract docStore is Owned {

    // Se declara una variable pública de tipo número entero, llamada indice, que se utilizará como contador de documentos, así como también para
    // asignarle un ID a cada uno.
    uint public indice;

    // Se declaran cuatro mappings. Los mappings son tablas de hash, donde se asocia un tipo de dato como índice (o campo), y otro tipo de dato que es
    // el contenido de ese índice. Dicha asociación sirve para luego realizar las consultas de lectura y escritura. El primer mapping, storeByString,
    // se declara con un índice de tipo string (texto, que se utilizará para buscar por hash/link de IPFS ), en el que se almacenará una variable de
    // tipo Documento.
    mapping(string => Documento) private storeByString;

    // El segundo mapping, storeByTitle, se declara con un índice de tipo bytes32 (se utilizará para buscar por el título del documento), en el que se almacenará
    // una variable de tipo Documento. Se utiliza bytes32 para el índice porque permite utilizar un string de hasta 32 caracteres. El tipo de dato string cuesta
    // más gas, entonces se utiliza únicamente en el caso de trabajar con string de más de 32 caracteres para que el costo de la transacción sea menor.
    mapping(bytes32 => Documento) private storeByTitle;

    // El tercer mapping, storeById, se declara con un índice de tipo número entero (se utilizará para buscar por ID del documento), en el que se
    // almacenará una variable de tipo Documento.
    mapping(uint => Documento) private storeById;

    // El cuarto y último mapping, storeByHash, se declara con un índice de tipo bytes32 (se utilizará para buscar por hash SHA256 del documento),
    // en el que se almacenará una variable de tipo Documento.
    mapping(bytes32 => Documento) private storeByHash;

    // Se declara un struct denominado Documento. Un struct es básicamente una clase, con campos personalizados que permitirán ordenar todos los
    // datos asociados a un mismo documento y guardarlos en los mapping.
    struct Documento {

        // Se declara un campo de tipo string, ipfsLink, que almacenará el hash/url de IPFS donde está almacenado el documento.
        string ipfsLink;

        // Se declara un campo de tipo bytes32, titulo, que almacenará el título del documento, codificado en bytes32.
        bytes32 titulo;

        // Se declara una variable de tipo número entero, timestamp, que almacenará el timestamp del bloque de la transacción que se efectuó al guardar el documento.
        uint timestamp;

        // Se declara una variable de tipo address, walletAddress, que almacenará el wallet address de quien inició y firmó la transacción que se efectuó al guardar el documento.
        address walletAddress;

        // Se declara una variable de tipo bytes32, fileHash, que almacenará el hash SHA256 del documento que se almacenó en IPFS.
        bytes32 fileHash;

        // Se declara una variable de tipo número entero, Id, que almacenará el número de ID del documento.
        uint Id;
    }

    // Se declara la función homónima al contrato, que se ejecutará apenas finalizada la migración a la red de Ethereum, de tipo pública.
    function docStore() public {

        // Se inicializa el índice de ID de documentos en 0.
        indice = 0;
    }

    // Se declara la función externa guardarDocumento, que recibe tres parámetros, incluye el modificador onlyOwner para que sólo el propietario
    // del contrato pueda ejecutarla. Los parámetros que recibe son:
    // - El hash/url de ipfs, de tipo string, denominado _ipfsLink. 
    // - El título del documento, de tipo bytes32, denominado _titulo.
    // - El hash SHA256 del documento, de tipo bytes32, denominado _fileHash.
    function guardarDocumento(string _ipfsLink, bytes32 _titulo, bytes32 _fileHash) onlyOwner external {

        // Se requiere que en el mapping storeByString, en la posición índice _ipfsLink, en el campo titulo, no exista previamente información.
        // De esta forma, se evita sobreescribir un documento por otro con el mismo hash/url de IPFS. El require, de existir información previa,
        // anulará y retrotraerá la ejecución de la función y devolverá los gastos de gas.
        require(storeByString[_ipfsLink].titulo == 0x0);

        // Se requiere que en el mapping storeByTitle, en la posición índice _titulo, en el campo titulo, no exista previamente información.
        // De esta forma, se evita sobreescribir un documento por otro con el mismo título. El require, de existir información previa,
        // anulará y retrotraerá la ejecución de la función y devolverá los gastos de gas.
        require(storeByTitle[_titulo].titulo == 0x0);

        // De pasar los require sin errores, se procede a aumentar en uno el índice para sumar un documento más, y utilizar dicho índice para
        // asignarle un ID único al documento que se está por guardar.
        indice += 1;

        // Se prepara una variable llamada '_documento' en memoria para almacenar un struct de tipo Documento (Documento memory _documento)
        // Se asigna en este espacio de memoria recién dimensionado, un struct de tipo Documento, en el que se cargan los datos:
        // * _ipfsLink = La variable de tipo string recibida como parámetro de la función, representando el hash/url de IPFS del documento.
        // * _titulo = La variable de tipo bytes32 recibida como parámetro de la función, representando el título del documento.
        // * now = una variable de Solidity, es el timestamp del bloque actual donde se almacena la transacción de guardado del documento.
        // * msg.sender = explicado anteriormente, una variable de Solidity, es el wallet address de quien inició  y firmó la transacción actual.
        // * _fileHash = La variable de tipo bytes32 recibida como parámetro de la función, representando el hash SHA256 del documento.
        // * indice = El número de ID actual que se le asigna al documento.
        Documento memory _documento = Documento(_ipfsLink, _titulo, now, msg.sender, _fileHash, indice);

        // A continuación se almacenará el espacio de memoria '_documento', en los cuatro mapping, para asociarlo con distintos índices.
        // Se almacena el espacio de memoria '_documento', en el mapping storeByTitle, en el índice correspondiente al título, ingresado
        // como parámetro de la función en la variable '_titulo'.
        storeByTitle[_titulo] = _documento;

        // Se almacena el espacio de memoria '_documento', en el mapping storeByTitle, en el índice correspondiente al hash/url de IPFS
        // del documento, ingresado como parámetro de la función en la variable _ipfsLink.
        storeByString[_ipfsLink] = _documento;

        // Se almacena el espacio de memoria '_documento', en el mapping storeByTitle, en el índice correspondiente al ID actual del
        // documento, representado en la variable 'indice'.
        storeById[indice] = _documento;

        // Se almacena el espacio de memoria '_documento', en el mapping storeByTitle, en el índice correspondiente al hash SHA256 del
        // documento, ingresado como parámetro de la función en la variable _fileHash.
        // Con esto finaliza la ejecución de la función guardarDocumento().
        storeByHash[_fileHash] = _documento;
    }

    // Las funciones restantes son funciones de consulta, cuyo formato es el mismo y varían únicamente el mapping en el que buscan y el
    // tipo de dato que aceptan como parámetro. Se comenta la primera y se entiende que las restantes utilizan la misma lógica.

    // Se declara la función externa de sólo lectura buscarDocumentoPorQM(), que acepta un parámetro de tipo string, denominado _ipfsLink,
    // y devuelve seis valores, de distintos tipos (string, bytes32, uint, address, bytes32, uint), correspondientes a la información
    // asociada al documento que se está buscando.
    // Esta función permite pasarle al contrato un hash/url de IPFS y que devuelva la información que tenga asociada. Si no se ha guardado
    // ningún documento con ese hash/url de IPFS, el contrato devolverá todos campos vacíos.
    function buscarDocumentoPorQM (string _ipfsLink) view external returns (string, bytes32, uint, address, bytes32, uint){

        // Se prepara una variable llamada '_documento' en memoria para almacenar un struct de tipo Documento (Documento memory _documento)
        // Se asigna en este espacio de memoria recién dimensionado, el contenido del mapping storeByString, en la posición índice correspondiente
        // al hash/url de IPFS ingresado en la función a través de la variable '_ipfsLink'.
        Documento memory _documento = storeByString[_ipfsLink];
        
        // La función devuelve el contenido del documento almacenado previamente en memoria, enviando los distintos campos que contiene.
        return (_documento.ipfsLink, _documento.titulo, _documento.timestamp, _documento.walletAddress, _documento.fileHash, _documento.Id);
    }

    function buscarDocumentoPorTitulo (bytes32 _titulo) view external returns (string, bytes32, uint, address, bytes32, uint){
        Documento memory _documento = storeByTitle[_titulo];
        return (_documento.ipfsLink, _documento.titulo, _documento.timestamp, _documento.walletAddress, _documento.fileHash, _documento.Id);
    }
    
    function buscarDocumentoPorId (uint _index) view external returns (string, bytes32, uint, address, bytes32, uint){
        Documento memory _documento = storeById[_index];
        return (_documento.ipfsLink, _documento.titulo, _documento.timestamp, _documento.walletAddress, _documento.fileHash, _documento.Id);
    }

    function buscarDocumentoPorHash (bytes32 _index) view external returns (string, bytes32, uint, address, bytes32, uint){
        Documento memory _documento = storeByHash[_index];
        return (_documento.ipfsLink, _documento.titulo, _documento.timestamp, _documento.walletAddress, _documento.fileHash, _documento.Id);
    }
    
}
