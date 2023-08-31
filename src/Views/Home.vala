public class Tuba.Views.Home : Views.Timeline {
    Gtk.Revealer compose_button_rev;
    construct {
        url = "/api/v1/timelines/home";
        label = _("Home");
        icon = "tuba-home-symbolic";

        scroll_to_top_rev.margin_end = 32;
        scroll_to_top_rev.margin_bottom = 80;

        compose_button_rev = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            valign = halign = Gtk.Align.END,
            margin_end = margin_bottom = 24,
            reveal_child = true,
            child = new Gtk.Button.from_icon_name ("document-edit-symbolic") {
                action_name = "app.compose",
                tooltip_text = _("Compose"),
                css_classes = { "circular", "compose-button", "suggested-action" }
            }
        };

		compose_button_rev.bind_property ("reveal-child", scroll_to_top_rev, "margin-bottom", GLib.BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_int (src.get_boolean () ? 80 : 24);

			return true;
		});

        scrolled_overlay.add_overlay (compose_button_rev);
    }

    double last_adjustment = 0.0;
    protected override void on_scrolled_vadjustment_value_change () {
        base.on_scrolled_vadjustment_value_change ();

        if (scrolled.vadjustment.value > 1000)
            compose_button_rev.reveal_child = scrolled.vadjustment.value + scrolled.vadjustment.page_size + 100 < scrolled.vadjustment.upper;
        last_adjustment = scrolled.vadjustment.value;
    }

    public override string? get_stream_url () {
        return account != null
            ? @"$(account.instance)/api/v1/streaming/?stream=user&access_token=$(account.access_token)"
            : null;
    }
}
