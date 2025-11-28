module banco_simples::usuario {                     // Define o módulo "usuario" dentro do pacote
    use std::string::String;                        // Importa o tipo String do padrão Move

    // Estrutura que representa uma pessoa/usuário
    public struct Usuario has store, drop {         // "public" = visível fora do módulo
                                                    // "store" = pode ficar dentro de outros objetos
                                                    // "drop" = pode ser descartada automaticamente
        nome: String,                               // Campo único: o nome do usuário (ex: "Alice")
    }

    // Função para criar um novo usuário a partir de bytes (ex: b"João")
    public fun novo(nome_bytes: vector<u8>): Usuario {
        Usuario { 
            nome: std::string::utf8(nome_bytes)     // Converte vector<u8> → String
        }
    }

    // Função para ler o nome (getter)
    public fun nome(self: &Usuario): String {
        self.nome                                   // Retorna uma cópia do nome
    }
}