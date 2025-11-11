// tests/todolist_tests.move
#[test_only]
module list::todolist_tests;

use list::todolist::{Self, TodoList};
use sui::test_scenario;
use std::string;

#[test]
fun test_add_and_clear() {
    let sender = @0xA;
    let mut scenario = test_scenario::begin(sender);

    todolist::create_and_transfer(scenario.ctx());
    test_scenario::next_tx(&mut scenario, sender);

    {
        let mut list = test_scenario::take_from_sender<TodoList>(&scenario);
        todolist::add_item(&mut list, string::utf8(b"Estudar Move"));
        assert!(todolist::length(&list) == 1, 0);
        todolist::clear(&mut list);
        assert!(todolist::length(&list) == 0, 1);
        test_scenario::return_to_sender(&scenario, list);
    }

    test_scenario::end(scenario)
}