public interface Tuba.Dialogs.Components.Attachable : GLib.Object {
	public signal void scroll (bool end);
	public signal void toast (Adw.Toast toast);
	public signal void push_subpage (Adw.NavigationPage page);
	public signal void pop_subpage ();
	public abstract bool edit_mode { get; set; default = false; }
}
