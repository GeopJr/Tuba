public class ExampleApp : Adw.Application {
	public ExampleApp () {
		Object (
			application_id: "dev.geopjr.reproducer",
			flags: ApplicationFlags.DEFAULT_FLAGS
		);
	}
  
	public override void activate () {
		var win = new Adw.ApplicationWindow (this);
		win.set_default_size (650, 367);

		var video = new Gtk.Video () {
			vexpand = true,
			hexpand = true,
			autoplay = true
		};
		win.content = video;
		win.present ();

		// (c) copyright 2008, Blender Foundation / www.bigbuckbunny.org
		File file = File.new_for_uri ("https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v");

		file.read_async.begin (Priority.DEFAULT, null, (obj, res) => {
			try {
				video.set_media_stream (Gtk.MediaFile.for_input_stream (file.read_async.end (res)));
			} catch (Error e) {
				print ("Error: %s\n", e.message);
			}
		});
	}
  
	public static int main (string[] args) {
		var app = new ExampleApp ();
		return app.run (args);
	}
}
