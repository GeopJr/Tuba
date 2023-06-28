public class Tuba.API.Misskey.Bookmark : Entity, AiChanify {
	public API.Misskey.Note note { get; set; }

	public override Entity to_mastodon () {
        return note.to_mastodon ();
    }
}
