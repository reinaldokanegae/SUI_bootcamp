#[test_only]
module projetoe1::projetoe1_tests {
    use projetoe1::projetoe1;
    use std::string;

    #[test]
    fun test_criar_cliente() {
        let c = projetoe1::criar_cliente(
            string::utf8(b"Pedro"),
            string::utf8(b"pedro.isao@gmail.com"),
            5511998765432,
            30,
            string::utf8(b"Cliente VIP")
        );

        assert!(projetoe1::ler_name(&c) == string::utf8(b"Pedro"), 1);
        assert!(projetoe1::ler_email(&c) == string::utf8(b"pedro.isao@gmail.com"), 2);
        assert!(projetoe1::ler_fone(&c) == 5511998765432, 3);
        assert!(projetoe1::ler_age(&c) == 30, 4);
        assert!(projetoe1::ler_notes(&c) == string::utf8(b"Cliente VIP"), 5);
    }
}