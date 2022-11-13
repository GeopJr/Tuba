using Gtk;

public interface Tooth.Dialogs.Saveable : Window {

	protected void construct_saveable (GLib.Settings settings) {
		settings.bind ("window-w", this, "default-width", SettingsBindFlags.DEFAULT);
		settings.bind ("window-h", this, "default-height", SettingsBindFlags.DEFAULT);
	}

}
