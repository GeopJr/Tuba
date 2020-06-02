using Gtk;

public class Tootle.Views.ExpandedStatus : Views.Base, IAccountListener {

    public API.Status root_status { get; construct set; }
    protected InstanceAccount? account = null;
    protected Widgets.Status root_widget;

    public ExpandedStatus (API.Status status) {
        Object (root_status: status, state: "content");

        root_widget = append (status);
        root_widget.avatar.button_press_event.connect (root_widget.on_avatar_clicked);
        connect_account ();
    }

   public override void on_account_changed (InstanceAccount? acc) {
        account = acc;
        request ();
    }

    private Widgets.Status prepend (API.Status status, bool to_end = false){
        var w = new Widgets.Status (status);
        w.avatar.button_press_event.connect (w.on_avatar_clicked);
        w.revealer.reveal_child = true;

		if (to_end)
			content_list.insert (w, -1);
		else
			content_list.prepend (w);

        check_resize ();
        return w;
    }
    private Widgets.Status append (API.Status status) {
    	return prepend (status, true);
    }

    public void request () {
        new Request.GET (@"/api/v1/statuses/$(root_status.id)/context")
            .with_account (account)
            .then_parse_obj (root => {
                if (scrolled == null) return;

                var ancestors = root.get_array_member ("ancestors");
                ancestors.foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null) {
                        var status = new API.Status (object);
                        prepend (status);
                    }
                });

                var descendants = root.get_array_member ("descendants");
                descendants.foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null) {
                        var status = new API.Status (object);
                        append (status);
                    }
                });

                int x,y;
                translate_coordinates (root_widget, 0, 0, out x, out y);
                scrolled.vadjustment.value = (double)(y*-1); //TODO: Animate scrolling?
                //content_list.select_row (root_widget);
            })
            .exec ();
    }

    public static void open_from_link (string q) {
        new Request.GET ("/api/v1/search")
            .with_account ()
            .with_param ("q", q)
            .with_param ("resolve", "true")
            .then ((sess, msg) => {
                var root = network.parse (msg);
                var statuses = root.get_array_member ("statuses");
                var object = statuses.get_element (0).get_object ();
                if (object != null){
                    var status = new API.Status (object);
                    window.open_view (new Views.ExpandedStatus (status));
                }
                else
                    Desktop.open_uri (q);
            })
            .exec ();
    }

}
