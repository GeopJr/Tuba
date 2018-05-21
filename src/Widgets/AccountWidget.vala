public class Tootle.AccountWidget : StatusWidget {

    public AccountWidget (ref Account account) {
        var status = new Status (-1);
        status.account = account;
        status.content = "<a href=\"%s\">@%s</a>".printf (account.url, account.acct);
        status.created_at = account.created_at;
        
        base (ref status);
        
        counters.visible = false;
        title_acct.visible = false;
        content_label.margin_bottom = 12;
        button_press_event.connect(() => {
            open_account ();
            return true;
        });
    }

}
