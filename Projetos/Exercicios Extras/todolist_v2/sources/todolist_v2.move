module list::todolist;

use std::string::String;
use std::vector;  // <-- Correto
use sui::object::{Self, UID};
use sui::transfer;
use sui::tx_context::{Self, TxContext};

/// Estrutura que representa uma lista de tarefas
public struct TodoList has key, store {
    id: UID,
    items: vector<String>
}

/// Cria uma nova lista (retorna)
public fun new(ctx: &mut TxContext): TodoList {
    TodoList {
        id: object::new(ctx),
        items: vector::empty<String>(),
    }
}

/// Adiciona um item
public fun add_item(list: &mut TodoList, item: String) {
    list.items.push_back(item);
}

/// Remove item por índice
public fun remove_item(list: &mut TodoList, index: u64) {
    let len = list.items.length();
    assert!(index < len, 1000);
    list.items.remove(index);
}

/// Retorna o tamanho
public fun length(list: &TodoList): u64 {
    list.items.length()
}

/// Pega item por índice
public fun get_item(list: &TodoList, index: u64): &String {
    assert!(index < list.items.length(), 1000);
    list.items.borrow(index)
}

/// Limpa a lista
public fun clear(list: &mut TodoList) {
    list.items = vector::empty<String>();
}

/// Cria e transfere
public fun create_and_transfer(ctx: &mut TxContext) {
    let list = new(ctx);
    transfer::transfer(list, tx_context::sender(ctx));
}