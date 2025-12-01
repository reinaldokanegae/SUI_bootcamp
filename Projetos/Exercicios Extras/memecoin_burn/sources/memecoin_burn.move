module capyburn_memecoin::capyburn {
    use sui::coin::{Self, Coin}; // Importa módulo Coin para criar/mintar/split/transferir tokens
    use sui::transfer; // Transferências genéricas de objetos
    use sui::tx_context::{Self, TxContext}; // Contexto da transação — usado para criar objetos e acessar sender
    use sui::balance::{Self, Balance}; // Manipulação do tipo Balance<T>
    use sui::table::{Self, Table}; // Estrutura de chave-valor persistente
    use sui::event; // Emissão de eventos on-chain
    use sui::object; // Criação de IDs únicos
    use std::option; // Option<T>

    // ==================== TOKEN ====================
    public struct CAPYBURN has drop {}  // Tipo do token — vazio, serve apenas como marker

    // ==================== CONFIGURAÇÃO DA TAX ====================
    const TOTAL_TAX_BPS: u64 = 200;     // 2.00% total
    const BPS: u64 = 10_000;

    // ==================== POTE DE REFLECTION (objeto compartilhado) ====================
    // Snapshot precisa da ability `store` para ser valor em Table<V>.
    public struct Snapshot has copy, drop, store {  // Valores armazenados na tabela de snapshots
        amount: u128,                               // Saldo registrado na última rodada  
        round: u64                                  // A rodada correspondente ao snapshot
    }

    public struct ReflectionPot has key {  // Objeto global no qual todos interagem
        id: UID,                           // ID único do objeto
        admin: address,                    // somente admin pode iniciar rounds e setar snapshots
        balance: Balance<CAPYBURN>,        // tokens acumulados (u64 internamente)
        total_supply_snapshot: u128,       // supply que conta pro cálculo (usa u128)
        current_round: u64,                // rodada atual
        claimed: Table<address, u64>,      // map address -> last_round_claimed
        snapshots: Table<address, Snapshot> // map address -> Snapshot { amount, round }
    }

    // ==================== EVENTOS ====================
    #[ext(event)]                                      
    public struct ReflectionClaimed has copy, drop {
        user: address,
        amount: u64,
        round: u64
    }

    #[ext(event)]
    public struct RoundStarted has copy, drop {
        admin: address,
        round: u64,
        snapshot_total_supply: u128
    }

    #[ext(event)]
    public struct SnapshotSet has copy, drop {
        admin: address,
        user: address,
        amount: u128,
        round: u64
    }

    #[ext(event)]
    public struct TaxCollected has copy, drop {
        from: address,
        amount: u64
    }

    #[ext(event)]
    public struct Burned has copy, drop {
        by: address,
        amount: u64
    }

    // ==================== PUBLISH (roda só 1 vez) ====================
    fun init(witness: CAPYBURN, ctx: &mut TxContext) {
        let deployer = tx_context::sender(ctx);

        let (mut treasury_cap, metadata) = coin::create_currency<CAPYBURN>(
            witness,
            9,
            b"CAPYBURN",
            b"Capyburn",
            b"2% tax → 1% auto-burn + 1% reflection (claim) • Deflationary capybara on Sui",
            option::none(),
            ctx
        );

        transfer::public_freeze_object(metadata);

        // Supply total: 1_000_000_000_000_000_000 (1e18)
        let total_supply: u128 = 1_000_000_000_000_000_000u128;
        let liquidity_amount = (total_supply * 95u128) / 100u128;   // 95%
        let marketing_initial = total_supply - liquidity_amount; // 5%

        // 5% inicial pra deployer (marketing, airdrops, CEX)
        let marketing_coin = coin::mint(&mut treasury_cap, marketing_initial as u64, ctx);
        transfer::public_transfer(marketing_coin, deployer);

        // 95% pra liquidez
        let liquidity_coin = coin::mint(&mut treasury_cap, liquidity_amount as u64, ctx);
        transfer::public_transfer(liquidity_coin, deployer);

        // Transferimos o treasury_cap pro deployer
        transfer::public_transfer(treasury_cap, deployer);

        // Cria o pote de reflection vazio
        let pot = ReflectionPot {
            id: object::new(ctx),
            admin: deployer,
            balance: balance::zero(),
            total_supply_snapshot: total_supply,
            current_round: 1,
            claimed: table::new(ctx),
            snapshots: table::new(ctx)
        };

        transfer::share_object(pot);
    }

    // ==================== TRANSFERÊNCIA COM TAX + REFLECTION ====================
    // O comportamento: tax = amount * TOTAL_TAX_BPS / BPS
    // burn = floor(tax/2); reflect = tax - burn (tratamento do resto garante soma = tax)
    public fun transfer(
        mut coin: Coin<CAPYBURN>,
        recipient: address,
        pot: &mut ReflectionPot,
        ctx: &mut TxContext
    ) {
        let from = tx_context::sender(ctx);
        let amount = coin::value(&coin);
        if (amount == 0) {
            transfer::public_transfer(coin, recipient);
            return;
        };

        let tax = (amount * TOTAL_TAX_BPS) / BPS; // u64 aritmética
        let send_amount = amount - tax;

        // burn: enviar para 0x0 (garante compatibilidade com várias versões da SDK)
        let burn_amount = tax / 2;
        if (burn_amount > 0) {
            let burn_coin = coin::split(&mut coin, burn_amount, ctx);
            transfer::public_transfer(burn_coin, @0x0);
            event::emit(Burned { by: from, amount: burn_amount });
        };

        // reflect
        let reflect_amount = tax - burn_amount; // garante que burn + reflect = tax
        if (reflect_amount > 0) {
            let reflect_coin = coin::split(&mut coin, reflect_amount, ctx);
            let reflect_balance = coin::into_balance(reflect_coin);
            balance::join(&mut pot.balance, reflect_balance);
            event::emit(TaxCollected { from, amount: reflect_amount });
        };

        // resto vai pro destinatário
        if (send_amount > 0) {
            let send_coin = coin::split(&mut coin, send_amount, ctx);
            coin::destroy_zero(coin);
            transfer::public_transfer(send_coin, recipient);
        } else {
            // tudo foi taxado; destruir coin remanescente (deve ser zero)
            coin::destroy_zero(coin);
        };
    }

    // ==================== ADMIN: set snapshot (single) ====================
    // Admin deve prover o saldo snapshot do usuário **para a rodada atual**.
    // Isso evita que holders passem arbitrary balances ao claim.
    public fun admin_set_snapshot(pot: &mut ReflectionPot, user: address, amount: u128, ctx: &mut TxContext) {
        let caller = tx_context::sender(ctx);
        assert!(caller == pot.admin, 1);

        if (table::contains(&pot.snapshots, user)) {
            let _old = table::remove(&mut pot.snapshots, user);
        };
        table::add(&mut pot.snapshots, user, Snapshot { amount, round: pot.current_round });
        event::emit(SnapshotSet { admin: caller, user, amount, round: pot.current_round });
    }

    // ==================== ADMIN: set snapshot (batch) ====================
    public fun admin_batch_set_snapshot(
        pot: &mut ReflectionPot,
        users: vector<address>,
        amounts: vector<u128>,
        ctx: &mut TxContext
    ) {
        let caller = tx_context::sender(ctx);
        assert!(caller == pot.admin, 2);
        let len_u = vector::length(&users);
        let len_a = vector::length(&amounts);
        assert!(len_u == len_a, 3);

        let mut i = 0;
        while (i < len_u) {
            let user = *vector::borrow(&users, i);
            let amt = *vector::borrow(&amounts, i);
            if (table::contains(&pot.snapshots, user)) {
                let _old = table::remove(&mut pot.snapshots, user);
            };
            table::add(&mut pot.snapshots, user, Snapshot { amount: amt, round: pot.current_round });
            event::emit(SnapshotSet { admin: caller, user, amount: amt, round: pot.current_round });
            i = i + 1;
        };
    }

    // ==================== CLAIM DE REFLECTION (1 clique) ====================
    // Usuário recebe reward baseado no snapshot que o admin preencheu PARA A RODADA ATUAL
    public fun claim_reflection(
        pot: &mut ReflectionPot,
        ctx: &mut TxContext
    ) {
        let user = tx_context::sender(ctx);

        // Verifica se já reclamou nesta rodada
        if (table::contains(&pot.claimed, user)) {
            let last = *table::borrow(&pot.claimed, user);
            if (last >= pot.current_round) {
                return;
            };
        };

        // Busca snapshot do usuário
        if (!table::contains(&pot.snapshots, user)) {
            // sem snapshot definido para essa rodada → nada a fazer, apenas marca como tentado
            if (table::contains(&pot.claimed, user)) {
                let _old = table::remove(&mut pot.claimed, user);
            };
            table::add(&mut pot.claimed, user, pot.current_round);
            return;
        };

        let snap_ref = table::borrow(&pot.snapshots, user);
        // exige que a snapshot seja da rodada atual
        if (snap_ref.round != pot.current_round) {
            if (table::contains(&pot.claimed, user)) {
                let _old = table::remove(&mut pot.claimed, user);
            };
            table::add(&mut pot.claimed, user, pot.current_round);
            return;
        };

        let holder_amount: u128 = snap_ref.amount;
        let total_balance_u128: u128 = balance::value(&pot.balance) as u128;

        if (total_balance_u128 == 0u128 || holder_amount == 0u128 || pot.total_supply_snapshot == 0u128) {
            if (table::contains(&pot.claimed, user)) {
                let _old = table::remove(&mut pot.claimed, user);
            };
            table::add(&mut pot.claimed, user, pot.current_round);
            return;
        };

        // cálculo proporcional em 128 bits para prevenir overflow
        let product: u128 = total_balance_u128 * holder_amount;
        let reward_u128: u128 = product / pot.total_supply_snapshot;

        if (reward_u128 == 0u128) {
            if (table::contains(&pot.claimed, user)) {
                let _old = table::remove(&mut pot.claimed, user);
            };
            table::add(&mut pot.claimed, user, pot.current_round);
            return;
        };

        // garantir que reward caiba em u64 para coin::take
        let max_u64_as_u128: u128 = 18446744073709551615u128;
        if (reward_u128 > max_u64_as_u128) { abort 100; };
        let reward = reward_u128 as u64;

        let reward_coin = coin::take(&mut pot.balance, reward, ctx);
        transfer::public_transfer(reward_coin, user);
        event::emit(ReflectionClaimed { user, amount: reward, round: pot.current_round });

        // Marca como já reclamado
        if (table::contains(&pot.claimed, user)) {
            let _old = table::remove(&mut pot.claimed, user);
        };
        table::add(&mut pot.claimed, user, pot.current_round);
    }

    // ==================== DEV/BOT: NOVA RODADA (chama 1x por dia ou a cada X volume)
    // Só admin pode criar nova rodada e atualizar snapshot total supply
    public fun new_round(pot: &mut ReflectionPot, new_total_supply: u128, ctx: &mut TxContext) {
        let caller = tx_context::sender(ctx);
        assert!(caller == pot.admin, 4);
        pot.current_round = pot.current_round + 1;
        pot.total_supply_snapshot = new_total_supply;
        event::emit(RoundStarted { admin: caller, round: pot.current_round, snapshot_total_supply: new_total_supply });
    }

    // ==================== QUEIMAR MANUAL (opcional) ====================
    // Admin-only burn helper (se quiser queimar moedas explicitamente)
    public fun burn(pot: &mut ReflectionPot, mut coin: Coin<CAPYBURN>, ctx: &mut TxContext) {
        let caller = tx_context::sender(ctx);
        assert!(caller == pot.admin, 5);
        let amount = coin::value(&coin);
        if (amount > 0) {
            // usa envio para 0x0 como forma compatível de tornar moedas irrecoveráveis
            transfer::public_transfer(coin, @0x0);
            event::emit(Burned { by: caller, amount });
        } else {
            coin::destroy_zero(coin);
        };
    }

    // ==================== ADMIN: mudar admin ====================
    public fun set_admin(pot: &mut ReflectionPot, new_admin: address, ctx: &mut TxContext) {
        let caller = tx_context::sender(ctx);
        assert!(caller == pot.admin, 6);
        pot.admin = new_admin;
    }
}
