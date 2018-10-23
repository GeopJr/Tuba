public class Tootle.Tag{

    public string name;
    public string url;

    public Tag (string _name, string _url){
        name = _name;
        url = _url;
    }
    
    public static Tag parse (Json.Object obj){
        var name = obj.get_string_member ("name");
        var url = obj.get_string_member ("url");
        return new Tag (name, url);
    }

}
