public class Tootle.Tag{

    public string name;
    public string url;

    public Tag(string name, string url){
        this.name = name;
        this.url = url;
    }
    
    public static Tag parse (Json.Object obj){
        var name = obj.get_string_member ("name");
        var url = obj.get_string_member ("url");
        return new Tag (name, url);
    }

}
