public interface Tuba.API.Misskey.AiChanify : GLib.Object, Widgetizable {
	public virtual Entity to_mastodon () throws Oopsie {
		throw new Tuba.Oopsie.INTERNAL ("Ai Chan didn't provide a Mastodon entity!");
	}
}
