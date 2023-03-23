public class Tuba.Views.Home : Views.Timeline {

    public Home () {
        Object (
        	url: "/api/v1/timelines/home",
        	label: _("Home"),
        	icon: "tuba-home-symbolic"
        );
    }

    public override string? get_stream_url () {
        return account.get_stream_url ();
    }

}
