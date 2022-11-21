public class Tooth.Views.Home : Views.Timeline {

    public Home () {
        Object (
        	url: "/api/v1/timelines/home",
        	label: _("Home"),
        	icon: "tooth-home-symbolic"
        );
    }

    public override string? get_stream_url () {
        return account.get_stream_url ();
    }

}
