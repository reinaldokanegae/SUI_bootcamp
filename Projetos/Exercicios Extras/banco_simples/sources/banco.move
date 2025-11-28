module banco_simples::banco {                       // Módulo principal do banco
    use sui::object::{Self, UID};                   // UID = identificador único do objeto
    use sui::transfer;                              // Para transferir objetos (ex: a conta)
    use sui::tx_context::{Self, TxContext};         // Informações da transação atual
    use sui::event;                                 // Para emitir eventos (visíveis no explorer)
    use banco_simples::usuario::{Self, Usuario};    // Importa o módulo usuário do mesmo pacote

    // =====================
    // Códigos de erro
    // =====================
    const E_SALDO_INSUFICIENTE: u64 = 1;            // Erro quando tenta sacar mais do que tem
    const E_VALOR_INVALIDO: u64 = 2;                // Erro quando valor ≤ 0

    // =====================
    // Eventos (aparecem no Sui Explorer!)
    // =====================
    public struct ContaCriada has copy, drop {      // Evento emitido ao criar conta
        dono: address,                              // Endereço do dono
        nome: std::string::String,                  // Nome escolhido
    }

    public struct Deposito has copy, drop {         // Evento de depósito
        valor: u64,
        para: address,
    }

    public struct Saque has copy, drop {            // Evento de saque
        valor: u64,
        de: address,
    }

    public struct Transferencia has copy, drop {    // Evento de transferência entre contas
        valor: u64,
        de: address,
        para: address,
    }

    // =====================
    // Objeto Conta (o "banco" de cada pessoa)
    // =====================
    public struct Conta has key {                   // "key" = é um objeto global na blockchain
        id: UID,                                    // ← Obrigatório no Sui! Todo objeto tem um ID único
        saldo: u64,                                 // Saldo em unidades (ex: 1000)
        usuario: Usuario,                           // Dados do dono (nome)
    }

    // =====================
    // Funções públicas
    // =====================

    // Cria uma nova conta e retorna ela (não transfere ainda)
    public fun criar_conta(nome: vector<u8>, ctx: &mut TxContext): Conta {
        let sender = tx_context::sender(ctx);       // Pega o endereço de quem chamou
        let conta = Conta {
            id: object::new(ctx),                   // Gera um ID único
            saldo: 0,
            usuario: usuario::novo(nome),           // Cria o usuário com o nome dado
        };

        // Emite evento visível no explorer
        event::emit(ContaCriada {
            dono: sender,
            nome: usuario::nome(&conta.usuario),
        });

        conta                                           // Retorna a conta criada
    }

    // Deposita dinheiro na própria conta
    public fun depositar(conta: &mut Conta, valor: u64, ctx: &TxContext) {
        assert!(valor > 0, E_VALOR_INVALIDO);       // Valor tem que ser positivo
        conta.saldo = conta.saldo + valor;          // Aumenta o saldo

        event::emit(Deposito {
            valor,
            para: tx_context::sender(ctx),         // Quem depositou = dono da conta
        });
    }

    // Saca dinheiro da própria conta
    public fun sacar(conta: &mut Conta, valor: u64, ctx: &TxContext) {
        assert!(valor > 0, E_VALOR_INVALIDO);
        assert!(conta.saldo >= valor, E_SALDO_INSUFICIENTE); // Verifica saldo

        conta.saldo = conta.saldo - valor;

        event::emit(Saque {
            valor,
            de: tx_context::sender(ctx),
        });
    }

    // Transfere de uma conta para outra
    public fun transferir(de: &mut Conta, para: &mut Conta, valor: u64, _ctx: &TxContext) {
        assert!(valor > 0, E_VALOR_INVALIDO);
        assert!(de.saldo >= valor, E_SALDO_INSUFICIENTE);

        de.saldo = de.saldo - valor;
        para.saldo = para.saldo + valor;

        event::emit(Transferencia {
            valor,
            de: object::uid_to_address(&de.id),     // Converte ID do objeto → endereço
            para: object::uid_to_address(&para.id),
        });
    }

    // =====================
    // Funções de leitura (views)
    // =====================
    public fun saldo(conta: &Conta): u64 {          // Lê o saldo sem mutar
        conta.saldo
    }

    public fun nome(conta: &Conta): std::string::String {
        usuario::nome(&conta.usuario)
    }
}