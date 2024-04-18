// LabelWithWidgets is ported from Fractal
// https://gitlab.gnome.org/GNOME/fractal/-/blob/3f8a7e8bd06441d83a5f052a2ae68d7d228dfcd0/src/components/label_with_widgets.rs

// How to use:
// Set `text` to the label's content but use the `placeholder` keyword where widgets should be placed.
// Then use `set_children` with an array of Widgets in order of how they should be placed in the label.
// There are some helper functions like `append_child` to add children and
// `LabelWithWidgets.with_label_and_widgets` to construct it with the desired text and widgets.

public class Tuba.Widgets.LabelWithWidgets : Gtk.Widget, Gtk.Buildable, Gtk.Accessible {
    struct LWWWidget {
        public Gtk.Widget widget;
        public int height;
        public int width;
    }

    private LWWWidget[] widgets = {};
    public Gtk.Label label;

    private string _placeholder = "<widget>";
    public string placeholder {
        get {
            return _placeholder;
        }
        set {
            _placeholder = value;
            update_label ();
        }
    }

    private string _label_text = "";
    private string _text = "";
    public string text {
        get {
            return _text;
        }
        set {
            _text = value;
            update_label ();
            label.notify_property ("label");
        }
    }

    private bool _use_markup = false;
    public bool use_markup {
        get {
            return _use_markup;
        }
        set {
            if (_use_markup == value) return;

            _use_markup = value;
            label.use_markup = _use_markup;
        }
    }

    private bool _fix_overflow_hack = false;
    public bool fix_overflow_hack {
        get {
            return fix_overflow_hack;
        }
        set {
            _fix_overflow_hack = value;
            update_label ();
        }
    }

    const string OBJECT_REPLACEMENT_CHARACTER = "\xEF\xBF\xBC";

    construct {
        label = new Gtk.Label ("") {
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            xalign = 0.0f,
            valign = Gtk.Align.START,
            use_markup = false,
            ellipsize = Pango.EllipsizeMode.NONE
            //  css_classes = {"lww-line-height"}
        };

        label.set_parent (this);

        label.activate_link.connect ((url) => activate_link (url));
    }
    ~LabelWithWidgets () {
        label.unparent ();
        foreach (var child in widgets) {
            child.widget.unparent ();
        }
    }

    private void allocate_shapes () {
        var child_size_changed = false;

        if (text == "") return;
        if (widgets.length == 0) {
            label.attributes = null;
            return;
        }

        for (var i = 0; i < widgets.length; i++) {
            Gtk.Requisition size;
            Gtk.Requisition natural_size;
            widgets[i].widget.get_preferred_size (out size, out natural_size);
            int width = natural_size.width;
            int height = natural_size.height;

            int old_width = widgets[i].width;
            int old_height = widgets[i].height;
            if (old_width > 0 || old_height > 0) {
                if (old_width != width || old_height != height) {
                    widgets[i].width = width;
                    widgets[i].height = height;

                    child_size_changed = true;
                }
            } else {
                widgets[i].width = width;
                widgets[i].height = height;

                child_size_changed = true;
            }
        }


        if (!child_size_changed) {
            return;
        }

        var attrs = new Pango.AttrList ();
        int index = 0;

        for (var i = 0; i < widgets.length; i++) {
            index = _label_text.index_of (OBJECT_REPLACEMENT_CHARACTER, index);
            if (index < 0) break;

            var logical_rect = Pango.Rectangle () {
                x = 0,
                y = - (widgets[i].height - (widgets[i].height / 4)) * Pango.SCALE,
                width = widgets[i].width * Pango.SCALE,
                height = widgets[i].height * Pango.SCALE
            };

            var shape = Pango.AttrShape.new (logical_rect, logical_rect);
            shape.start_index = index;
            shape.end_index = index + OBJECT_REPLACEMENT_CHARACTER.length;
            attrs.insert (shape.copy ());

            index = index + OBJECT_REPLACEMENT_CHARACTER.length;
        }

        label.attributes = attrs;
    }

