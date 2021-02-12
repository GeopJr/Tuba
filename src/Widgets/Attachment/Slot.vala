using Gtk;
using Gdk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/attachment_slot.ui")]
public class Tootle.Widgets.Attachment.Slot : FlowBoxChild {

	[GtkChild] Button button;
	[GtkChild] Label chip;
	[GtkChild] Image play_icon;
	[GtkChild] Stack stack;

	public API.Attachment attachment { get; construct set; }

	public Slot (API.Attachment obj) {
		Object (attachment: obj);

		if (attachment.preview_url != null) {
			var img = new Widgets.Attachment.Picture (attachment.preview_url);
			img.notify["visible"].connect (() => {
				stack.visible_child_name = img.visible ? "content" : "loading";
			});
			stack.add_named (img, "content");
			img.on_request ();
		}

		if (attachment.kind != "image") {
			chip.label = attachment.kind;
			chip.show ();
		}

		switch (attachment.kind) {
			case "audio":
			case "video":
			case "gifv":
				play_icon.show ();
				break;
		}
	}

	construct {
		button.tooltip_text = attachment.description;
	}

	void open () {
        Desktop.download.begin (attachment.url, (obj, res) => {
			try {
				var path = Desktop.download.end (res);
				Desktop.open_uri (path);
			}
			catch (Error e) {
				app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
			}
        });
	}

	[GtkCallback]
    protected virtual void on_clicked () {
		open ();
    }

}
