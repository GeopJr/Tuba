public class Tuba.Place : Object {
	public string title { get; set; }
	public string icon { get; set; }
	public int badge { get; set; default = 0; }
	public bool separated { get; set; default = false; }
	public bool selectable { get; set; default = true; }
	public bool visible { get; set; default = true; }
	public bool needs_attention { get; construct set; default=true; }
	public Object? extra_data { get; set; default = null; }

	[CCode (has_target = false)]
	public delegate void OpenFunc (Dialogs.MainWindow window, Object? extra = null);

	public OpenFunc open_func { get; set; }
}
