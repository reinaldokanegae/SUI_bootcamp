module capabilities_sui::counter {
    // Importa módulos essenciais do framework Sui
    use sui::object::{Self, UID};                    // object::new, UID → para criar objetos únicos
    use sui::transfer;                               // transfer::share_object, transfer::public_transfer
    use sui::tx_context::{Self, TxContext};          // acesso ao contexto da transação (sender, etc.)

    // ============================
    // 1. O recurso principal: o contador compartilhado
    // ============================
    // "has key" = este é um objeto raiz que vive no storage global da blockchain
    public struct Counter has key {
        id: UID,             // ID único gerado pelo Sui (obrigatório em todo objeto com "key")
        value: u64           // O valor do contador que vamos incrementar
    }

    // ============================
    // 2. A capability verdadeira (o que o Projeto 7 deveria ter ensinado!)
    // ============================
    // "has key, store" → pode ser armazenado no storage de qualquer endereço
    //                    e pode ser transferido livremente (delegável + revogável)
    public struct AdminCap has key, store {
        id: UID              // Todo objeto com "key" precisa de um UID (mesmo capabilities!)
    }

    // ============================
    // 3. Função de criação (equivalente ao "inicializar" do Projeto 7)
    // ============================
    public fun create(ctx: &mut TxContext) {
        // Cria o objeto Counter (será compartilhado → qualquer um pode ler/escrever se tiver permissão)
        let counter = Counter {
            id: object::new(ctx),      // Gera um ID fresco e único
            value: 0
        };

        // Cria a capability que controla quem pode incrementar
        let cap = AdminCap {
            id: object::new(ctx)       // Também precisa de ID único
        };

        // === Distribuição dos objetos ===
        // 1. A capability vai para a carteira de quem chamou a função (o criador)
        transfer::public_transfer(cap, tx_context::sender(ctx));
        //    → public_transfer = objeto privado, só o dono pode usar/transferir

        // 2. O contador fica compartilhado (shared object)
        transfer::share_object(counter);
        //    → share_object = qualquer um pode passar como parâmetro em funções
        //      (mas só quem tem AdminCap consegue chamar increment!)
    }

    // ============================
    // 4. Função privilegiada: só quem tem AdminCap pode chamar
    // ============================
    public fun increment(
        counter: &mut Counter,    // Referência mutável ao contador (precisa ser shared)
        _cap: &AdminCap           // A capability é passada como prova de permissão
    ) {
        // O underscore "_" indica: "eu sei que tenho a cap, mas não vou usar os campos dela"
        // O simples fato de a transação fornecer uma referência válida já prova permissão
        counter.value = counter.value + 1;
    }

    // ============================
    // 5. Função pública de leitura (qualquer um pode chamar)
    // ============================
    public fun value(counter: &Counter): u64 {
        // Não precisa de capability → só leitura
        counter.value
    }

}