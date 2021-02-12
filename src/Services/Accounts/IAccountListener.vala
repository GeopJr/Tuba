[Deprecated]
public interface Tootle.IAccountListener : GLib.Object {

	protected void account_listener_init () {
		accounts.notify["active"].connect (_on_active_acc_update);
		accounts.saved.notify["size"].connect (_on_saved_accs_update);
		on_account_changed (accounts.active);
	}
	protected void account_listener_free () {
		accounts.notify["active"].disconnect (_on_active_acc_update);
		accounts.saved.notify["size"].disconnect (_on_saved_accs_update);
	}

	void _on_active_acc_update (ParamSpec s) {
		on_account_changed (accounts.active);
	}

	void _on_saved_accs_update (ParamSpec s) {
		on_accounts_changed (accounts.saved);
	}

	public virtual void on_account_changed (InstanceAccount? account) {}
	public virtual void on_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {}

}
