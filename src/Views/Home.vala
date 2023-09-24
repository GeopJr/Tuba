public class Tuba.Views.Home : Views.Timeline {
    Gtk.Revealer compose_button_rev;
    construct {
        url = "/api/v1/timelines/home";
        label = _("Home");
        icon = "user-home-symbolic";

        scroll_to_top_rev.margin_end = 32;
        scroll_to_top_rev.margin_bottom = 24;
        scroll_to_top_rev.add_css_class ("scroll-to-top-btn");

        compose_button_rev = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            valign = halign = Gtk.Align.END,
            margin_end = 24,
            reveal_child = true,
            child = new Gtk.Button.from_icon_name ("document-edit-symbolic") {
                action_name = "app.compose",
                tooltip_text = _("Compose"),
                css_classes = { "circular", "compose-button", "suggested-action" },
                margin_bottom = 24
            }
        };

        compose_button_rev.notify["reveal-child"].connect (toggle_scroll_to_top_margin);
        toggle_scroll_to_top_margin ();

        scrolled_overlay.add_overlay (compose_button_rev);

        #if DEV_MODE
            app.dev_new_post.connect (node => {
                try {
                    model.insert (0, Entity.from_json (accepts, node));
                } catch (Error e) {
                    warning (@"Error getting Entity from json: $(e.message)");
                }
            });
        #endif
    }

    void toggle_scroll_to_top_margin () {
        Tuba.toggle_css (scroll_to_top_rev, compose_button_rev.reveal_child, "composer-btn-revealed");
    }

    double last_adjustment = 0;
    double show_on_adjustment = -1;
    bool last_direction_down = false;
    protected override void on_scrolled_vadjustment_value_change () {
        base.on_scrolled_vadjustment_value_change ();

        double trunced = Math.trunc (scrolled.vadjustment.value);
        bool direction_down = trunced == last_adjustment ? last_direction_down : trunced > last_adjustment;
        last_direction_down = direction_down;

        if (!direction_down && show_on_adjustment == -1) {
            show_on_adjustment = last_adjustment - 200;
            if (show_on_adjustment <= 0) show_on_adjustment = last_adjustment;
        } else if (direction_down) {
            show_on_adjustment = -1;
        }

        if (compose_button_rev.reveal_child && direction_down)
            compose_button_rev.reveal_child = false;
        else if (!compose_button_rev.reveal_child && !direction_down && trunced <= show_on_adjustment)
            compose_button_rev.reveal_child = true;

        last_adjustment = trunced;
    }

    public override string? get_stream_url () {
        return account != null
            ? @"$(account.instance)/api/v1/streaming/?stream=user&access_token=$(account.access_token)"
            : null;
    }
}
