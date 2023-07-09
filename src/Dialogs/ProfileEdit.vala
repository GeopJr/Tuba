public class Tuba.Dialogs.ProfileEdit : Adw.Window {
    public class Field : Adw.ExpanderRow {
        Adw.EntryRow key_row;
        Adw.EntryRow value_row;

        public string key {
            get {
                return key_row.text ?? "";
            }
        }

        public string value {
            get {
                return value_row.text ?? "";
            }
        }

        public bool valid {
            get {
                // TODO: Max length
                return key.length > 0 && value.length > 0;
            }
        }

        public Field (string? t_key, string? t_value) {
            expanded = t_key != null || t_value != null;
            key_row = new Adw.EntryRow () {
                //  input_purpose = InputPurpose.FREE_FORM,
                title = _("Label"),
                text = t_key ?? ""
            };
            key_row.changed.connect (update_valid_style);

            value_row = new Adw.EntryRow () {
                //  input_purpose = InputPurpose.FREE_FORM,
                title = _("Content"),
                text = t_value ?? ""
            };
            value_row.changed.connect (update_valid_style);

            add_row (key_row);
            add_row (value_row);
            update_valid_style ();
        }

        void update_valid_style () {
            if (valid) {
                remove_css_class ("error");
            } else {
                add_css_class ("error");
            }
        }
    }

    private Widgets.Avatar avi { get; set; }
    private Adw.EntryRow name_row { get; set; }
    private Adw.EntryRow bio_row { get; set; }
    private Gtk.ListBox fields_box { get; set; }

    construct {
        title = _("Edit Profile");
        modal = true;
        transient_for = app.main_window;
        default_width = 460;
        default_height = 520;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);

        avi = new Widgets.Avatar () {
            size = 120
        };

        var profile_info_box = new Gtk.ListBox () {
            css_classes = { "boxed-list" },
            selection_mode = Gtk.SelectionMode.NONE
        };

        name_row = new Adw.EntryRow () {
            //  input_purpose = InputPurpose.FREE_FORM,
            title = _("Display Name")
        };

        bio_row = new Adw.EntryRow () {
            //  input_purpose = InputPurpose.FREE_FORM,
            title = _("Bio")
        };

        profile_info_box.append (name_row);
        profile_info_box.append (bio_row);

        fields_box = new Gtk.ListBox () {
            css_classes = { "boxed-list" },
            selection_mode = Gtk.SelectionMode.NONE
        };

        content_box.append (avi);
        content_box.append (profile_info_box);
        content_box.append (fields_box);

        var clamp = new Adw.Clamp () {
            child = content_box,
            tightening_threshold = 100,
            valign = Gtk.Align.START
        };
        var scroller = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true
        };
        scroller.child = clamp;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        var headerbar = new Adw.HeaderBar ();

        box.append (headerbar);
        box.append (scroller);

        content = box;
    }

	Gee.ArrayList<Field> fields = new Gee.ArrayList<Field> ();
    public ProfileEdit (API.Account acc) {
        // TODO header image
        // TODO overlay
        avi.account = acc;
        name_row.text = acc.display_name;
        bio_row.text = acc?.source?.note ?? "";

        // TODO
        // No way to know how many on masto+glitch, I think *oma has a config
        var guess_amount = acc?.source?.fields?.size > 4 ? acc.source.fields.size : 4;
        
        // add known
        if (acc?.source?.fields?.size > 0) {
            for (var i = 0; i < acc.source.fields.size; i++) {
                var field = acc.source.fields.get (i);
                add_field (field.name, field.val);
            }
        }
        
        var fields_left = guess_amount - (acc?.source?.fields?.size ?? 0);
        if (fields_left > 0) {
            for (var i = 0; i < fields_left; i++) {
                add_field (null, null);
            }
        }
    }

    private void add_field (string? key, string? value) {
        var field = new Field (key, value);
        field.title = _("Field %d").printf (fields.size + 1);

        fields.add (field);
        fields_box.append (field);
    }
}