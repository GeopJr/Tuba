using Gtk;

public class Tootle.Views.Lists : Views.Timeline {

    [GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/list_item.ui")]
    public class Row : ListBoxRow {

		API.List? list;

		[GtkChild]
		Stack stack;
		[GtkChild]
		Label title;

		public Row (API.List? list) {
			this.list = list;

			if (list == null)
				stack.visible_child_name = "add";
			else
				list.bind_property ("title", title, "label", BindingFlags.SYNC_CREATE);
		}

		[GtkCallback]
		void on_edit_clicked () {
			new Dialogs.ListEditor (this.list);
		}

		[GtkCallback]
		void on_remove_clicked () {
			var yes = app.question (
				_("Delete \"%s\"?").printf (list.title),
				_("This action cannot be reverted.")
			);
			if (yes) {
				new Request.DELETE (@"/api/v1/lists/$(list.id)")
					.with_account (accounts.active)
					.then (() => { this.destroy (); })
					.exec ();
			}
		}

		public virtual signal void open () {
			if (this.list == null)
				return;

			var view = new Views.List (list);
			window.open_view (view);
		}
    }

	public new bool empty {
		get { return false; }
	}

    public Lists () {
        Object (
        	url: @"/api/v1/lists",
            label: _("Lists"),
            icon: "view-list-symbolic"
        );
        accepts = typeof (API.List);
    }

    public override void on_request_finish () {
        var add_row = new Row (null);
        add_row.open.connect (() => {
            var dlg = new Dialogs.ListEditor.empty ();
            dlg.done.connect (on_refresh);
        });
        append (add_row);
        on_content_changed ();
    }

}
