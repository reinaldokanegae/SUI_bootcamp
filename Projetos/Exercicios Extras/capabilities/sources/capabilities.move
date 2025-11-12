module capabilities::admin {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    // passe VIP
    public struct AdminCap has key {
        id: UID
    }

    // Criar o passe (só uma vez!)
    public fun create_admin_cap(ctx: &mut TxContext): AdminCap {
        let cap = AdminCap {
            id: object::new(ctx)
        };
        cap // retorna o passe
    }

    // Função da Área VIP
    public entry fun funcao_admin(
        _: &AdminCap,           // ← "Mostre o passe!"
        param_exemplo: u64
    ) {
        // AQUI SÓ ENTRA QUEM TEM O CAP!
        // Ex: pausar contrato, mintar, etc.
        assert!(param_exemplo > 0, 1000); // só um exemplo
        // ... lógica secreta ...
    }

    // Revogar o passe (upgrade ou emergência)
    public fun destroy_admin_cap(cap: AdminCap) {
        let AdminCap { id } = cap;
        object::delete(id);
    }
}