public class Tuba.Dialogs.Report : Adw.Window {
	~Report () {
		debug ("Destroying Report");
	}

	private enum Category {
		SPAM,
		VIOLATION,
		OTHER;

		public string to_string () {
			switch (this) {
				case SPAM: return "spam";
				case VIOLATION: return "violation";
				case OTHER: return "other";
				default: assert_not_reached ();
			}
		}

		public string to_title () {
			switch (this) {
				case SPAM: return "It's spam";
				case VIOLATION: return "It violates server rules";
				case OTHER: return "It's something else";
				default: assert_not_reached ();
			}
		}

		public string to_description () {
			switch (this) {
				case SPAM: return "Malicious links, fake engagement, or repetitive replies";
				case VIOLATION: return "You are aware that it breaks specific rules";
				case OTHER: return "The issue does not fit into other categories";
				default: assert_not_reached ();
			}
		}
	}

	Adw.Carousel carousel;
	bool has_rules;
	Gee.HashMap<Category, Gtk.CheckButton> check_buttons;
	Gee.HashMap<string, Gtk.CheckButton> rules_buttons;
	Gee.HashMap<string, Gtk.CheckButton> status_buttons;
	Gtk.Stack page_3_stack;
	Adw.StatusPage page_3_error;
	Gtk.Button next_button;
	Gtk.Button back_button;
	Adw.PreferencesGroup group_3;
	Adw.PreferencesPage page_2;
	Adw.PreferencesPage page_3;
	Adw.PreferencesPage page_4;
	Category[] categories;
	string account_id;
	Adw.SwitchRow forward_switch;
	Adw.EntryRow additional_info;
	string? status_id = null;
	construct {
		var back_action = new SimpleAction ("back", null);
		back_action.activate.connect (on_back);

		var action_group = new GLib.SimpleActionGroup ();
		action_group.add_action (back_action);

		this.insert_action_group ("report", action_group);
		this.add_binding_action (Gdk.Key.Escape, 0, "report.back", null);

		has_rules = accounts.active.instance_info.rules != null && accounts.active.instance_info.rules.size > 0;

		categories = {Category.SPAM};
		if (has_rules) categories += Category.VIOLATION;
		categories += Category.OTHER;

		this.transient_for = app.main_window;
		this.modal = true;
		this.default_height = 520;
		this.default_width = 460;

		var toolbarview = new Adw.ToolbarView ();
		var headerbar = new Adw.HeaderBar () {
			show_end_title_buttons = false,
			show_start_title_buttons = false
		};
		back_button = new Gtk.Button.with_label (_("Cancel"));
		back_button.clicked.connect (on_back);
		next_button = new Gtk.Button.with_label (_("Next")) {
			css_classes = { "suggested-action" },
			sensitive = false
		};
		next_button.clicked.connect (on_next);

		headerbar.pack_start (back_button);
		headerbar.pack_end (next_button);
		toolbarview.add_top_bar (headerbar);

		carousel = new Adw.Carousel () {
			allow_long_swipes = false,
			allow_mouse_drag = false,
			allow_scroll_wheel = false,
			interactive = false
		};
		carousel.notify["position"].connect (on_position_change);
		toolbarview.content = carousel;
		toolbarview.add_bottom_bar (new Adw.CarouselIndicatorDots () {
			carousel = carousel
		});
		this.content = toolbarview;
	}

	public Report (API.Account account, string? status_id = null) {
		// translators: the variable is an account handle
		this.title = _("Reporting %s").printf (@"$(account.username)@$(account.domain)");
		this.status_id = status_id;
		populate_posts (account.id, status_id);
		account_id = account.id;

		install_page_1 ();
		if (has_rules) {
			install_page_2 ();
		}
		install_page_3 ();
		install_page_4 (account.domain);

		this.present ();
	}

	private void install_page_1 () {
		var page_1 = new Adw.PreferencesPage () {
			hexpand = true,
			vexpand = true,
			valign = Gtk.Align.CENTER
		};
		var group_1 = new Adw.PreferencesGroup ();

		if (status_id == null) {
			// translators: you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			//				this is meant for reporting users
			group_1.title = _("Tell us what's going on with this account");
		} else {
			// translators: you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			//				this is meant for reporting posts
			group_1.title = _("Tell us what's going on with this post");
		}

		// translators: you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
		//				this is shown above a list of radio-button options where the user can only choose one
		group_1.set_description (_("Choose the best match"));

		Gtk.CheckButton? group = null;
		check_buttons = new Gee.HashMap<Category, Gtk.CheckButton> ();
		foreach (Category category in categories) {
			var checkbutton = new Gtk.CheckButton () {
				css_classes = {"selection-mode"}
			};
			checkbutton.toggled.connect (on_category_set);
			check_buttons.set (category, checkbutton);

			if (group != null) {
				checkbutton.group = group;
			} else {
				group = checkbutton;
			}

			var category_row = new Adw.ActionRow () {
				title = category.to_title (),
				subtitle = category.to_description (),
				activatable_widget = checkbutton,
				use_markup = false
			};
			category_row.add_prefix (checkbutton);

			group_1.add (category_row);
		}

		page_1.add (group_1);
		carousel.append (page_1);
	}

