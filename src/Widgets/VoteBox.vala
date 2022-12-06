using Gtk;
using Gdk;
using Gee;

[GtkTemplate (ui = "/dev/geopjr/tooth/ui/widgets/votebox.ui")]
public class Tooth.Widgets.VoteBox: Box {
	[GtkChild] protected ListBox pollBox;
	[GtkChild] protected Button button_vote;
    [GtkChild] protected Box pollActionBox;
    [GtkChild] protected Label people_label;
    [GtkChild] protected Label expires_label;

	public API.Poll? poll { get; set;}
	public API.Status? status_parent{ get; set;}


    protected ArrayList<string> selectedIndex=new ArrayList<string>();

	construct{
        button_vote.set_label (_("Vote"));
        button_vote.clicked.connect ((button) =>{
            Request voting=API.Poll.vote(accounts.active,poll.options,selectedIndex,poll.id);
 			voting.then ((sess, mess) => {
	            status_parent.poll=API.Poll.from_json(typeof(API.Poll),network.parse_node (mess));
            })
            .on_error ((code, reason) => {}).exec ();
        });
        notify["poll"].connect (update);
        button_vote.sensitive = false;
	}

    public string generate_css_style(int percentage) {
        return @".ttl-poll-$(percentage).ttl-poll-winner { background: linear-gradient(to right, alpha(@accent_bg_color, .5) $(percentage)%, transparent 0%); } .ttl-poll-$(percentage) { background: linear-gradient(to right, alpha(@view_fg_color, .1) $(percentage)%, transparent 0%); }.ttl-poll-row:first-child{border-top-left-radius: 12px;border-top-right-radius: 12px;}.ttl-poll-row:last-child{border-bottom-left-radius: 12px;border-bottom-right-radius: 12px;}";
    }

	void update(){
        var row_number=0;
        var winner_p = 0.0;

        Adw.ActionRow last_winner = null;
        Widgets.VoteCheckButton group_radio_option = null;

		//clear all existing entries
		Widget entry=pollBox.get_first_child();
		while(entry!=null){
			pollBox.remove(entry);
			entry=pollBox.get_first_child();
		}
		//Reset button visibility
		button_vote.set_visible(false);
        if(!poll.expired && !poll.voted){
		    button_vote.set_visible(true);
		}

        //  if (poll.expired) {
        //      pollBox.sensitive = false;
        //  }
		//creates the entries of poll
 		foreach (API.PollOption p in poll.options){
            var row = new Adw.ActionRow ();
            row.add_css_class("ttl-poll-row");

            //if it is own poll
            if(poll.expired || poll.voted){
                // If multiple, Checkbox else radioButton
                var percentage = ((double)p.votes_count/poll.votes_count)*100;

                var provider = new Gtk.CssProvider ();
                provider.load_from_data(generate_css_style((int) percentage).data);
                row.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                row.add_css_class(@"ttl-poll-$((int) percentage)");

                if (percentage > winner_p) {
                    winner_p = percentage;
                    if (last_winner != null)
                        last_winner.remove_css_class("ttl-poll-winner");
                    row.add_css_class("ttl-poll-winner");
                    last_winner = row;
                }

                foreach (int own_vote in poll.own_votes){
                    if (own_vote==row_number){
                         row.add_suffix(new Image.from_icon_name("tooth-check-round-outline-symbolic"));
                    }
                }

                row.title = "%.1f%%".printf(percentage);
                row.subtitle = p.title;
                pollBox.append(row);
            }
            else{
                row.title = p.title;
                var check_option = new Widgets.VoteCheckButton ();

                if (!poll.multiple){
                    if (row_number==0){
 						group_radio_option=check_option;
                    }
                    else{
 						check_option.set_group(group_radio_option);
                   }
				}

                check_option.poll_title = p.title;
                check_option.toggled.connect((radio)=>{
                    var radio_votebutton = radio as Widgets.VoteCheckButton;
                    if (selectedIndex.contains(radio_votebutton.poll_title)){
                        selectedIndex.remove(radio_votebutton.poll_title);
                    }
                    else{
                        selectedIndex.add(radio_votebutton.poll_title);
                    }
                    button_vote.sensitive = selectedIndex.size > 0;
                });

                foreach (int own_vote in poll.own_votes){
                    if (own_vote==row_number){
                         check_option.set_active(true);
                         row.add_suffix(new Image.from_icon_name("tooth-check-round-outline-symbolic"));
                          if (!selectedIndex.contains(p.title)){
                            selectedIndex.add(p.title);
                          }
                    }
                }

                if(poll.expired || poll.voted){
                    check_option.set_sensitive(false);
                }

                row.add_prefix(check_option);
                row.activatable_widget = check_option;

                pollBox.append(row);
            }
            row_number++;
        }

        people_label.label = _("%lld voted").printf(poll.votes_count);
        expires_label.label = poll.expired ? DateTime.humanize_ago(poll.expires_at) : DateTime.humanize_left(poll.expires_at);
	}
}
