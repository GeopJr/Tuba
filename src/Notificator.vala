using GLib;
using Soup;

public class Tootle.Notificator : GLib.Object {
    
    weak Account account;
    WebsocketConnection? connection;
    
    public Notificator (Account acc){
        Object ();
        account = acc;
    }
    
    public async void start () {
        var msg = account.get_stream ();
        connection = yield Tootle.network.stream (msg);
        connection.error.connect (e => error (e.message));
        connection.message.connect ((i, bytes) => {
            warning ((string)bytes.get_data ());
        });
        debug ("Receiving notifications for %lld", account.id);
    }
    
    public void close () {
        debug ("Closing notifications for %lld", account.id);
        connection.close (0, null);
    }
    
}
