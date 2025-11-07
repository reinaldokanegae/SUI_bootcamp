module list::todolist;

use std::string::String;
use sui::object::{Self, UID};
use sui::transfer;
use sui::tx_context::{Self, TxContext};

/// Estrutura que representa uma lista de tarefas (ToDo List)
public struct TodoList has key, store {
    id: UID,
    items: vector<String>
}

/// Cria uma nova lista de tarefas e transfere para o remetente
public fun new(ctx: &mut TxContext) {
    let list = TodoList {
        id: object::new(ctx),
        items: vector[],
    };

    let sender = tx_context::sender(ctx);
    transfer::transfer(list, sender);
}
