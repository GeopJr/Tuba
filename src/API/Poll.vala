using Gee;
using Json;

public class Tooth.API.Poll : GLib.Object, Json.Serializable{
    public string id { get; set; }
    public string expires_at{ get; set; }
    public bool expired { get; set; }
    public bool multiple { get; set; }
    public int64 votes_count { get; set; }
    public bool voted { get; set; default = true;}
    public ArrayList<int> own_votes { get; set; }
    public ArrayList<PollOption>? options{ get; set; default = null; }

    public Poll (string _id) {
        id = _id;
    }

	public override bool deserialize_property (string prop, out Value val, ParamSpec spec, Json.Node node) {
		var success = default_deserialize_property (prop, out val, spec, node);

		//  var type = spec.value_type;
		if (prop=="options"){
		    return Entity.des_list (out val, node, typeof (API.PollOption));
		}
		if (prop=="own-votes"){
		    return Poll.des_list_int (out val, node);
		}
		return success;
	}
	public static bool des_list_int (out Value val, Json.Node node) {
		var arr = new Gee.ArrayList<int> ();
		if (!node.is_null ()) {
			node.get_array ().foreach_element ((array, i, elem) => {
				arr.add ((int)elem.get_int());
			});
		}
		val = arr;
		return true;
	}
	public static Poll from_json (Type type, Json.Node? node) throws Oopsie {
        if (node == null)
            throw new Oopsie.PARSING (@"Received Json.Node for $(type.name ()) is null!");

        var obj = node.get_object ();
        if (obj == null)
            throw new Oopsie.PARSING (@"Received Json.Node for $(type.name ()) is not a Json.Object!");

        return Json.gobject_deserialize (type, node) as Poll;
	}
    public static Request vote (InstanceAccount acc,ArrayList<PollOption> options,ArrayList<string> selection, string id) {
 		message (@"Voting poll $(id)...");
 		  //Creating json to send
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("choices");
        builder.begin_array ();
        var row_number=0;
        foreach (API.PollOption p in options){
            foreach (string select in selection){
                if (select == p.title){
	                builder.add_string_value (row_number.to_string());
	            }
            }
            row_number++;
	    }
	    builder.end_array ();
        builder.end_object ();
        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        var json = generator.to_data (null);
        //Send POST MESSAGE
		Request voting=new Request.POST (@"/api/v1/polls/$(id)/votes")
			.with_account (acc);
		voting.set_request("application/json",Soup.MemoryUse.COPY,json.data);
		return voting;
    }
}
