public class Tootle.Views.Favorites : Views.Timeline {

    public Favorites () {
        Object (timeline: "favorites");
    }

    public override string get_url (){
        if (page_next != null)
            return page_next;

        return @"/api/v1/favourites";
    }

}
