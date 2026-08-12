public class Tuba.Dialogs.Drafts : Adw.NavigationPage, Composer.PreferredSizeable {
	public signal void draft_selected (Widgets.ScheduledStatus draft_status_widget);
	public int preferred_height { get; set; default = -1; }
	public int preferred_width { get; set; default = -1; }

	~Drafts () {
		debug ("Destroying Drafts");
	}

	construct {
		this.title = _("Draft Posts");
		var timeline = new InlineDraftsTimeline ();
		timeline.picked_draft.connect (on_draft_selected);
		var preferred_size_bin = new Composer.PreferredSizeBin () {
			child = timeline
		};

		this.bind_property ("preferred-height", preferred_size_bin, "height", SYNC_CREATE);
		this.bind_property ("preferred-width", preferred_size_bin, "width", SYNC_CREATE);

		this.child = preferred_size_bin;
	}

	private void on_draft_selected (Widgets.ScheduledStatus draft_status_widget) {
		draft_selected (draft_status_widget);
	}

	public class InlineDraftsTimeline : Views.Timeline {
		// will be passed InlineDraftsTimeline => Dialogs.Drafts => Composer
		public signal void picked_draft (Widgets.ScheduledStatus draft_status_widget);

		public InlineDraftsTimeline () {
			Object (
				url: "/api/v1/scheduled_statuses",
				label: _("Draft Posts"),
				icon: "tuba-chat-symbolic",
				empty_state_title: _("No Draft Posts"),
				batch_size_min: 20
			);

			header.show_start_title_buttons = false;
			header.show_end_title_buttons = false;
		}

		construct {
			accepts = typeof (API.ScheduledStatus);
		}

		public override Gtk.Widget on_create_model_widget (Object obj) {
			var widget = base.on_create_model_widget (obj);
			var widget_scheduled = widget as Widgets.ScheduledStatus;

			if (widget_scheduled != null) {
				widget_scheduled.draft = true;
				widget_scheduled.is_inline = true;
				widget_scheduled.inline_clicked.connect (on_inline_clicked);
			}

			return widget;
		}

		public override bool should_hide (Entity entity) {
			var scheduled_entity = entity as API.ScheduledStatus;
			return scheduled_entity != null && new GLib.DateTime.from_iso8601 (scheduled_entity.scheduled_at, null).get_year () <= API.ScheduledStatus.DRAFT_YEAR;
		}

		private void on_inline_clicked (Widgets.ScheduledStatus draft_status_widget) {
			picked_draft (draft_status_widget);
		}
	}
}
