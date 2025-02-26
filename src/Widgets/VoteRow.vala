public class Tuba.Widgets.VoteRow : Gtk.ListBoxRow {
	const uint ANIMATION_DURATION = 500;

	Adw.SpringAnimation animation;
	Widgets.EmojiLabel title_label;
	Gtk.Label subtitle_label;
	Gtk.Box main_box;
	Gtk.Image voted_icon;

	public Widgets.VoteCheckButton check_button { get; private set; }
	public bool delayed_animation { get; set; default = false; }

	private bool _winner = false;
	public bool winner {
		get { return _winner; }
		set {
			if (_winner != value) {
				_winner = value;
				this.queue_draw ();
			}
		}
	}

	private double _percentage = -1;
	public double percentage {
		get { return _percentage; }
		set {
			if (value != _percentage) {
				double before = _percentage / 100;

				_percentage = value;
				this.subtitle_label.label = "%.1f%%".printf (percentage);

				animate (double.min (before, 0));
			}
		}
	}

	public Gee.HashMap<string, string>? instance_emojis {
		set {
			this.title_label.instance_emojis = value;
			if (this.title != "") this.title_label.content = this.title;
		}
	}

	private string _title = "";
	public string title {
		get { return _title; }
		set {
			if (value != _title) {
				_title = value;
				this.title_label.content = value;
			}
		}
	}

	private bool _voted = false;
	public bool voted {
		get { return _voted; }
		set {
			if (_voted != value) {
				_voted = value;
				this.voted_icon.visible = value;
				this.show_results = true;
			}
		}
	}

	private bool _show_results = false;
	public bool show_results {
		get { return _show_results; }
		set {
			if (_show_results != value) {
				_show_results = value;
				this.check_button.visible = !value;
				this.subtitle_label.visible = value && this.subtitle_label.label != "";
				this.voted_icon.visible = this.voted;
				this.activatable = !value;

				animate (0);
			}
		}
	}

	private Gdk.RGBA _background_color = {
		120 / 255.0f,
		174 / 255.0f,
		237 / 255.0f,
		0.5f
	};
	private Gdk.RGBA background_color {
		get { return _background_color; }
		set {
			value.alpha = 0.5f;
			_background_color = value;
			if (this.winner) this.queue_draw ();
		}
	}

	private void animation_target_cb (double value) {
		this.queue_draw ();
	}

	private void animate (double from, double to = this.percentage / 100) {
		animation.value_from = from;
		animation.value_to = to;

		if (!delayed_animation) play_animation ();
	}

	public void play_animation () {
		this.animation.play ();
	}

	private void update_accent_color () {
		background_color = Adw.StyleManager.get_default ().get_accent_color_rgba ();
	}

	construct {
		this.add_css_class ("ttl-poll-row");
		this.activatable = true;
		this.vexpand = true;

		check_button = new Widgets.VoteCheckButton ();
		var target = new Adw.CallbackAnimationTarget (animation_target_cb);
		animation = new Adw.SpringAnimation (this, 0.0, 1.0, new Adw.SpringParams (0.65, 0.4, 110.0), target);

		var default_sm = Adw.StyleManager.get_default ();
		if (default_sm.system_supports_accent_colors) {
			default_sm.notify["accent-color-rgba"].connect (update_accent_color);
			_background_color = default_sm.get_accent_color_rgba ();
			_background_color.alpha = 0.5f;
		}

		this.title_label = new Widgets.EmojiLabel () {
			use_markup = false,
			xalign = 0.0f,
			vexpand = true,
			valign = Gtk.Align.CENTER
		};
		this.subtitle_label = new Gtk.Label ("") {
			visible = false,
			xalign = 0.0f,
			css_classes = {"dim-label"}
		};
		this.voted_icon = new Gtk.Image.from_icon_name ("tuba-check-round-outline-symbolic") {
			tooltip_text = "Voted",
			vexpand = true,
			valign = Gtk.Align.CENTER,
			visible = false
		};

		var title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			hexpand = true,
			margin_top = 6,
			margin_bottom = 6
		};
		title_box.append (title_label);
		title_box.append (subtitle_label);

		this.main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
			margin_top = 2,
			margin_bottom = 2,
			margin_start = 14,
			margin_end = 14,
			height_request = 50
		};
		this.main_box.append (check_button);
		this.main_box.append (title_box);
		this.main_box.append (voted_icon);

		this.child = main_box;
	}

	public VoteRow (string poll_title) {
		this.check_button.poll_title = poll_title;
	}

	public override void snapshot (Gtk.Snapshot snapshot) {
		if (!show_results) {
			base.snapshot (snapshot);
			return;
		}

		int width = this.get_width ();
		Graphene.Rect bar = Graphene.Rect () {
			origin = Graphene.Point () {
				x = 0.0f,
				y = 0.0f
			},
			size = Graphene.Size () {
				height = (float) this.get_height (),
				width = (float) width * (float) this.animation.value
			}
		};

		if (this.winner) {
			snapshot.append_color (this.background_color, bar);
		} else {
			var color = this.get_color ();
			color.alpha = 0.2f;
			snapshot.append_color (color, bar);
		}
		base.snapshot (snapshot);
	}
}
