public interface Tootle.IAccountHolder : GLib.Object {

	protected abstract InstanceAccount? account { get; set; default = null; }

	protected void account_listener_init () {
		accounts.switched.connect (on_account_changed);
		accounts.changed.connect (on_accounts_changed);
		on_account_changed (accounts.active);
	}
	protected void account_listener_free () {
		accounts.switched.disconnect (on_account_changed);
		accounts.changed.disconnect (on_accounts_changed);
	}

	public virtual void on_account_changed (InstanceAccount? account) {}
	public virtual void on_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {}

}
