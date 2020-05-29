public interface Tootle.IAccountListener : GLib.Object {

	protected void connect_account () {
		accounts.notify["active"].connect (() => on_account_changed (accounts.active));
		accounts.saved.notify["size"].connect (() => on_accounts_changed (accounts.saved));
		on_account_changed (accounts.active);
	}

	public virtual void on_account_changed (InstanceAccount? account) {}
	public virtual void on_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {}

}