	private void install_page_2 () {
		page_2 = new Adw.PreferencesPage () {
			hexpand = true,
			vexpand = true,
			valign = Gtk.Align.CENTER
		};
		var group_2 = new Adw.PreferencesGroup () {
			// translators: you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			title = _("Which rules are being violated?")
		};

		// translators: you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
		//				this shown above a list of checkbox options where the user can select multiple
		group_2.set_description (_("Select all that apply"));

		rules_buttons = new Gee.HashMap<string, Gtk.CheckButton> ();
		foreach (var rule in accounts.active.instance_info.rules) {
			var checkbutton = new Gtk.CheckButton () {
				css_classes = {"selection-mode"}
			};
			checkbutton.toggled.connect (on_rule_set);
			rules_buttons.set (rule.id, checkbutton);

			var rule_row = new Adw.ActionRow () {
				title = GLib.Markup.escape_text (rule.text).strip (),
				activatable_widget = checkbutton,
				use_markup = true
			};
			rule_row.add_prefix (checkbutton);

			group_2.add (rule_row);
		}

		page_2.add (group_2);
		carousel.append (page_2);
	}

	private void install_page_3 () {
		page_3 = new Adw.PreferencesPage () {
			hexpand = true,
			vexpand = true
		};
		page_3_error = new Adw.StatusPage () {
			vexpand = true,
			hexpand = true,
			// translators: 'fetch' as in get
			title = _("Couldn't fetch all user's posts")
		};
		page_3_stack = new Gtk.Stack () {
			vexpand = true,
			hexpand = true,
			valign = Gtk.Align.CENTER
		};
		page_3_stack.add_named (new Gtk.Spinner () {
			spinning = true,
			halign = Gtk.Align.CENTER,
			valign = Gtk.Align.CENTER,
			vexpand = true,
			hexpand = true,
			width_request = 32,
			height_request = 32
		}, "spinner");
		page_3_stack.add_named (page_3, "main");
		page_3_stack.add_named (page_3_error, "error");

		group_3 = new Adw.PreferencesGroup ();

		if (status_id == null) {
			// translators: you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			//				this is shown above a list of posts. The user is meant to choose any that should be included in the report
			group_3.title = _("Are there any posts that back up this report?");
		} else {
			// translators: this is the same as 'Are there any posts that back up this report?' but for when you are reporting a post
			//				that's why it asks about choosing 'other' posts
			group_3.title = _("Are there any other posts that back up this report?");
		}

		// translators: you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
		//				this shown above a list of checkbox options where the user can select multiple
		group_3.set_description (_("Select all that apply"));
		page_3.add (group_3);
		carousel.append (page_3_stack);
	}

	private void install_page_4 (string domain) {
		page_4 = new Adw.PreferencesPage () {
			hexpand = true,
			vexpand = true,
			valign = Gtk.Align.CENTER
		};
		var group_4 = new Adw.PreferencesGroup () {
			// translators: you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			//				this is shown at the top of the last page of the report dialog
			title = _("Is there anything else you think we should know?")
		};

		additional_info = new Adw.EntryRow () {
			// translators: you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			//				additional comments to be included in the report
			title = _("Additional Comments")
		};
		additional_info.changed.connect (on_additional_info_changed);
		group_4.add (additional_info);

		if (accounts.active.domain != domain) {
			forward_switch = new Adw.SwitchRow () {
				// translators: you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
				//				the variable is an instance name e.g. 'Forward to mastodon.social'
				title = _("Forward to %s").printf (domain),
				active = true
			};
			group_4.add (forward_switch);
		}

		page_4.add (group_4);
		carousel.append (page_4);
	}

	private void on_back () {
		uint car_pos = (uint) carousel.position;
		if (car_pos >= 1) {
			var pos = car_pos - 1;
			var page_to = carousel.get_nth_page (pos);
			while (page_to.sensitive == false) {
				pos -= 1;
				page_to = carousel.get_nth_page (pos);
			}

			next_button.sensitive = true;
			carousel.scroll_to (page_to, true);
		} else {
			this.close ();
		}
	}

