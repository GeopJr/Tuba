public class Tootle.Views.Home : Views.Timeline {

    public Home () {
        Object (
        	timeline: "home",
        	label: _("Home"),
        	icon: "user-home-symbolic"
        );
    }

    public override string? get_stream_url () {
        return account.get_stream_url () ?? null;
    }

}
