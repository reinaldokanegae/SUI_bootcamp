/// Módulo completo de exemplo de NFT com Display padrão no Sui
module my_NFT::my_NFT {

    // IMPORTAÇÕES NECESSÁRIAS
    use sui::display;                           // Para criar o Display (como o NFT aparece nas carteiras)
    use sui::package;                           // Para trabalhar com Publisher e One-Time Witness
    use sui::transfer;                          // Para transferir objetos (NFT, Display, Publisher)
    use sui::object::{Self, UID};               // UID = identificador único de cada objeto no Sui
    use sui::tx_context::{Self, TxContext};     // Informações da transação (quem chamou, etc)
    use std::string::{Self, String};            // Tipo String do Move

    // ONE-TIME WITNESS (OBRIGATÓRIO NO SUI)
    // Regra rígida: tem que ter o MESMO NOME do módulo, mas em MAIÚSCULAS
    // Só existe UMA VEZ na vida do pacote → usado para provar que somos os criadores
    public struct MY_NFT has drop {}            // Nome exato: MY_NFT (não pode ser outro!)

    // Estrutura do nosso NFT
    // has key  → pode ser possuído como objeto top-level (aparece na carteira)
    // has store → pode ser colocado dentro de outros objetos (ex: bags, etc)
    public struct MeuNFT has key, store {
        id: UID,                                // ID único gerado pelo Sui
        name: String,                           // Nome do NFT (ex: "Gato Fofo #001")
        description: String,                    // Descrição longa
        url: String,                            // Link da imagem (IPFS, Arweave, HTTPS...)
    }

    // Função chamada AUTOMATICAMENTE quando o pacote é publicado
    // Só roda 1 vez na vida do contrato
    // Aqui criamos e entregamos o Publisher (prova de que somos donos do pacote)
    fun init(otw: MY_NFT, ctx: &mut TxContext) {
        // "Claim" = pegamos o direito de criar Display, Kiosk rules, etc.
        let publisher = package::claim(otw, ctx);
        
        // Enviamos o Publisher para quem publicou o contrato (você!)
        transfer::public_transfer(publisher, tx_context::sender(ctx));
    }

    // Função pública para MINTAR (criar) um novo NFT
    // Qualquer pessoa pode chamar essa função
    entry fun mint(
        name: vector<u8>,          // Nome em bytes (vai ser convertido para String)
        description: vector<u8>,   // Descrição em bytes
        url: vector<u8>,           // URL da imagem em bytes
        ctx: &mut TxContext        // Contexto da transação
    ) {
        // Cria o objeto NFT com os dados fornecidos
        let nft = MeuNFT {
            id: object::new(ctx),                   // Gera um ID único
            name: string::utf8(name),                // Converte bytes → String
            description: string::utf8(description),
            url: string::utf8(url),
        };

        // Transfere o NFT recém-criado para quem chamou a função
        transfer::public_transfer(nft, tx_context::sender(ctx));
    }

    // Função para criar o DISPLAY (só precisa rodar 1 vez depois do publish)
    // Isso faz seu NFT aparecer bonitinho nas carteiras (Sui Wallet, OKX, etc)
    // Precisa do objeto Publisher que você recebeu no deploy
    entry fun create_display(publisher: &package::Publisher, ctx: &mut TxContext) {
        // Cria um novo Display para o tipo MeuNFT
        let mut display = display::new_with_fields<MeuNFT>(
            publisher,       // Prova que somos os criadores (só quem tem Publisher pode fazer isso)

            // CAMPOS que as carteiras vão procurar
            vector[
                string::utf8(b"name"),         // campo padrão para nome
                string::utf8(b"description"),  // campo padrão para descrição
                string::utf8(b"image_url")     // campo PADRÃO para imagem (OBRIGATÓRIO ser "image_url")
            ],

            // VALORES que vão substituir os campos acima
            vector[
                string::utf8(b"{name}"),       // {name} → pega do campo .name do NFT
                string::utf8(b"{description}"),
                string::utf8(b"{url}")         // {url} → vai preencher o image_url
            ],
            ctx
        );

        // Ativa a versão atual do Display (obrigatório)
        display::update_version(&mut display);

        // Transfere o objeto Display para quem chamou (fica na sua carteira)
        transfer::public_transfer(display, tx_context::sender(ctx));
    }
}