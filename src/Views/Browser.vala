public class Tuba.Views.Browser : Adw.Bin {
	private class HeaderBar : Adw.Bin {
		~HeaderBar () {
			debug ("Destroying Browser HeaderBar");
		}

		Gdk.RGBA color;
		Adw.WindowTitle window_title;
		Gtk.Image ssl_icon;
		SimpleAction go_back_action;
		SimpleAction go_forward_action;

		private const GLib.ActionEntry[] ACTION_ENTRIES = {
			{"copy-url", on_copy_url},
			{"open-in-browser", on_open_in_browser},
			{"refresh", on_refresh}
		};

		public signal void refresh ();
		public signal void go_back ();
		public signal void go_forward ();
		public signal void exit ();

		public enum Security {
			SECURE,
			INSECURE,
			UNKNOWN;
		}

		private Security _security = Security.UNKNOWN;
		public Security security {
			get { return _security; }
			set {
				if (value != _security) {
					_security = value;
					switch (value) {
						case Security.UNKNOWN:
							ssl_icon.visible = false;
							return;
						case Security.SECURE:
							ssl_icon.icon_name = "tuba-padlock2-symbolic";
							ssl_icon.tooltip_text = _("Secure");
							break;
						default:
							ssl_icon.icon_name = "tuba-channel-insecure-symbolic";
							ssl_icon.tooltip_text = _("Insecure");
							break;
					}

					ssl_icon.visible = true;
				}
			}
		}

		public string title {
			get { return window_title.title; }
			set { window_title.title = value; }
		}

		public string subtitle {
			get { return window_title.subtitle; }
			set { window_title.subtitle = value; }
		}

		private double _progress = 0;
		public double progress {
			get {
				return _progress;
			}

			set {
				_progress = value;
				if (value == 1) _progress = 0;
				this.queue_draw ();
			}
		}

		public bool can_go_back {
			set {
				go_back_action.set_enabled (value);
			}
		}

		public bool can_go_forward {
			set {
				go_forward_action.set_enabled (value);
			}
		}

		public override void snapshot (Gtk.Snapshot snapshot) {
			snapshot.append_color (
				color,
				Graphene.Rect () {
					origin = Graphene.Point () {
						x = 0,
						y = 0
					},
					size = Graphene.Size () {
						height = this.get_height (),
						width = (float) (this.get_width () * this.progress)
					}
				}
			);

			base.snapshot (snapshot);
		}

		private void update_accent_color () {
			color = Adw.StyleManager.get_default ().get_accent_color_rgba ();
			color.alpha = 0.5f;
			if (progress != 0) this.queue_draw ();
		}

		construct {
			var default_sm = Adw.StyleManager.get_default ();
			if (default_sm.system_supports_accent_colors) {
				default_sm.notify["accent-color-rgba"].connect (update_accent_color);
				update_accent_color ();
			} else {
				color = {
					120 / 255.0f,
					174 / 255.0f,
					237 / 255.0f,
					0.5f
				};
			}

			window_title = new Adw.WindowTitle ("", "");
			var headerbar = new Adw.HeaderBar () {
				show_start_title_buttons = false,
				show_end_title_buttons = false,
				title_widget = window_title
			};

			var back_btn = new Gtk.Button.from_icon_name (is_rtl ? "tuba-right-large-symbolic" : "tuba-left-large-symbolic") {
				tooltip_text = _("Back")
			};
			back_btn.clicked.connect (on_exit);
			headerbar.pack_start (back_btn);

			ssl_icon = new Gtk.Image () {
				visible = false
			};
			headerbar.pack_start (ssl_icon);

			var actions = new GLib.SimpleActionGroup ();
			actions.add_action_entries (ACTION_ENTRIES, this);

			go_back_action = new SimpleAction ("go-back", null);
			go_back_action.activate.connect (on_go_back);
			go_back_action.set_enabled (false);
			actions.add_action (go_back_action);

			go_forward_action = new SimpleAction ("go-forward", null);
			go_forward_action.activate.connect (on_go_forward);
			go_forward_action.set_enabled (false);
			actions.add_action (go_forward_action);

			this.insert_action_group ("browser", actions);

			var sub_menu_model = new GLib.Menu ();
			var back_item = new GLib.MenuItem (_("Back"), "browser.go-back");
			back_item.set_attribute_value ("verb-icon", "tuba-left-large-symbolic");
			sub_menu_model.append_item (back_item);

			var refresh_item = new GLib.MenuItem (_("Refresh"), "browser.refresh");
			refresh_item.set_attribute_value ("verb-icon", "tuba-view-refresh-symbolic");
			sub_menu_model.append_item (refresh_item);

			var forward_item = new GLib.MenuItem (_("Forward"), "browser.go-forward");
			forward_item.set_attribute_value ("verb-icon", "tuba-right-large-symbolic");
			sub_menu_model.append_item (forward_item);

			var menu_section = new GLib.MenuItem.section (null, sub_menu_model);
			menu_section.set_attribute_value ("display-hint", "horizontal-buttons");

			var others_model = new GLib.Menu ();
			others_model.append (_("Open in Browser"), "browser.open-in-browser");
			others_model.append (_("Copy URL"), "browser.copy-url");

			var menu_model = new GLib.Menu ();
			menu_model.append_item (menu_section);
			menu_model.append_section (null, others_model);

			var menu_button = new Gtk.MenuButton () {
				icon_name = "view-more-symbolic",
				primary = true,
				menu_model = menu_model,
				tooltip_text = _("Menu")
			};
			headerbar.pack_end (menu_button);

			this.child = headerbar;
		}

		private void on_open_in_browser () {
			Host.open_url.begin (this.subtitle);
		}

		private void on_copy_url () {
			Host.copy (this.subtitle);
			app.toast (_("Copied url to clipboard"));
		}

		private void on_refresh () {
			refresh ();
		}

		private void on_go_back () {
			go_back ();
		}

		private void on_go_forward () {
			go_forward ();
		}

		private void on_exit () {
			exit ();
		}
	}

	const uint ANIMATION_DURATION = 250;
	public override void snapshot (Gtk.Snapshot snapshot) {
		var progress = this.animation.value;
		if (progress == 1.0) {
			base.snapshot (snapshot);
			return;
		}

		float width = (float) this.get_width ();
		snapshot.translate (Graphene.Point () {
			x = width - width * (float) progress,
			y = 0
		});
		base.snapshot (snapshot);
	}

	private void animation_target_cb (double value) {
		this.queue_draw ();
	}

	private void on_animation_end () {
		if (reveal_child) {
			this.grab_focus ();
		} else {
			exit ();
			animation = null; // leaks without
		}
	}

	private bool _reveal_child = false;
	public bool reveal_child {
		get {
			return _reveal_child;
		}

		set {
			if (_reveal_child == value) return;
			animation.value_from = animation.value;
			animation.value_to = value ? 1.0 : 0.0;

			_reveal_child = value;
			animation.play ();
			this.notify_property ("reveal-child");
		}
	}

	~Browser () {
		debug ("Destroying Browser");
	}

	WebKit.WebView webview;
	HeaderBar headerbar;
	Adw.TimedAnimation animation;

	public new bool grab_focus () {
		return this.webview.grab_focus ();
	}

	public signal void exit ();
	construct {
		var target = new Adw.CallbackAnimationTarget (animation_target_cb);
		animation = new Adw.TimedAnimation (this, 0.0, 1.0, ANIMATION_DURATION, target) {
			easing = Adw.Easing.EASE_IN_OUT_QUART
		};
		animation.done.connect (on_animation_end);

		this.webview = new WebKit.WebView () {
			vexpand = true,
			hexpand = true
		};

		WebKit.Settings webkit_settings = new WebKit.Settings () {
			default_font_family = Gtk.Settings.get_default ().gtk_font_name,
			allow_file_access_from_file_urls = false,
			allow_modal_dialogs = false,
			allow_universal_access_from_file_urls = false,
			auto_load_images = true,
			disable_web_security = true,
			javascript_can_open_windows_automatically = false,
			enable_developer_extras = false,
			enable_back_forward_navigation_gestures = true,
			enable_dns_prefetching = false,
			enable_fullscreen = true,
			enable_media = true,
			enable_media_capabilities = true,
			enable_mediasource = true,
			enable_site_specific_quirks = true,
			enable_webaudio = true,
			enable_webgl = true,
			enable_webrtc = false,
			enable_write_console_messages_to_stdout = false,
			javascript_can_access_clipboard = false,
			javascript_can_open_windows_automatically = false,
			enable_html5_database = true,
			enable_html5_local_storage = true,
			enable_smooth_scrolling = true,
			hardware_acceleration_policy = WebKit.HardwareAccelerationPolicy.NEVER
		};

		webkit_settings.set_user_agent_with_application_details (Build.NAME, Build.VERSION);
		webview.settings = webkit_settings;

		Gtk.GestureClick back_click_gesture = new Gtk.GestureClick () {
			button = 8
		};
		back_click_gesture.pressed.connect (on_go_back);
		webview.add_controller (back_click_gesture);

		Gtk.GestureClick forward_click_gesture = new Gtk.GestureClick () {
			button = 9
		};
		forward_click_gesture.pressed.connect (on_go_forward);
		webview.add_controller (forward_click_gesture);

		headerbar = new HeaderBar ();
		headerbar.go_back.connect (on_go_back);
		headerbar.refresh.connect (on_refresh);
		headerbar.go_forward.connect (on_go_forward);
		headerbar.exit.connect (on_exit);

		var toolbar_view = new Adw.ToolbarView () {
			css_classes = { "background" }
		};
		toolbar_view.add_top_bar (headerbar);

		this.webview.bind_property ("title", headerbar, "title", BindingFlags.SYNC_CREATE);
		this.webview.bind_property ("uri", headerbar, "subtitle", BindingFlags.SYNC_CREATE);
		this.webview.web_context.set_cache_model (WebKit.CacheModel.DOCUMENT_BROWSER);
		this.webview.bind_property ("estimated-load-progress", headerbar, "progress", BindingFlags.SYNC_CREATE);
		this.webview.load_changed.connect (on_load_changed);
		this.webview.network_session.download_started.connect (download_in_browser);
		this.webview.decide_policy.connect (open_new_tab_in_browser);
		this.webview.create.connect (on_create);

		toolbar_view.content = this.webview;
		this.child = toolbar_view;
	}

	protected virtual void on_load_changed (WebKit.LoadEvent load_event) {
		this.headerbar.can_go_forward = this.webview.can_go_forward ();
		this.headerbar.can_go_back = this.webview.can_go_back ();

		switch (load_event) {
			case WebKit.LoadEvent.FINISHED:
				GLib.TlsCertificateFlags tls_errors;
				bool secure = this.webview.get_tls_info (null, out tls_errors);
				headerbar.security = secure && tls_errors == NO_FLAGS
					? HeaderBar.Security.SECURE
					: HeaderBar.Security.INSECURE;
				break;
			default:
				headerbar.security = HeaderBar.Security.UNKNOWN;
				break;
		}
	}

	public static bool can_handle_uri (GLib.Uri uri) {
		return uri.get_scheme ().has_prefix ("http");
	}

	public static bool can_handle_url (string url) {
		return url.down ().has_prefix ("http");
	}

	public void load_url (string url) {
		this.webview.load_uri (url);
	}

	protected void download_in_browser (WebKit.Download download) {
		download.cancel ();
		Host.open_url.begin (download.get_request ().uri);
	}

	protected bool open_new_tab_in_browser (WebKit.PolicyDecision decision, WebKit.PolicyDecisionType type) {
		switch (type) {
			case WebKit.PolicyDecisionType.NEW_WINDOW_ACTION:
				WebKit.NavigationPolicyDecision navigation_decision = decision as WebKit.NavigationPolicyDecision;
				if (navigation_decision == null) return false;

				load_url (navigation_decision.navigation_action.get_request ().uri);
				navigation_decision.ignore ();
				return true;
			case WebKit.PolicyDecisionType.RESPONSE:
				WebKit.ResponsePolicyDecision response_decision = decision as WebKit.ResponsePolicyDecision;
				if (
					response_decision == null
					|| response_decision.is_mime_type_supported ()
					|| response_decision.response.mime_type.has_prefix ("text/")
				) return false;

				Host.open_url.begin (response_decision.request.uri);
				response_decision.ignore ();
				return true;
			default:
				return false;
		}
	}

	protected Gtk.Widget on_create (WebKit.NavigationAction navigation_action) {
		Host.open_url.begin (navigation_action.get_request ().get_uri ());

		// According to the docs, we should return null if
		// we are not creating a new WebView, but the vapi
		// requires a Gtk.Widget. So this is purposely
		// returning null even though it claims to return
		// a Gtk.Widget.
		return (Gtk.Widget) null;
	}

	private void on_go_back () {
		this.webview.go_back ();
	}

	private void on_refresh () {
		this.webview.reload ();
	}

	private void on_go_forward () {
		this.webview.go_forward ();
	}

	private void on_exit () {
		this.reveal_child = false;
	}
}
