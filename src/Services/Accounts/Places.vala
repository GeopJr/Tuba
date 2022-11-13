public class Tooth.Place : Object {

	public string title { get; set; }
	public string icon { get; set; }
	public int badge { get; set; default = 0; }
	public bool separated { get; set; default = false; }

	[CCode (has_target = false)]
	public delegate void OpenFunc (Dialogs.MainWindow window);

	public OpenFunc open_func { get; set; }

}
