module projetoe1::projetoe1 {
    use std::string::{Self, String};

    public struct Cliente has drop {
        name: String,
        email: String,
        fone: u64,
        age: u8,
        notes: String
    }

    public fun criar_cliente(
        name: String,
        email: String,
        fone: u64,
        age: u8,
        notes: String
    ): Cliente {
        Cliente { name, email, fone, age, notes }
    }

    public fun ler_name(cliente: &Cliente): String {
        cliente.name
    }

    public fun ler_email(cliente: &Cliente): String {
        cliente.email
    }

    public fun ler_fone(cliente: &Cliente): u64 {
        cliente.fone
    }

    public fun ler_age(cliente: &Cliente): u8 {
        cliente.age
    }

    public fun ler_notes(cliente: &Cliente): String {
        cliente.notes
    }
}


