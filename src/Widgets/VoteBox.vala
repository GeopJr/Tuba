using Gtk;
using Gdk;
using Gee;

[GtkTemplate (ui = "/dev/geopjr/tooth/ui/widgets/votebox.ui")]
public class Tooth.Widgets.VoteBox: Box {
	[GtkChild] protected Gtk.Box pollBox;
	[GtkChild] protected Gtk.Button button_vote;

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
	}

	void update(){
        var row_number=0;
 		Gtk.ToggleButton group_radio_option = null;

		//clear all existing entries
		Gtk.Widget entry=pollBox.get_first_child();
		while(entry!=null){
			pollBox.remove(entry);
			entry=pollBox.get_first_child();
		}
		//Reset button visibility
		button_vote.set_visible(false);
        if(!poll.expired && !poll.voted){
		    button_vote.set_visible(true);
		}
		//creates the entries of poll
 		foreach (API.PollOption p in poll.options){
            //if it is own poll
            if(poll.expired){
                // If multiple, Checkbox else radioButton
                var option = new Widgets.RichLabel (_(" %.2f %%   %s ".printf (( (double)p.votes_count/poll.votes_count)*100,p.title) ));
                pollBox.append(option);
            }
            else{
                var check_option = new Gtk.ToggleButton ();
                if (!poll.multiple){
                    if (row_number==0){
 						group_radio_option=check_option;
                    }
                    else{
 						check_option.set_group(group_radio_option);
                   }
				}
                check_option.set_label(p.title);
                check_option.toggled.connect((radio)=>{
                    if (selectedIndex.contains(radio.get_label())){
                        selectedIndex.remove(radio.get_label());
                    }
                    else{
                        selectedIndex.add(radio.get_label());
                    }
                });
                foreach (int own_vote in poll.own_votes){
                    if (own_vote==row_number){
                         check_option.set_active(true);
                          if (!selectedIndex.contains(p.title)){
                            selectedIndex.add(p.title);
                          }
                    }
                }
                if(poll.expired || poll.voted){
                    check_option.set_sensitive(false);
                }
                pollBox.append(check_option);
            }
            row_number++;
        }

        if(!poll.expired){
                var option = new Widgets.RichLabel (_("Expires at: %s").printf(DateTime.humanize(poll.expires_at)));
                pollBox.append(option);
        }
	}
}
