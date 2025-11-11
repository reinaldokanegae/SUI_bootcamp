module eventos::conta {
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;

    public struct Conta has key {
        id: UID,
        saldo: u64,
    }

    public struct EventoCriacao has copy, drop {
        id: ID,
    }

    public struct EventoDeposito has copy, drop {
        conta_id: ID,
        valor: u64,
        novo_saldo: u64,
    }

    // Cria uma nova conta e emite evento
    public entry fun criar_conta(ctx: &mut TxContext) {
        let conta = Conta {
            id: object::new(ctx),
            saldo: 0,
        };

        let conta_id = object::id(&conta);

        event::emit(EventoCriacao { id: conta_id });

        transfer::transfer(conta, tx_context::sender(ctx));
    }

    // Deposita valor e emite evento
    public entry fun depositar(conta: &mut Conta, valor: u64) {
        let conta_id = object::id(conta);
        let novo_saldo = conta.saldo + valor;
        conta.saldo = novo_saldo;

        event::emit(EventoDeposito {
            conta_id,
            valor,
            novo_saldo,
        });
    }
}