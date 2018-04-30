public class Tootle.Relationship{

    public int64 id;
    public bool following;
    public bool followed_by;
    public bool blocking;
    public bool muting;
    public bool muting_notifications;
    public bool requested;
    public bool domain_blocking;

    public Relationship(int64 id){
        this.id = id;
    }
    
    public static Relationship parse (Json.Object obj){
        var id = int64.parse (obj.get_string_member ("id"));
        var relationship = new Relationship (id);
        relationship.following = obj.get_boolean_member ("following");
        relationship.followed_by = obj.get_boolean_member ("followed_by");
        relationship.blocking = obj.get_boolean_member ("blocking");
        relationship.muting = obj.get_boolean_member ("muting");
        relationship.muting_notifications = obj.get_boolean_member ("muting_notifications");
        relationship.requested = obj.get_boolean_member ("requested");
        relationship.domain_blocking = obj.get_boolean_member ("domain_blocking");
        return relationship;
    }

}
