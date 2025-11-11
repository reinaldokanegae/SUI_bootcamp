module condicional_loop::meu_modulo {
    use std::string::{Self, String};
    use std::vector;

    // Struct com campo 'idade' e habilidade 'drop'
    public struct Pessoa has drop {
        idade: u8
    }

    // Função que verifica se é maior de idade
    public fun eh_maior_idade(pessoa: &Pessoa): bool {
        pessoa.idade >= 18
    }

    // Função que soma as idades
    public fun soma_idades(pessoas: &vector<Pessoa>): u64 {
        let mut soma: u64 = 0;
        let mut i = 0;
        let length = vector::length(pessoas);

        while (i < length) {
            let pessoa = vector::borrow(pessoas, i);
            soma = soma + (pessoa.idade as u64);
            i = i + 1;
        };

        soma
    }
}    