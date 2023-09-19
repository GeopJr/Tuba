public interface Tuba.Dialogs.Saveable : Gtk.Window {
	protected void construct_saveable (GLib.Settings settings) {
		settings.bind ("window-w", this, "default-width", SettingsBindFlags.DEFAULT);
		settings.bind ("window-h", this, "default-height", SettingsBindFlags.DEFAULT);
	}
}
