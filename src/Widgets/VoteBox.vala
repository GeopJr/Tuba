[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/widgets/votebox.ui")]
public class Tuba.Widgets.VoteBox : Gtk.Box {
	[GtkChild] protected unowned Gtk.ListBox poll_box;
	[GtkChild] protected unowned Gtk.Button button_vote;
	[GtkChild] protected unowned Gtk.Button button_refresh;
	[GtkChild] protected unowned Gtk.Button button_results;
	[GtkChild] protected unowned Gtk.Label info_label;

	public API.Poll? poll { get; set;}
	protected Gee.ArrayList<string> selected_index = new Gee.ArrayList<string> ();
	private bool show_results { get; set; default=false; }

	public API.Translation? translation { get; set; default=null; }

	construct {
		button_vote.clicked.connect (on_vote_button_clicked);
		notify["poll"].connect (update);
		button_vote.sensitive = false;
	}

	private void on_vote_button_clicked (Gtk.Button button) {
		button.sensitive = false;
		API.Poll.vote (accounts.active, poll.options, selected_index, poll.id)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				poll = API.Poll.from (network.parse_node (parser));

				button.sensitive = true;
			})
			.on_error ((code, reason) => {
				app.toast ("%s: %s".printf (_("Error"), reason));
				button.sensitive = true;
			})
			.exec ();
	}

	public string generate_css_style (int percentage) {
		return @".ttl-poll-$(percentage).ttl-poll-winner { background: linear-gradient(to right, alpha(@accent_bg_color, .5) $(percentage)%, transparent 0%) no-repeat; } .ttl-poll-$(percentage) { background: linear-gradient(to right, alpha(@view_fg_color, .1) $(percentage)%, transparent 0%) no-repeat; }"; // vala-lint=line-length
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

	void update () {
		update_translations ();

		var row_number = 0;
		int64 winner_p = 0;
		Widgets.VoteCheckButton group_radio_option = null;

		// Clear all existing entries
		Gtk.Widget entry = poll_box.get_first_child ();
		while (entry != null) {
			poll_box.remove (entry);
			entry = poll_box.get_first_child ();
		}

		selected_index.clear ();

		// Reset button visibility
		button_vote.sensitive = false;
		button_vote.visible = !this.show_results && !poll.expired && !poll.voted;
		button_results.visible = !poll.expired && !poll.voted;

		if (this.show_results) {
			button_results.icon_name = "tuba-eye-not-looking-symbolic";
			button_results.tooltip_text = _("Hide Results");
		} else {
			button_results.icon_name = "tuba-eye-open-negative-filled-symbolic";
			button_results.tooltip_text = _("Show Results");
		}

		if (poll.expired || poll.voted || this.show_results) {
			foreach (API.PollOption p in poll.options) {
				if (p.votes_count > winner_p) {
					winner_p = p.votes_count;
				}
			}
		}

		// Create the entries of poll
		foreach (API.PollOption p in poll.options) {
			var row = new Adw.ActionRow () {
				css_classes = { "ttl-poll-row" },
				use_markup = false,
				title = p.tuba_translated_title == null ? p.title : p.tuba_translated_title
			};

			// If it is own poll
			if (poll.expired || poll.voted || this.show_results) {
				// If multiple, Checkbox else radioButton
				var percentage = poll.votes_count > 0 ? ((double)p.votes_count / poll.votes_count) * 100 : 0.0;

				var provider = new Gtk.CssProvider ();
				provider.load_from_string (generate_css_style ((int) percentage));

				row.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
				row.add_css_class (@"ttl-poll-$((int) percentage)");
				row.add_css_class ("ttl-poll-voted");

				if (p.votes_count == winner_p) {
					row.add_css_class ("ttl-poll-winner");
				}

				if (poll.own_votes != null) {
					foreach (int own_vote in poll.own_votes) {
						if (own_vote == row_number) {
							row.add_suffix (new Gtk.Image.from_icon_name ("tuba-check-round-outline-symbolic") {
								tooltip_text = _("Voted")
							});
						}
					}
				}

				row.subtitle = "%.1f%%".printf (percentage);
				poll_box.append (row);
			} else {
				var check_option = new Widgets.VoteCheckButton ();

				if (!poll.multiple) {
					if (row_number == 0) {
						group_radio_option=check_option;
					} else {
						check_option.set_group (group_radio_option);
					}
				}

				check_option.poll_title = p.title;
				check_option.toggled.connect (on_check_option_toggeled);

				if (poll.own_votes != null) {
					foreach (int own_vote in poll.own_votes) {
						if (own_vote == row_number) {
							check_option.active = true;
							row.add_suffix (new Gtk.Image.from_icon_name ("tuba-check-round-outline-symbolic") {
								tooltip_text = _("Voted")
							});

							if (!selected_index.contains (p.title)) {
								selected_index.add (p.title);
							}
						}
					}
				}

				if (poll.expired || poll.voted || this.show_results) {
					check_option.sensitive = false;
				}

				row.add_prefix (check_option);
				row.activatable_widget = check_option;

				poll_box.append (row);
			}

			row_number++;
		}

		string voted_string = Tuba.Units.shorten (poll.votes_count);
		if (poll.expires_at != null) {
			info_label.label = "%s · %s".printf (
				// translators: the variable is the amount of people that voted
				_("%s voted").printf (voted_string),
				poll.expired
					? DateTime.humanize_ago (poll.expires_at)
					: DateTime.humanize_left (poll.expires_at)
			);
		} else {
			info_label.label = _("%s voted").printf (voted_string);
		}

		update_aria ();
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

		this.update_property (
			Gtk.AccessibleProperty.LABEL,
			"%s %s %s.".printf (
				aria_poll,
				aria_voted,
				info_label.get_text ()
			),
			-1
		);
	}

	private void on_check_option_toggeled (Gtk.CheckButton radio) {
		var radio_votebutton = radio as Widgets.VoteCheckButton;
		if (selected_index.contains (radio_votebutton.poll_title)) {
			selected_index.remove (radio_votebutton.poll_title);
		} else {
			selected_index.add (radio_votebutton.poll_title);
		}

		button_vote.sensitive = selected_index.size > 0;
	}

	[GtkCallback] private void on_refresh_poll () {
		if (poll == null) return;

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
					update ();
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
		update ();
	}
}
