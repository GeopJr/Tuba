public class Tuba.Dialogs.AnnualReport : Adw.Dialog {
	class PostButton : Gtk.Button {
		~PostButton () {
			debug (@"Destroying PostButton $(formal.id)");
		}

		construct {
			this.css_classes = {"card"};
		}

		API.Status formal;
		public PostButton (API.Status status) {
			formal = status.formal;

			status.formal.filtered = null;
			status.formal.tuba_spoiler_revealed = true;
			try {
				var widg = status.to_widget () as Widgets.Status;
				widg.actions.visible = false;
				widg.menu_button.visible = false;
				widg.activatable = false;
				widg.filter_stack.can_focus = false;
				widg.filter_stack.can_target = false;
				widg.filter_stack.focusable = false;

				this.child = widg;
			} catch {}

			this.clicked.connect (on_clicked);
		}

		private void on_clicked () {
			var view = new Views.Thread (formal);
			app.main_window.open_view (view);
		}
	}

	~AnnualReport () {
		debug ("Destroying AnnualReport");
	}

	string report_year;
	Gtk.Box content_box;
	Adw.ToastOverlay toast_overlay;
	Gtk.Box screenshot_box;
	Gtk.Button share_button;
	GLib.Menu style_menu;
	Gtk.WidgetPaintable screenshot_paintable;
	Adw.HeaderBar headerbar;
	construct {
		var actions = new SimpleActionGroup ();
		actions.add_action_entries (
			{
				{"change-style", on_change_style, "s"},
			},
			this
		);
		this.insert_action_group ("annual", actions);

		style_menu = new GLib.Menu ();
		style_menu.append (_("Default"), "annual.change-style('window')");
		// translators: Accent color
		style_menu.append (_("Accent"), "annual.change-style('accent')");
		style_menu.append ("Pride", "annual.change-style('pride')");
		style_menu.append ("Trans", "annual.change-style('trans')");

		this.add_css_class ("annual");
		this.content_height = this.content_width = 600;
		content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 36) {
			margin_top = margin_bottom = 12,
			margin_start = 6,
			margin_end = 6
		};

		var scrolled_window = new Gtk.ScrolledWindow () {
			hexpand = true,
			vexpand = true,
			child = new Adw.Clamp () {
				child = content_box,
				tightening_threshold = 100,
				valign = Gtk.Align.START
			}
		};

		toast_overlay = new Adw.ToastOverlay () {
			vexpand = true,
			hexpand = true,
			child = scrolled_window
		};

		var toolbarview = new Adw.ToolbarView () {
			content = toast_overlay
		};

		headerbar = new Adw.HeaderBar () {
			show_title = false
		};
		toolbarview.add_top_bar (headerbar);

		share_button = new Gtk.Button () {
			label = _("Share"),
			css_classes = {"suggested-action"}
		};
		share_button.clicked.connect (on_share);
		headerbar.pack_end (share_button);

		var download_button = new Gtk.Button () {
			icon_name = "document-save-symbolic",
			tooltip_text = _("Save As…")
		};
		download_button.clicked.connect (save_with_background);
		headerbar.pack_end (download_button);

		var style_button = new Gtk.MenuButton () {
			// translators: dropdown label for picking a window style
			label = _("Style"),
			menu_model = style_menu
		};
		headerbar.pack_start (style_button);

		this.child = toolbarview;
		scrolled_window.vadjustment.value_changed.connect (on_vadjustment_changed);
	}

	private void on_vadjustment_changed (Gtk.Adjustment vadjustment) {
		headerbar.show_title = vadjustment.value > 0;
	}

	string report_alt_text = "";
	public AnnualReport (API.AnnualReports report, int year = 0) {
		screenshot_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
			css_classes = {"annual-screenshot-box"}
		};
		screenshot_paintable = new Gtk.WidgetPaintable (screenshot_box);
		content_box.append (screenshot_box);

		var avi = new Widgets.Avatar () {
			account = accounts.active,
			size = 128
		};
		avi.add_css_class ("main-avi");
		screenshot_box.append (avi);

		API.AnnualReports.Report? current_report = null;
		if (year == 0 || report.annual_reports.size == 1) {
			current_report = report.annual_reports.get (0);
		} else {
			foreach (API.AnnualReports.Report t_report in report.annual_reports) {
				if (t_report.year == year) {
					current_report = t_report;
					break;
				}
			}

			if (current_report == null) {
				current_report = report.annual_reports.get (0);
			}
		}
		report_year = current_report.year.to_string ();

		// translators: This is part of the alt text of the Fedi Wrapped 'Share' attachment,
		//				which will be used as the attachment alt text when posted on fedi.
		//				The first variable is the annual report year (e.g. 2024), the second
		//				variable is the app name (Tuba)
		report_alt_text += _("Screenshot of my %s Wrapped annual report using %s.").printf (report_year, Build.NAME);

		// translators: The variable is the year (e.g. 2024). Wrapped as in
		//				Spotify wrapped / recap of the year. You can leave it
		//				as is as it's more of an annual event that it's known
		//				as 'wrapped'
		var title = _("%s Wrapped").printf (report_year);
		this.title = title;
		screenshot_box.append (new Gtk.Label (title) {
			css_classes = {"title-1"}
		});

		var stats_flowbox = new Gtk.FlowBox () {
			selection_mode = Gtk.SelectionMode.NONE,
			column_spacing = 6,
			row_spacing = 6,
			max_children_per_line = 2,
			homogeneous = true
		};
		screenshot_box.append (stats_flowbox);

		Gee.HashMap<string, API.Account> report_accounts = new Gee.HashMap<string, API.Account> ();
		foreach (var account in report.accounts) {
			report_accounts.set (account.id, account);
		}

		int64 total_new_followers = 0;
		int64 total_new_followings = 0;
		if (current_report.data.time_series.size > 0) {
			var posts_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
				margin_top = margin_bottom = margin_start = margin_end = 6,
				valign = Gtk.Align.CENTER
			};
			// translators: #FediWrapped, title of the 'amount of new posts' card
			posts_box.append (new Gtk.Label (_("New Posts")) {
				css_classes = {"caption-heading"}
			});

			int64 total_new_posts = 0;
			foreach (var stats in current_report.data.time_series) {
				total_new_posts += stats.statuses;
				total_new_followers += stats.followers;
				total_new_followings += stats.following;
			}

			string shortened_value = Units.shorten (total_new_posts);
			posts_box.append (new Gtk.Label (shortened_value) {
				css_classes = {"title-1"},
				wrap = true,
				wrap_mode = Pango.WrapMode.WORD_CHAR
			});

			stats_flowbox.append (new Gtk.FlowBoxChild () {
				css_classes = {"card"},
				child = posts_box
			});

			// translators: This is part of the alt text of the Fedi Wrapped 'Share' attachment,
			//				which will be used as the attachment alt text when posted on fedi.
			//				The variable is the amount of posts made (e.g. 1k)
			report_alt_text += _("I made %s posts.").printf (shortened_value);
		}

		if (current_report.data.top_hashtags.size > 0) {
			var hashtags_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
				margin_top = margin_bottom = margin_start = margin_end = 6,
				valign = Gtk.Align.CENTER
			};

			// translators: #FediWrapped, title of a card
			hashtags_box.append (new Gtk.Label (_("Most Used Hashtag")) {
				css_classes = {"caption-heading"}
			});

			string most_used_hashtag = "";
			int64 max_count = -1;
			foreach (var hashtag in current_report.data.top_hashtags) {
				if (hashtag.count > max_count) {
					max_count = hashtag.count;
					most_used_hashtag = hashtag.name;
				}
			}

			hashtags_box.append (new Gtk.Label (@"#$most_used_hashtag") {
				css_classes = {"title-1"},
				wrap = true,
				wrap_mode = Pango.WrapMode.WORD_CHAR
			});

			stats_flowbox.append (new Gtk.FlowBoxChild () {
				css_classes = {"card"},
				child = hashtags_box
			});

			// translators: This is part of the alt text of the Fedi Wrapped 'Share' attachment,
			//				which will be used as the attachment alt text when posted on fedi.
			//				The variable is the most used hashtag
			report_alt_text += _("My most used hashtag was #%s.").printf (most_used_hashtag);
		}

		if (current_report.data.most_used_apps.size > 0) {
			var apps_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
				margin_top = margin_bottom = margin_start = margin_end = 6,
				valign = Gtk.Align.CENTER
			};

			// translators: #FediWrapped, title of the 'which app was used to make most posts' card
			apps_box.append (new Gtk.Label (_("Most Used App")) {
				css_classes = {"caption-heading"}
			});

			string most_used_app = "";
			int64 max_count = -1;
			foreach (var app in current_report.data.most_used_apps) {
				if (app.count > max_count) {
					max_count = app.count;
					most_used_app = app.name;
				}
			}

			apps_box.append (new Gtk.Label (most_used_app) {
				css_classes = {"title-1"},
				wrap = true,
				wrap_mode = Pango.WrapMode.WORD_CHAR
			});

			string[] classes = {"card"};
			if (most_used_app.down () == Build.NAME.down ()) classes += "tuba";
			stats_flowbox.append (new Gtk.FlowBoxChild () {
				css_classes = classes,
				child = apps_box
			});

			// translators: This is part of the alt text of the Fedi Wrapped 'Share' attachment,
			//				which will be used as the attachment alt text when posted on fedi.
			//				The variable is the name of the most used client (e.g. Tuba)
			report_alt_text += _("My most used app was %s.").printf (most_used_app);
		}

		if (current_report.data.commonly_interacted_with_accounts.size > 0) {
			var circle_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
				margin_top = margin_bottom = margin_start = margin_end = 6,
				valign = Gtk.Align.CENTER
			};

			// translators: #FediWrapped, title of the card that shows you
			//				the users you interacted with the most
			circle_box.append (new Gtk.Label (_("Most Interactions")) {
				css_classes = {"caption-heading"}
			});

			var besties_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
				halign = Gtk.Align.CENTER
			};

			string[] interaction_names = {};
			current_report.data.commonly_interacted_with_accounts.sort (sort_countable);
			for (int i = 0; i < int.min (current_report.data.commonly_interacted_with_accounts.size, 3); i++) {
				var acc_id = current_report.data.commonly_interacted_with_accounts.get (i).account_id;
				if (report_accounts.has_key (acc_id)) {
					var acc = report_accounts.get (acc_id);
					besties_box.append (new Widgets.Avatar () {
						account = acc,
						size = 48,
						tooltip_text = acc.display_name
					});
					interaction_names += acc.display_name;
				}
			}

			circle_box.append (besties_box);
			stats_flowbox.append (new Gtk.FlowBoxChild () {
				css_classes = {"card"},
				child = circle_box
			});

			// translators: This is part of the alt text of the Fedi Wrapped 'Share' attachment,
			//				which will be used as the attachment alt text when posted on fedi.
			//				The variable is a list of user names (e.g. GeopJr, Tuba, Vala).
			//				The amount of users could be just one and some languages might
			//				require pronouns or prefixes, if so, feel free to translate it as
			//				'I had the most interactions with the following people: %s.'
			report_alt_text += _("I had the most interactions with %s.").printf (string.joinv (", ", interaction_names));
		}

		var advanced_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 24);
		content_box.append (advanced_box);

		if (total_new_followers > 0 || total_new_followings > 0) {
			var follow_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
			// translators: #FediWrapped, title of the section about how many
			//				new followers you got and new people you followed
			follow_box.append (new Gtk.Label (_("Follow Stats")) {
				css_classes = { "title-1" }
			});

			var follow_stats_flowbox = new Gtk.FlowBox () {
				selection_mode = Gtk.SelectionMode.NONE,
				column_spacing = 6,
				row_spacing = 6,
				max_children_per_line = 2,
				homogeneous = true
			};
			follow_box.append (follow_stats_flowbox);

			if (total_new_followers > 0) {
				var followers_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
					margin_top = margin_bottom = margin_start = margin_end = 6,
					valign = Gtk.Align.CENTER
				};

				// translators: #FediWrapped, title of the 'amount of new followers' card
				followers_box.append (new Gtk.Label (_("New Followers")) {
					css_classes = {"caption-heading"}
				});

				followers_box.append (new Gtk.Label (Units.shorten (total_new_followers)) {
					css_classes = {"title-1"},
					wrap = true,
					wrap_mode = Pango.WrapMode.WORD_CHAR
				});

				follow_stats_flowbox.append (new Gtk.FlowBoxChild () {
					css_classes = {"card"},
					child = followers_box
				});
			}

			if (total_new_followings > 0) {
				var follows_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
					margin_top = margin_bottom = margin_start = margin_end = 6,
					valign = Gtk.Align.CENTER
				};

				// translators: #FediWrapped, title of the 'amount of new people you followed' card
				follows_box.append (new Gtk.Label (_("New Follows")) {
					css_classes = {"caption-heading"}
				});

				follows_box.append (new Gtk.Label (Units.shorten (total_new_followings)) {
					css_classes = {"title-1"},
					wrap = true,
					wrap_mode = Pango.WrapMode.WORD_CHAR
				});

				follow_stats_flowbox.append (new Gtk.FlowBoxChild () {
					css_classes = {"card"},
					child = follows_box
				});
			}

			advanced_box.append (follow_box);
		}

		if (current_report.data.top_statuses.by_favourites != null) {
			var status_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
			// translators: #FediWrapped, title of the section that shows you
			//				which one of your posts had the most favorites
			status_box.append (new Gtk.Label (_("Most Favorited Post")) {
				css_classes = { "title-1" }
			});

			foreach (var status in report.statuses) {
				if (status.id == current_report.data.top_statuses.by_favourites) {
					var post_btn = new PostButton (status);
					post_btn.clicked.connect (on_post_button_clicked);
					status_box.append (post_btn);
					break;
				}
			}

			advanced_box.append (status_box);
		}

		if (current_report.data.top_statuses.by_reblogs != null) {
			var status_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
			// translators: #FediWrapped, title of the section that shows you
			//				which one of your posts had the most boosts
			status_box.append (new Gtk.Label (_("Most Boosted Post")) {
				css_classes = { "title-1" }
			});

			foreach (var status in report.statuses) {
				if (status.id == current_report.data.top_statuses.by_reblogs) {
					var post_btn = new PostButton (status);
					post_btn.clicked.connect (on_post_button_clicked);
					status_box.append (post_btn);
					break;
				}
			}

			advanced_box.append (status_box);
		}

		if (current_report.data.top_statuses.by_replies != null) {
			var status_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
			// translators: #FediWrapped, title of the section that shows you
			//				which one of your posts had the most replies
			status_box.append (new Gtk.Label (_("Most Replied Post")) {
				css_classes = { "title-1" }
			});

			foreach (var status in report.statuses) {
				if (status.id == current_report.data.top_statuses.by_replies) {
					var post_btn = new PostButton (status);
					post_btn.clicked.connect (on_post_button_clicked);
					status_box.append (post_btn);
					break;
				}
			}

			advanced_box.append (status_box);
		}
	}

	private void on_post_button_clicked () {
		this.force_close ();
	}

	private void on_share () {
		share_button.sensitive = false;

		var texture = do_screenshot ();
		if (texture == null) {
			share_button.sensitive = true;
			return;
		}

		share_async.begin (texture, (obj, res) => {
			try {
				new Dialogs.Compose (share_async.end (res));
			} catch (Error e) {
				warning (e.message);
				toast_overlay.add_toast (new Adw.Toast (e.message) {
					timeout = 5
				});
			}

			share_button.sensitive = true;
		});
	}

	private async API.Status share_async (Gdk.Texture texture) throws GLib.Error {
		var attachment = yield API.Attachment.upload (null, texture.save_to_png_bytes (), "image/png");
		var builder = new Json.Builder ();
		builder.begin_object ();
		builder.set_member_name ("description");
		builder.add_string_value (report_alt_text);
		builder.end_object ();

		var req = new Request.PUT (@"/api/v1/media/$(attachment.id)")
			.with_account (accounts.active)
			.body_json (builder);

		yield req.await ();

		attachment.description = report_alt_text;
		var status = new API.Status.empty ();
		status.content = "#Wrapstodon #FediWrapped";
		status.media_attachments = new Gee.ArrayList<API.Attachment>.wrap ({attachment});

		return status;
	}

	private void save_with_background () {
		save_as_async.begin ();
	}

	private async void save_as_async () {
		var chooser = new Gtk.FileDialog () {
			// translators: save dialog title, refer to the other #FediWrapped strings for more info
			title = _("Save #FediWrapped"),
			modal = true,
			initial_name = @"$report_year-wrapped.png"
		};

		try {
			var file = yield chooser.save (app.main_window, null);
			if (file != null) {
				var texture = do_screenshot ();
				if (texture != null) {
					FileOutputStream stream = file.replace (null, false, FileCreateFlags.PRIVATE);
					try {
						yield stream.write_bytes_async (texture.save_to_png_bytes ());

						// translators: the variable is a year, e.g. 2024
						toast_overlay.add_toast (new Adw.Toast (_("Saved %s Wrapped").printf (report_year)) {
							timeout = 5
						});
					} catch (GLib.IOError e) {
						warning (e.message);
						toast_overlay.add_toast (new Adw.Toast (e.message) {
							timeout = 5
						});
					}
				}
			}
		} catch (Error e) {
			// User dismissing the dialog also ends here so don't make it sound like
			// it's an error
			warning (@"Couldn't get the result of FileDialog for annual report: $(e.message)");
		}
	}

	enum Background {
		TRANSPARENT,
		WINDOW,
		ACCENT,
		PRIDE,
		TRANS;

		public static Background from_string (string name) {
			switch (name.down ()) {
				case "window": return WINDOW;
				case "accent": return ACCENT;
				case "pride": return PRIDE;
				case "trans": return TRANS;
				default: return TRANSPARENT;
			}
		}

		public string to_string () {
			switch (this) {
				case WINDOW: return "style-window";
				case ACCENT: return "style-accent";
				case PRIDE: return "style-pride";
				case TRANS: return "style-trans";
				default: return "";
			}
		}
	}

	private Gdk.Texture? do_screenshot () {
		int width = screenshot_box.get_width ();
		int height = screenshot_box.get_height ();
		if (int.min (width, height) < 512) {
			if (width < height) {
				height = (int) (((float) height / (float) width) * 512);
				width = 512;
			} else {
				width = (int) (((float) width / (float) height) * 512);
				height = 512;
			}
		}

		Graphene.Rect rect = Graphene.Rect.zero ();
		rect.init (0, 0, (float) width, (float) height);

		Gtk.Snapshot snapshot = new Gtk.Snapshot ();
		screenshot_paintable.snapshot (snapshot, width, height);

		Gsk.RenderNode? node = snapshot.to_node ();
		if (node == null) {
			critical (@"Could not get node snapshot, width: $width, height: $height");
			toast_overlay.add_toast (new Adw.Toast (@"Could not get node snapshot, width: $width, height: $height") {
				timeout = 5
			});
			return null;
		}

		Gsk.Renderer renderer = screenshot_box.get_native ().get_renderer ();
		return renderer.render_texture (node, rect);
	}

	Background current_style = Background.TRANSPARENT;
	private void on_change_style (GLib.SimpleAction action, GLib.Variant? value) {
		if (value == null) return;

		string current_style_class = current_style.to_string ();
		if (current_style_class != "" && screenshot_box.has_css_class (current_style_class))
			screenshot_box.remove_css_class (current_style_class);
		current_style = Background.from_string (value.get_string ());
		screenshot_box.add_css_class (current_style.to_string ());
	}

	private int sort_countable (API.AnnualReports.Report.Data.Countable a, API.AnnualReports.Report.Data.Countable b) {
		return (int) (a.count < b.count) - (int) (a.count > b.count);
	}
}
