[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/widgets/votebox.ui")]
public class Tuba.Widgets.VoteBox : Gtk.Box {
	[GtkChild] protected unowned Gtk.ListBox poll_box;
	[GtkChild] protected unowned Gtk.Button button_vote;
	[GtkChild] protected unowned Gtk.Button button_refresh;
	[GtkChild] protected unowned Gtk.Button button_results;
	[GtkChild] public unowned Gtk.Label info_label;

	public bool usable {
		set {
			button_vote.visible =
			button_refresh.visible =
			button_results.visible = value;
		}
	}

	public API.Poll? poll { get; set;}
	protected Gee.ArrayList<string> selected_index = new Gee.ArrayList<string> ();
	private bool show_results { get; set; default=false; }

	public API.Translation? translation { get; set; default=null; }

	construct {
		button_vote.clicked.connect (on_vote_button_clicked);
		notify["poll"].connect (update);
		button_vote.sensitive = false;

		poll_box.row_activated.connect (on_listboxrow_activated);

		Gtk.GestureClick click_gesture = new Gtk.GestureClick () {
			button = Gdk.BUTTON_PRIMARY
		};
		click_gesture.pressed.connect (on_clicked);
		poll_box.add_controller (click_gesture);
	}

	private void on_clicked (Gtk.GestureClick gesture, int n_press, double x, double y) {
		gesture.set_state (Gtk.EventSequenceState.CLAIMED);
	}

	private void on_listboxrow_activated (Gtk.ListBoxRow row) {
		var vote_row = row as Widgets.VoteRow;
		if (vote_row == null || !vote_row.check_button.visible) return;

		vote_row.check_button.active = !vote_row.check_button.active;
	}

	private void on_vote_button_clicked (Gtk.Button button) {
		button.sensitive = false;
		update_selected_index ();

		API.Poll.vote (accounts.active, poll.options, selected_index, poll.id)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);

				freeze_notify ();
				poll = API.Poll.from (network.parse_node (parser));
				thaw_notify ();
				update_rows ();

				button.sensitive = true;
			})
			.on_error ((code, reason) => {
				app.toast ("%s: %s".printf (_("Error"), reason));
				button.sensitive = true;
			})
			.exec ();
	}

	void update_translations () {
		if (poll.options != null && poll.options.size > 0) {
			if (
				translation != null
				&& translation.poll != null
				&& translation.poll.id != ""
				&& translation.poll.id == poll.id
				&& translation.poll.options.size > 0
			) {
				for (int i = 0; i < translation.poll.options.size; i++) {
					poll.options.get (i).tuba_translated_title = translation.poll.options.get (i).title;
				}
			} else {
				poll.options.@foreach (item => {
					item.tuba_translated_title = null;
					return true;
				});
			}
		}
	}

	Widgets.VoteRow[] vote_rows = {};
	void update () {
		vote_rows = {};
		var row_number = 0;
		Widgets.VoteCheckButton group_radio_option = null;

		// Clear all existing entries
		Gtk.Widget entry = poll_box.get_first_child ();
		while (entry != null) {
			poll_box.remove (entry);
			entry = poll_box.get_first_child ();
		}
		selected_index.clear ();

		var emojis_map = poll.gen_emojis_map ();
		// Create the entries of poll
		foreach (API.PollOption p in poll.options) {
			var row = new Widgets.VoteRow (p.title) {
				delayed_animation = true,
				instance_emojis = emojis_map
			};

			if (!poll.multiple) {
				if (row_number == 0) {
					group_radio_option = row.check_button;
				} else {
					row.check_button.set_group (group_radio_option);
				}
			}
			row.check_button.toggled.connect (on_check_option_toggled);

			vote_rows += row;
			poll_box.append (row);
			row_number++;
		}

		update_rows ();
	}

	private void update_aria () {
		string aria_poll = GLib.ngettext (
			// translators: This is an accessibility label.
			//				Screen reader users are going to hear this a lot,
			//				please be mindful.
			//				The variable is the amount of poll options
			"Poll with %d option.", "Poll with %d options.",
			(ulong) poll.options.size
		).printf (poll.options.size);

		string aria_voted = "";
		// translators: This is an accessibility label.
		//				Screen reader users are going to hear this a lot,
		//				please be mindful.
		//				Describes whether the user has voted on the poll.
		if (poll.voted) aria_voted = _("You have voted.");

		poll_box.update_property (
			Gtk.AccessibleProperty.LABEL,
			"%s %s %s.".printf (
				aria_poll,
				aria_voted,
				info_label.get_text ()
			),
			-1
		);
	}

	private void on_check_option_toggled (Gtk.CheckButton radio) {
		bool can_vote = false;
		foreach (var row in vote_rows) {
			if (row.check_button.active) {
				can_vote = true;
				break;
			}
		}

		button_vote.sensitive = can_vote;
	}

	private void update_selected_index () {
		foreach (var row in vote_rows) {
			bool contained = selected_index.contains (row.check_button.poll_title);
			bool active = row.check_button.active;
			if (contained && !active) {
				selected_index.remove (row.check_button.poll_title);
			} else if (!contained && active) {
				selected_index.add (row.check_button.poll_title);
			}
		}

		button_vote.sensitive = selected_index.size > 0;
	}

	[GtkCallback] private void on_refresh_poll () {
		if (poll == null) return;

		poll_box.grab_focus ();
		button_refresh.sensitive = false;
		new Request.GET (@"/api/v1/polls/$(poll.id)")
			.with_account (accounts.active)
			.then ((in_stream) => {
				button_refresh.sensitive = true;

				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				var parsed_poll = API.Poll.from (node);

				if (parsed_poll != null) {
					poll = parsed_poll;
					update_rows ();
				}
			})
			.on_error ((code, message) => {
				warning (@"Couldn't refresh poll $(poll.id): $code $message");
				button_refresh.sensitive = true;

				app.toast (@"Couldn't refresh poll: $message");
			})
			.exec ();
	}

	[GtkCallback] private void on_toggle_results () {
		if (poll == null) return;

		this.show_results = !this.show_results;
		update_rows ();
	}

	private void update_rows () {
		update_translations ();

		// Reset button visibility
		button_vote.sensitive = selected_index.size > 0;
		button_vote.visible = !this.show_results && !poll.expired && !poll.voted;
		button_results.visible = !poll.expired && !poll.voted;
		button_refresh.visible = !button_vote.visible && !poll.expired;

		if (this.show_results) {
			button_results.icon_name = "tuba-eye-not-looking-symbolic";
			// translators: tooltip of poll button that hides the current vote results
			button_results.tooltip_text = _("Hide Results");
		} else {
			button_results.icon_name = "tuba-eye-open-negative-filled-symbolic";
			// translators: tooltip of poll button that shows the current vote results
			button_results.tooltip_text = _("Show Results");
		}

		int64 winner_p = 0;
		if (poll.expired || poll.voted || this.show_results) {
			foreach (API.PollOption p in poll.options) {
				if (p.votes_count > winner_p) {
					winner_p = p.votes_count;
				}
			}
		}

		if (vote_rows.length <= poll.options.size) {
			for (int i = 0; i < vote_rows.length; i++) {
				var row = vote_rows[i];
				var p = poll.options.get (i);

				row.title = p.tuba_translated_title == null ? p.title : p.tuba_translated_title;
				row.voted = false;
				row.winner = false;
				row.show_results = false;
				row.check_button.active = selected_index.contains (row.check_button.poll_title);

				// If it is own poll
				if (poll.expired || poll.voted || this.show_results) {
					var percentage = poll.votes_count > 0 ? ((double)p.votes_count / poll.votes_count) * 100 : 0.0;

					row.percentage = percentage;
					row.winner = p.votes_count == winner_p;

					if (poll.own_votes != null) {
						foreach (int own_vote in poll.own_votes) {
							if (own_vote == i) {
								row.voted = true;
								break;
							}
						}
					}

					row.show_results = true;
				} else {
					if (poll.own_votes != null) {
						foreach (int own_vote in poll.own_votes) {
							if (own_vote == i) {
								row.check_button.active = true;
								row.voted = true;
							}
						}
					}
				}

				row.play_animation ();
			}
		}

		string voted_string = Tuba.Units.shorten (poll.votes_count);
		string voted_numerical_string = GLib.ngettext (
			// translators: the variable is the amount of people that voted
			"%s voted", "%s voted",
			(ulong) poll.votes_count
		).printf (voted_string);
		if (poll.expires_at != null) {
			info_label.label = "%s · %s".printf (
				voted_numerical_string,
				poll.expired
					? DateTime.humanize_ago (poll.expires_at)
					: DateTime.humanize_left (poll.expires_at)
			);
		} else {
			info_label.label = voted_numerical_string;
		}

		update_aria ();
		update_selected_index ();
	}
}
