public class Tootle.Attachment{

    public int64 id;
    public string type;
    public string url;
    public string preview_url;
    public string? description;

    public Attachment(int64 id){
        this.id = id;
    }
    
    public static Attachment parse (Json.Object obj){
        var id = int64.parse (obj.get_string_member ("id"));
        var attachment = new Attachment (id);
        
        attachment.type = obj.get_string_member ("type");
        attachment.preview_url = obj.get_string_member ("preview_url");
        attachment.url = obj.get_string_member ("url");
        
        if (obj.has_member ("description"))
            attachment.description = obj.get_string_member ("description");
        
        return attachment;
    }

}