    private void allocate_children () {
        if (widgets.length == 0) return;

        var run_iter = label.get_layout ().get_iter ();
        int i = 0;

        while (true) {
            var run = run_iter.get_run_readonly ();
            if (run != null) {
                var extra_attrs = run.item.analysis.extra_attrs.copy ();
                bool has_shape_attr = false;
                foreach (var attr in extra_attrs) {
                    if (((Pango.Attribute) attr).as_shape () != null) {
                        has_shape_attr = true;
                        break;
                    }
                }

                if (has_shape_attr) {
                    if (i < widgets.length) {
                        Pango.Rectangle logical_rect;
                        run_iter.get_run_extents (null, out logical_rect);

                        //  int orig_x = logical_rect.x;
                        //  int orig_y = logical_rect.y;
                        logical_rect.x = pango_pixels (logical_rect.x);
                        logical_rect.y = pango_pixels (logical_rect.y);
                        //  logical_rect.width = pango_pixels (orig_x + logical_rect.width, 1024) - logical_rect.x;
                        //  logical_rect.height = pango_pixels (orig_y + logical_rect.height, 1024) - logical_rect.y;

                        int offset_x;
                        int offset_y;
                        label.get_layout_offsets (out offset_x, out offset_y);

                        var allocation = Gtk.Allocation () {
                            x = logical_rect.x + offset_x,
                            y = logical_rect.y + offset_y,
                            height = widgets[i].height,
                            width = widgets[i].width
                        };
                        widgets[i].widget.allocate_size (allocation, -1);
                        i++;
                    } else {
                        break;
                    }
                }
            }

            if (!run_iter.next_run ()) {
                break;
            }
        }
    }

    public override void size_allocate (int width, int height, int baseline) {
        label.allocate (width, height, baseline, null);
        this.allocate_children ();
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return label.get_request_mode ();
    }

    public override void measure (
        Gtk.Orientation orientation,
        int for_size,
        out int minimum,
        out int natural,
        out int minimum_baseline,
        out int natural_baseline
    ) {
        this.allocate_shapes ();
        this.label.measure (
            orientation,
            for_size,
            out minimum,
            out natural,
            out minimum_baseline,
            out natural_baseline
        );
    }

    private void update_label () {
        var old_label = label.label;
        var new_label = _text.replace (placeholder, OBJECT_REPLACEMENT_CHARACTER);

        if (_fix_overflow_hack) {
            label.set_property ("nat-lines", 20); //int.max (100, widgets.length);
            label.ellipsize = Pango.EllipsizeMode.END;
            //  label.width_chars = label.max_width_chars = 1;
        }

        if (old_label != new_label) {
            label.wrap = true;
            label.wrap_mode = Pango.WrapMode.WORD_CHAR;

            _text = new_label;
            label.label = _text;
            _label_text = label.get_text ();
            invalidate_child_widgets ();
        }
    }

    public void append_child (Gtk.Widget child) {
        widgets += LWWWidget () {
            widget = child,
            width = 0,
            height = 0
        };
        child.set_parent (this);
        invalidate_child_widgets ();
    }

    public LabelWithWidgets.with_label_and_widgets (string t_text, Gtk.Widget[] t_widgets) {
        Object ();

        foreach (unowned Gtk.Widget widget in t_widgets) {
            append_child (widget);
        }

        this.text = t_text;
    }

    public void set_children (Gtk.Widget[] t_widgets) {
        foreach (var child in widgets) {
            child.widget.unparent ();
            child.widget.destroy ();
        }
        widgets = {};
        foreach (unowned Gtk.Widget widget in t_widgets) {
            append_child (widget);
        }
    }

    private void invalidate_child_widgets () {
        for (var i = 0; i < widgets.length; i++) {
            widgets[i].width = 0;
            widgets[i].height = 0;
        }
        this.allocate_shapes ();
        this.queue_resize ();
    }

    private int pango_pixels (int d, int a = 0) {
        return (d + a) >> 10;
    }

    public void add_child (Gtk.Builder builder, GLib.Object child, string? type) {
        Gtk.Widget widget = child as Gtk.Widget;
        if (widget != null) {
            this.append_child (widget);
        } else {
            this.parent.add_child (builder, child, type);
        }

        base.add_child (builder, child, type);
    }

    public signal bool activate_link (string uri);

    public bool single_line_mode {
		get { return label.single_line_mode; }
		set { label.single_line_mode = value; }
	}

	public float xalign {
        get { return label.xalign; }
        set { label.xalign = value; }
	}

    public bool selectable {
        get { return label.selectable; }
        set { label.selectable = value; }
	}

    public int lines {
        get { return label.lines; }
        set { label.lines = value; }
	}

    public Gtk.Justification justify {
        get { return label.justify; }
        set { label.justify = value; }
	}
}
