// sources/capybara.move
module capybara_memecoin::capybara {
    // Importa tudo que precisamos do framework Sui
    use sui::coin::{Self, Coin, TreasuryCap};     // Coin = tipo do token, TreasuryCap = controle de mint
    use sui::transfer;                            // Para transferir e congelar objetos
    use sui::tx_context::{Self, TxContext};       // Informações da transação (quem está publicando, etc.)

    // === WITNESS DO TOKEN (obrigatório) ===
    // Tem que ser public na edition 2024+
    public struct CAPYBARA has drop {}

    // === FUNÇÃO EXECUTADA UMA ÚNICA VEZ NO PUBLISH ===
    fun init(witness: CAPYBARA, ctx: &mut TxContext) {
        // Cria o token CAPYBARA
        // treasury_cap → objeto que permite mintar
        // metadata     → nome, símbolo, decimals, etc.
        // <<< AQUI O "mut" É OBRIGATÓRIO para poder usar &mut depois >>>
        let (mut treasury_cap, metadata) = coin::create_currency<CAPYBARA>(
            witness,            // tipo único do token
            9,                  // casas decimais (9 = padrão meme/ERC-20)
            b"CAPY",            // símbolo (ticker)
            b"Capybara Coin",   // nome completo
            b"Clean fair launch • 95% LP • TreasuryCap burned", // descrição
            option::none(),     // ícone (pode colocar URL depois se quiser)
            ctx                 // contexto da transação
        );

        // Congela os metadados para sempre (obrigatório para DEXs aceitarem)
        transfer::public_freeze_object(metadata);

        // === SUPPLY TOTAL ===
        // 1 bilhão de CAPY com 9 casas decimais
        let total_supply: u64 = 1_000_000_000_000_000_000; // 1_000_000_000 * 1_000_000_000

        // === DISTRIBUIÇÃO ===
        let liquidity_amount = total_supply * 95 / 100;   // 950 milhões → vai para o pool
        let marketing_amount = total_supply - liquidity_amount; // 50 milhões → fica com você

        // Mint dos 5% de marketing → vai direto pra carteira de quem publicou
        let marketing_coin = coin::mint(&mut treasury_cap, marketing_amount, ctx);
        transfer::public_transfer(marketing_coin, tx_context::sender(ctx));

        // Mint dos 95% de liquidez → você recebe também (depois joga no pool)
        let liquidity_coin = coin::mint(&mut treasury_cap, liquidity_amount, ctx);
        transfer::public_transfer(liquidity_coin, tx_context::sender(ctx));

        // === QUEIMA DEFINITIVA DO TREASURYCAP (supply fixo pra sempre) ===
        // Envia o "poder de mintar" para o endereço morto 0x0
        // Isso é o que a comunidade chama de "TreasuryCap burned / renounced"
        transfer::public_transfer(treasury_cap, @0x0);
    }
}