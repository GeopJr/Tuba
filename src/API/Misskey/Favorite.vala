public class Tuba.API.Misskey.Favorite : Entity, Widgetizable, AiChanify {
	public string kind { get; set; }
	public API.Misskey.Note note { get; set; }

	public override Entity to_mastodon () {
        return note.to_mastodon ();
    }

    public override Gtk.Widget to_widget () {
		return to_mastodon ().to_widget ();
	}
}
