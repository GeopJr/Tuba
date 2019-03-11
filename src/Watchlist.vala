using GLib;
using Gee;

public class Tootle.Watchlist : Object {

    public ArrayList<string> users = new ArrayList<string> ();
    public ArrayList<string> hashtags = new ArrayList<string> ();
    public ArrayList<Notificator> notificators = new ArrayList<Notificator> ();

    construct {
        accounts.switched.connect (on_account_changed);
    }

    public Watchlist () {}

    public virtual void on_account_changed (API.Account? account){
        if (account != null)
            reload ();
    }

    private void reload () {
        info ("Reloading");

        notificators.@foreach (notificator => {
            notificator.close ();
            return true;
        });
        notificators.clear ();
        users.clear ();
        hashtags.clear ();

        load ();
        info ("Watching for %i users and %i hashtags", users.size, hashtags.size);
    }

    private void load () {
        var users_array = settings.watched_users.split (",");
        foreach (string item in users_array)
            add (item, false);

        var hashtags_array = settings.watched_hashtags.split (",");
        foreach (string item in hashtags_array)
            add (item, true);
    }

    public void save () {
        var serialized_users = "";
        users.@foreach (item => {
            serialized_users += item + ",";
            return true;
        });
        serialized_users = remove_last_delimiter (serialized_users);
        settings.watched_users = serialized_users;

        var serialized_hashtags = "";
        hashtags.@foreach (item => {
            serialized_hashtags += item + ",";
            return true;
        });
        serialized_hashtags = remove_last_delimiter (serialized_hashtags);
        settings.watched_hashtags = serialized_hashtags;

        info ("Saved");
    }

    private string remove_last_delimiter (string str) {
        var i = str.last_index_of (",");
        if (i > -1)
            return str.substring (0, i);
        else
            return str;
    }

    private Notificator get_notificator (string hashtag) {
        var url = "%s/api/v1/streaming/?stream=hashtag&tag=%s&access_token=%s".printf (accounts.formal.instance, hashtag, accounts.formal.token);
        var msg = new Soup.Message ("GET", url);
        var notificator = new Notificator (msg);
        notificator.status_added.connect (on_status_added);
        return notificator;
    }

    private void on_status_added (API.Status status) {
        var obj = new API.Notification (-1);
        obj.type = API.NotificationType.WATCHLIST;
        obj.account = status.account;
        obj.status = status;
        accounts.formal.notification (obj);
    }

    public void add (string entity, bool is_hashtag) {
        if (entity == "")
            return;

        if (is_hashtag) {
            hashtags.add (entity);
            var notificator = get_notificator (entity);
            notificator.start ();
            notificators.add (notificator);
            info ("Added #%s", entity);
        }
        else {
            users.add (entity);
            info ("Added @%s", entity);
        }
    }

    public void remove (string entity, bool is_hashtag) {
        if (entity == "")
            return;

        if (is_hashtag) {
            var i = hashtags.index_of (entity);
            var notificator = notificators.@get(i);
            notificator.close ();
            notificators.remove_at (i);
            hashtags.remove (entity);
            info ("Removed #%s", entity);
        }
        else {
            users.remove (entity);
            info ("Removed @%s", entity);
        }
    }

}
