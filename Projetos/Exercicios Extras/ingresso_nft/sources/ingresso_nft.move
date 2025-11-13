/// Módulo: ingresso_nft::event_ticket
/// Projeto 5 – Ingresso NFT transferível (revenda permitida)
module ingresso_nft::event_ticket {
    use std::string::String;
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::event;

        // 1. O NFT do ingresso
    // key  → objeto que pode existir na blockchain
    // store → permite que ele seja transferido livremente (revenda)
    public struct EventTicket has key, store {
        id: UID,                    // ID único do NFT (nunca muda)
        event_name: String,         // ex: "Rock in Rio 2026"
        event_date: String,         // ex: "05 Set 2026"
        seat: String,               // ex: "Pista Premium - Fila 12"
        ticket_type: String,        // ex: "VIP", "Camarote", "Pista"
        owner: address,             // endereço atual do dono
    }

    // 2. Evento emitido toda vez que o ingresso é transferido
    public struct TicketTransferred has copy, drop {
        ticket_id: address,         // ID do ingresso
        from: address,              // quem vendeu / transferiu
        to: address,                // quem recebeu
        event_name: String,         // nome do evento (pra ficar fácil de ler no explorador)
    }

    // 3. Criar (mint) um novo ingresso
    public fun mint(
        event_name: String,
        event_date: String,
        seat: String,
        ticket_type: String,
        recipient: address,         // quem vai receber o ingresso (comprador)
        ctx: &mut TxContext
    ) {
        // Cria o objeto NFT
        let ticket = EventTicket {
            id: object::new(ctx),
            event_name,
            event_date,
            seat,
            ticket_type,
            owner: recipient,
        };

        // Emite um evento dizendo que foi criado e enviado
        event::emit(TicketTransferred {
            ticket_id: object::id_address(&ticket),
            from: @0x0,             // 0x0 = mint (criação)
            to: recipient,
            event_name,
        });

        // Envia o NFT diretamente para o comprador
        transfer::public_transfer(ticket, recipient);
    }

    // 4. Transferir / Revender o ingresso
    // Qualquer pessoa que tiver o ingresso pode revender para outro endereço
    public fun transfer_ticket(
        mut ticket: EventTicket,    // precisamos mutar o owner
        new_owner: address,
    ) {
        let old_owner = ticket.owner;

        // Atualiza quem é o dono agora
        ticket.owner = new_owner;

        // Emite evento de transferência (ótimo para exploradores e marketplaces)
        event::emit(TicketTransferred {
            ticket_id: object::id_address(&ticket),
            from: old_owner,
            to: new_owner,
            event_name: ticket.event_name,
        });

        // Transfere de fato o NFT para o novo dono
        transfer::public_transfer(ticket, new_owner);
    }

    // 5. Funções auxiliares (leitura)
    public fun get_info(ticket: &EventTicket): (String, String, String, String, address) {
        (
            ticket.event_name,
            ticket.event_date,
            ticket.seat,
            ticket.ticket_type,
            ticket.owner
        )
    }

    public fun is_vip(ticket: &EventTicket): bool {
        ticket.ticket_type == std::string::utf8(b"VIP") ||
        ticket.ticket_type == std::string::utf8(b"VIP Pass") ||
        ticket.ticket_type == std::string::utf8(b"Camarote")
    }
}