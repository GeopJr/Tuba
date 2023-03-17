// LabelWithWidgets is ported from Fractal
// https://gitlab.gnome.org/GNOME/fractal/-/blob/40d2071975e20c1c936f7e87daaf8a0eba7f31b7/src/components/label_with_widgets.rs

public class LabelWithWidgets : Gtk.Buildable, Gtk.Widget {
    private Gtk.Widget[] widgets = {};
    private int[] widget_heights = {};
    private int[] widget_widths = {};
    
    public Gtk.Label label;
    
    private string _placeholder = "<widget>";
    public string placeholder {
        get {
            return _placeholder;
        }
        set {
            _placeholder = value;
            update_label();
        }
    }
    
    private string _text = "";
    public string text {
        get {
            return _text;
        }
        set {
            _text = value;
            update_label();
            notify_property("label");
        }
    }
    
    private bool _ellipsize = false;
    public bool ellipsize {
        get {
            return _ellipsize;
        }
        set {
            _ellipsize = value;
            update_label();
        }
    }
    
    private bool _use_markup = false;
    public bool use_markup {
        get {
            return _use_markup;
        }
        set {
            _use_markup = value;
            label.use_markup = _use_markup;
        }
    }
    
    const string OBJECT_REPLACEMENT_CHARACTER = "​";
    const int PANGO_SCALE = 1024;
    
    construct {
        label = new Gtk.Label("") {
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            xalign = 0.0f,
            valign = Gtk.Align.START,
            //  css_classes = {"line-height"}
        };

        label.set_parent(this);

        label.notify["label"].connect(() => {
            invalidate_child_widgets();
        });        
    }
    ~LabelWithWidgets (){
        label.unparent();
        foreach (var child in widgets) {
            child.unparent();
        }
    }
    
    private void allocate_shapes() {
        var child_size_changed = false;

        for (var i = 0; i < widgets.length; i++) {
            Gtk.Widget child = widgets[i];
            Gtk.Requisition size;
            Gtk.Requisition natural_size;
            child.get_preferred_size(out size, out natural_size);
            int width = natural_size.width;
            int height = natural_size.height;

            if (widget_widths.length > 0) {
                int old_width = widget_widths[i];
                int old_height = widget_heights[i];
                if (old_width != width || old_height != height) {
                    widget_widths[i] = width;
                    widget_heights[i] = height;

                    child_size_changed = true;
                }
            } else {
                widget_widths[i] = width;
                widget_heights[i] = height;

                child_size_changed = true;
            }
        }


        if (!child_size_changed) {
            return;
        }

        var attrs = new Pango.AttrList();
        int index = 0;

        for (var i = 0; i < widget_widths.length; i++) {
            index = text.index_of (OBJECT_REPLACEMENT_CHARACTER, index);
            if (index < 0) break;

            var width = widget_widths[i];
            var height = widget_heights[i];
            var logical_rect = Pango.Rectangle() {
                x = 0,
                y = -(height - (height / 4)) * PANGO_SCALE,
                width = width * PANGO_SCALE,
                height = height * PANGO_SCALE
            };
    
            var shape = Pango.AttrShape.new(logical_rect, logical_rect);
            shape.start_index = index;
            shape.end_index = index + OBJECT_REPLACEMENT_CHARACTER.length;
            attrs.insert(shape.copy());
    
            index = index + 1;
        }

        label.attributes = attrs;
    }
    
    private void allocate_children () {
        var run_iter = label.get_layout ().get_iter ();
        int i = 0;

        while (true) {
            var run = run_iter.get_run_readonly ();
            if (run == null) {
                break;
            }
    
            var extra_attrs = run.item.analysis.extra_attrs.copy();
            bool has_shape_attr = false;
            foreach (var attr in extra_attrs) {
                // FIXME
                if (true) {
                    has_shape_attr = true;
                    break;
                }
            }
    
            if (has_shape_attr) {
                if (i < widgets.length) {
                    var widget = widgets[i];
                    var width = widget_widths[i];
                    var height = widget_heights[i];
    
                    Pango.Rectangle ink_rect;
                    Pango.Rectangle logical_rect;
                    run_iter.get_run_extents (out ink_rect, out logical_rect);
    
                    int offset_x;
                    int offset_y;
                    label.get_layout_offsets (out offset_x, out offset_y);
    
                    var allocation = Gtk.Allocation () {
                        x = pango_pixels (logical_rect.x) + offset_x,
                        y = pango_pixels (logical_rect.y) + offset_y,
                        height = width,
                        width = height
                    };
                    widget.allocate_size (allocation, -1);
                    i++;
                } else {
                    break;
                }
            }
    
            if (!run_iter.next_run ()) {
                break;
            }
        }
    }
    