	private void on_next () {
		uint car_pos = (uint) carousel.position;
		if (car_pos < carousel.n_pages - 1) {
			var pos = car_pos + 1;
			var page_to = carousel.get_nth_page (pos);
			while (page_to.sensitive == false) {
				pos += 1;
				page_to = carousel.get_nth_page (pos);
			}
			if (page_to == page_2) on_rule_set ();
			if (page_to == page_4) on_additional_info_changed ();

			carousel.scroll_to (page_to, true);
		} else {
			app.question.begin (
				// translators: submit the report
				{_("Are you sure you want to submit?"), false},
				null,
				this,
				{ { _("Submit"), Adw.ResponseAppearance.SUGGESTED }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
				false,
				(obj, res) => {
					if (app.question.end (res).truthy ()) {
						submit ();
						this.destroy ();
					}
				}
			);
		}
	}

	private void submit () {
		bool forward = false;
		if (forward_switch != null) forward = forward_switch.active;

		var msg = new Request.POST ("/api/v1/reports")
			.with_account (accounts.active)
			.with_form_data ("account_id", account_id)
			.with_form_data ("forward", forward.to_string ());

		if (additional_info.text != "") msg.with_form_data ("comment", additional_info.text);

		Category category = Category.OTHER;
		check_buttons.foreach (e => {
			if (((Gtk.CheckButton) e.value).active) {
				category = (Category) e.key;
				return false;
			}

			return true;
		});
		msg.with_form_data ("category", category.to_string ());

		if (category == Category.VIOLATION) {
			rules_buttons.foreach (e => {
				if (((Gtk.CheckButton) e.value).active) {
					msg.with_form_data ("rule_ids[]", ((string) e.key));
				}
				return true;
			});
		}

		if (status_id != null) msg.with_form_data ("status_ids[]", status_id);
		status_buttons.foreach (e => {
			if (((Gtk.CheckButton) e.value).active) {
				msg.with_form_data ("status_ids[]", ((string) e.key));
			}
			return true;
		});

		msg
			.on_error ((code, message) => {
				warning (@"Error while submitting report: $code $message");

				// translators: the variable is an error
				app.toast (_("Couldn't submit report: %s").printf (message), 0);
			})
			.exec ();
	}

	private void on_additional_info_changed () {
		if (additional_info.text.length > 1000) {
			additional_info.add_css_class ("error");
			next_button.sensitive = false;
		} else {
			additional_info.remove_css_class ("error");
			next_button.sensitive = true;
		}
	}

	private void on_position_change () {
		if (carousel.position == 0) {
			back_button.label = _("Cancel");
		} else {
			back_button.label = _("Back");
		}

		if (carousel.position == carousel.n_pages - 1) {
			next_button.label = _("Submit");
		} else {
			next_button.label = _("Next");
		}
	}

	private class StatusRow : Gtk.ListBoxRow {
		public Gtk.CheckButton check_button { get; set; }

		public StatusRow (Gtk.CheckButton btn, Widgets.Status widget_status) {
			check_button = btn;
			this.activatable = true;

			var status_row_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
				margin_start = 6,
				margin_end = 6
			};
			status_row_box.append (check_button);
			status_row_box.append (widget_status);
			this.child = status_row_box;
		}

		public void toggle () {
			check_button.active = !check_button.active;
		}
	}

	private void populate_posts (string account_id, string? status_id = null) {
		new Request.GET (@"/api/v1/accounts/$(account_id)/statuses")
			.with_param ("exclude_replies", "false")
			.with_param ("exclude_reblogs", "true")
			.with_account (accounts.active)
			.then ((in_stream) => {
				status_buttons = new Gee.HashMap<string, Gtk.CheckButton> ();
				var listbox = new Gtk.ListBox () {
					selection_mode = Gtk.SelectionMode.NONE,
					css_classes = {"boxed-list"}
				};
				listbox.row_activated.connect (on_row_activated);
				var parser = Network.get_parser_from_inputstream (in_stream);

				Network.parse_array (parser, node => {
					var status = API.Status.from (node);
					if (status_id != null && status.id == status_id) return;
					status.spoiler_text = null;
					status.tuba_spoiler_revealed = true;
					status.sensitive = false;

					var widget_status = status.to_widget () as Widgets.Status;
					if (widget_status == null) return;

					var checkbutton = new Gtk.CheckButton () {
						css_classes = {"selection-mode"},
						valign = Gtk.Align.CENTER
					};
					status_buttons.set (status.id, checkbutton);

					widget_status.hexpand = true;
					widget_status.indicators.visible = false;
					widget_status.can_focus = false;
					widget_status.can_target = false;
					widget_status.focusable = false;
					widget_status.actions.visible = false;
					#if USE_LISTVIEW
						widget_status.can_be_opened = false;
					#else
						widget_status.activatable = false;
					#endif
					listbox.append (new StatusRow (checkbutton, widget_status));
				});

				if (status_buttons.size == 0) {
					page_3.visible = false;
					page_3_error.description = _("%s. You can continue with the report however.").printf (_("No posts found"));
					page_3_stack.visible_child_name = "error";

					return;
				}

				group_3.add (listbox);
				page_3_stack.visible_child_name = "main";
			})
			.on_error ((code, message) => {
				// translators: the variable is an error
				page_3_error.description = _("%s. You can continue with the report however.").printf (message);
				page_3_stack.visible_child_name = "error";
			})
			.exec ();
	}

	private void on_row_activated (Gtk.ListBoxRow row) {
		((StatusRow) row).toggle ();
	}

	private void on_category_set () {
		next_button.sensitive = true;

		check_buttons.foreach (e => {
			if (((Category) e.key) == Category.VIOLATION) {
				page_2.sensitive = ((Gtk.CheckButton) e.value).active;
				return false;
			}

			return true;
		});
	}

	private void on_rule_set () {
		rules_buttons.foreach (e => {
			if (((Gtk.CheckButton) e.value).active) {
				next_button.sensitive = true;
				return false;
			}

			next_button.sensitive = false;
			return true;
		});
	}
}
