public class ExampleApp : Adw.Application {
	public ExampleApp () {
		Object (
			application_id: "dev.geopjr.reproducer",
			flags: ApplicationFlags.DEFAULT_FLAGS
		);
	}
  
	public override void activate () {
		var win = new Adw.ApplicationWindow (this);
		win.set_default_size (1000, 300);

		var provider = new Gtk.CssProvider ();
		provider.load_from_string (".larger{font-size:larger;}");
		Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

		var listbox = new Gtk.ListBox () {
			selection_mode = Gtk.SelectionMode.NONE,
			css_classes = {"background"}
		};

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			css_classes = {"card"},
		};
		content_box.append (new Gtk.Label ("") {
		});

		var stack = new Gtk.Stack ();
		stack.add_child (new Gtk.Label ("and he @SK53 keeps the momentum with the rarely seen combination of Rwanda 🇷🇼 Romania 🇷🇴 #fridaygeotrivia 👏") {
			wrap = true,
			xalign = 0.0f,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			valign = Gtk.Align.START,
			ellipsize = Pango.EllipsizeMode.NONE,
			css_classes = {"larger"}
		});
		content_box.append (stack);
		listbox.append (content_box);
  
		win.content = new Gtk.ScrolledWindow () {
			vexpand = true,
			hscrollbar_policy = Gtk.PolicyType.NEVER,
			child = new Adw.Clamp () {
					child = listbox,
					tightening_threshold = 300,
					maximum_size = 670,
					vexpand = true
			}
		};
		win.present ();
	}
  
	public static int main (string[] args) {
		var app = new ExampleApp ();
		return app.run (args);
	}
}
