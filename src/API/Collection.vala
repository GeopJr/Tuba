public class Tuba.API.WrappedCollection : Entity {
	public API.Collection collection { get; set; }
}

public class Tuba.API.WrappedCollectionItem : Entity {
	public API.Collection.Item collection_item { get; set; }
}

public class Tuba.API.Collections : Entity {
	public Gee.ArrayList<API.Collection> collections { get; set; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "collections":
				return typeof (API.Collection);
		}

		return base.deserialize_array_type (prop);
	}

	public static Collections from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Collections), node) as API.Collections;
	}
}

public class Tuba.API.Collection : Entity, Widgetizable {
	public class Tag : Entity {
		public string name { get; set; }
		public string url { get; set; }
	}

	public class Item : Entity {
		public string id { get; set; }
		public string account_id { get; set; }
		public string state { get; set; }
	}

	public string id { get; set; }
	public string account_id { get; set; }
	public string? url { get; set; default=null; }
	public string name { get; set; }
	public string description { get; set; }
	public bool sensitive { get; set; default=false; }
	public bool discoverable { get; set; default=false; }
	public string language { get; set; default="en"; }
	public string updated_at { get; set; }
	public Tag? tag { get; set; default=null; }
	public int32 item_count { get; set; default=1; }
	public Gee.ArrayList<API.Collection.Item>? items { get; set; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "items":
				return typeof (API.Collection.Item);
		}

		return base.deserialize_array_type (prop);
	}

	public override Gtk.Widget to_widget () {
		return new Widgets.CollectionRow (this);
	}

	public override void open () {
		(new Dialogs.Collection (this)).present (app.main_window);
	}
}
