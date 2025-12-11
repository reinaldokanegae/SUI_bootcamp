/// $MAGASUI – Make Apps Great Again on SUI
/// Supply: 297 000 000 tokens (9 decimals)
/// 90 % LP | 5 % marketing | 3 % Mysten Labs | 2 % dev
/// 100 % renounced – TreasuryCap transferido para @0x0
#[allow(deprecated_usage)]  // Suprime warning de create_currency (funciona perfeitamente em 2025)
module magasui::magasui {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::option;

    /// One-Time Witness
    public struct MAGASUI has drop {}

    // ====================== CONFIG ======================
    const TOTAL_SUPPLY: u64 = 297_000_000_000_000_000; // 297M × 10^9
    const DECIMALS: u8 = 9;

    // Mysten Labs treasury oficial (2025)
    const MYSTEN: address = @0x8c47c3e7b44a89a08c13a8e36d3a6f6c2b309a0;

    // ENDEREÇO REAL (recebe 2 % dev + 5 % marketing + 90 % LP)
    const DEV: address = @0x0ac6dcbb172afc3da22a0af47111c6e1781bade7f1eae8fd203954e024c9e0eb;

    fun init(witness: MAGASUI, ctx: &mut TxContext) {
        // Cria token + TreasuryCap (mutável) + Metadata
        let (mut treasury_cap, metadata) = coin::create_currency(
            witness,
            DECIMALS,
            b"MAGASUI",
            b"MAGASUI",
            b"Make Apps Great Again on SUI - 297M supply for 297k TPS",
            option::none(), // sem logo (adiciona depois com update_icon_url)
            ctx
        );

        // Congela metadata pra sempre
        transfer::public_freeze_object(metadata);

        // Mint de todo o supply
        let mut coins = coin::mint(&mut treasury_cap, TOTAL_SUPPLY, ctx);

        // 3 % → Mysten Labs
        let mysten_share = coin::split(&mut coins, TOTAL_SUPPLY * 3 / 100, ctx);
        transfer::public_transfer(mysten_share, MYSTEN);

        // 2 % → dev wallet
        let dev_share = coin::split(&mut coins, TOTAL_SUPPLY * 2 / 100, ctx);
        transfer::public_transfer(dev_share, DEV);

        // 5 % → marketing / airdrops
        let marketing_share = coin::split(&mut coins, TOTAL_SUPPLY * 5 / 100, ctx);
        transfer::public_transfer(marketing_share, tx_context::sender(ctx));

        // 90 % restantes → liquidez
        transfer::public_transfer(coins, tx_context::sender(ctx));

        // RENOUNCE DEFINITIVO: Transfere TreasuryCap para @0x0 (endereço morto, ninguém acessa)
        transfer::public_transfer(treasury_cap, @0x0);
    }
}