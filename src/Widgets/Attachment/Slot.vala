using Gtk;
using Gdk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/attachment_slot.ui")]
public class Tootle.Widgets.Attachment.Slot : FlowBoxChild {

	[GtkChild]
	EventBox event_box;
	[GtkChild]
	Label chip;
	[GtkChild]
	Image play_icon;
	[GtkChild]
	Stack stack;

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
		event_box.tooltip_text = attachment.description;
		event_box.button_release_event.connect (on_clicked);
	}

	void download () {
        Desktop.download (attachment.url, path => {
        	app.toast (_("Attachment downloaded"));
        });
	}
	void open () {
        Desktop.download (attachment.url, path => {
        	Desktop.open_uri (path);
        });
	}

    protected virtual bool on_clicked (EventButton ev) {
		if (ev.button != 1)
			return false;

		open ();
		return true;
    }

}
