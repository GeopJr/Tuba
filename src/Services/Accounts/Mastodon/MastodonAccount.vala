public class Tootle.Mastodon.Account : InstanceAccount {

	public const string BACKEND = "Mastodon";

	class Test : AccountStore.BackendTest {

		public override string? get_backend (Json.Object obj) {
			return BACKEND; // Always treat instances as compatible with Mastodon
		}

	}

	public static void register (AccountStore store) {
		store.backend_tests.add (new Test ());
		store.create_for_backend[BACKEND].connect ((node) => {
			var account = Entity.from_json (typeof (Account), node) as Account;
			account.backend = BACKEND;
			return account;
		});
	}

}
