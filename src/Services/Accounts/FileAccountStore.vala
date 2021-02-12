using Gee;

public class Tootle.FileAccountStore : AccountStore {

	string dir_path;
	string file_path;

	construct {
		dir_path = @"$(GLib.Environment.get_user_config_dir ())/$(app.application_id)";
		file_path = @"$dir_path/accounts.json";
	}

	public override void load () throws GLib.Error {
		uint8[] data;
		string etag;
		var file = File.new_for_path (file_path);
		file.load_contents (null, out data, out etag);
		var contents = (string) data;

		var parser = new Json.Parser ();
		parser.load_from_data (contents, -1);
		var array = parser.get_root ().get_array ();

		array.foreach_element ((arr, i, node) => {
			try {
				var account = accounts.create_account (node);
				saved.add (account);
			}
			catch (Error e) {
				warning (@"Couldn't load account $i: $(e.message)");
			}
		});

		message (@"Loaded $(saved.size) accounts");
	}

	public override void save () throws GLib.Error {
		var dir = File.new_for_path (dir_path);
		if (!dir.query_exists ())
			dir.make_directory_with_parents ();

		var file = File.new_for_path (file_path);

		var builder = new Json.Builder ();
		builder.begin_array ();
		saved.foreach ((acc) => {
			var node = acc.to_json ();
			builder.add_value (node);
			return true;
		});
		builder.end_array ();

		var generator = new Json.Generator ();
		generator.set_root (builder.get_root ());
		var data = generator.to_data (null);

		if (file.query_exists ())
			file.@delete ();

		FileOutputStream stream = file.create (FileCreateFlags.PRIVATE);
		stream.write (data.data);

		message (@"Saved $(saved.size) accounts");
	}

}