    public override void size_allocate(int width, int height, int baseline) {
        // The order of the widget allocation is important.
        allocate_shapes();
        label.allocate(width, height, baseline, null);
        allocate_children();
    }
    
    public override Gtk.SizeRequestMode get_request_mode() {
        return label.get_request_mode();
    }
    
    public override void measure(Gtk.Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
        int t_minimum = -1;
        int t_natural = -1;
        int t_minimum_baseline = -1;
        int t_natural_baseline = -1;

        minimum = -1;
        natural = -1;
        minimum_baseline = -1;
        natural_baseline = -1;
    
        if (label.should_layout()) {
            label.measure(orientation, for_size, out t_minimum, out t_natural, out t_minimum_baseline, out t_natural_baseline);
        }
    
        foreach (var child in widgets){
            if (label.should_layout()) {
                int child_min = -1;
                int child_nat = -1;
                int child_min_baseline = -1;
                int child_nat_baseline = -1;
    
                child.measure(orientation, for_size, out child_min, out child_nat, out child_min_baseline, out child_nat_baseline);
    
                minimum = int.max(t_minimum, child_min);
                natural = int.max(t_natural, child_nat);
    
                if (child_min_baseline > -1) {
                    minimum_baseline = int.max(t_minimum_baseline, child_min_baseline);
                }
                if (child_nat_baseline > -1) {
                    natural_baseline = int.max(t_natural_baseline, child_nat_baseline);
                }
            }
	    }
    }
    
    public void update_label() {
        if (this.ellipsize) {
            // Workaround: if both wrap and ellipsize are set, and there are
            // widgets inserted, GtkLabel reports an erroneous minimum width.
            label.wrap = false;
            label.ellipsize = Pango.EllipsizeMode.END;
    
            if (text != null) {
                _text = _text.replace(placeholder, OBJECT_REPLACEMENT_CHARACTER);
                int pos = _text.index_of_char('\n');
                if (pos >= 0) {
                    _text = _text.substring(0, pos) + "…";
                }
                label.label = _text;
            }
        } else {
            label.wrap = true;
            label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            label.ellipsize = Pango.EllipsizeMode.NONE;
    
            if (text != null) {
                _text = _text.replace(placeholder, OBJECT_REPLACEMENT_CHARACTER);
                label.label = _text;
            }
        }
    
        invalidate_child_widgets();
    }
    
    public void append_child(Gtk.Widget child) {
        widgets += child;
        widget_widths += 0;
        widget_heights += 0;
    
        child.set_parent(this);
    
        invalidate_child_widgets();
    }
    
    public LabelWithWidgets.with_label_and_widgets(string t_text, Gtk.Widget[] t_widgets) {
        Object ();
    
        foreach (unowned Gtk.Widget widget in t_widgets) {
            append_child(widget);
        }

        this.text = t_text;
    }
    
    private void invalidate_child_widgets() {
        for (var i = 0; i < widget_widths.length; i++) {
            widget_widths[i] = 0;
            widget_heights[i] = 0;
        }
        this.queue_resize();
    }
    
    public int pango_pixels(int d) {
        return (d + 512) >> 10;
    }

    public void add_child(Gtk.Builder builder, GLib.Object child, string? type) {
        Gtk.Widget widget = child as Gtk.Widget;
        if (widget != null) {
            this.append_child(widget);
        } else {
            this.parent.add_child(builder, child, type);
        }

        base.add_child (builder, child, type);
    }
}