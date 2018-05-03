public class Tootle.CmdRunner : GLib.Object{

    public signal void done(int exit);
    public signal void output_changed(string text);
    public signal void standard_changed(string text);
    public signal void error_changed(string text);

    public string standard_output_str = "";
    public string error_output_str = "";
    public string output_str = "";
    
    GLib.IOChannel out_make;
    GLib.IOChannel error_out;
    string dir;
    string command;
    Pid pid;

    public CmdRunner(string dir, string command){
        this.dir = dir;
        this.command = command;
    }

    public void run(){
        int standard_output = 0;
        int standard_error = 0;
        try{
        Process.spawn_async_with_pipes(dir,
                                       command.split(" "),
                                       null,
                                       SpawnFlags.DO_NOT_REAP_CHILD,
                                       null,
                                       out pid,
                                       null,
                                       out standard_output,
                                       out standard_error);
        }
        catch(Error e){
            critical("Couldn't launch command %s in the directory %s: %s", command, dir, e.message);
        }
        
        ChildWatch.add(pid, (pid, exit) => {
            Process.close_pid (pid);
            error_out.shutdown (false);
            out_make.shutdown (false);
            done(exit);
        });

        out_make = new GLib.IOChannel.unix_new(standard_output);
        out_make.add_watch(IOCondition.IN | IOCondition.HUP, (source, condition) => {
            if(condition == IOCondition.HUP){
                return false;
            }
            string output = null;
            
            try{
                out_make.read_line(out output, null, null);
            }
            catch(Error e){
                critical("Error in the output retrieving of %s: %s", command, e.message);
            }

            standard_output_str += output;
            output_str += output;
            standard_changed(output);
            output_changed(output);
            
            return true;
        });

        error_out = new GLib.IOChannel.unix_new(standard_error);
        error_out.add_watch(IOCondition.IN | IOCondition.HUP, (source, condition) => {
            if(condition == IOCondition.HUP){
                return false;
            }
            string output = null;
            try{
                error_out.read_line(out output, null, null);
            }
            catch(Error e){
                critical("Error in the output retrieving of %s: %s", command, e.message);
            }
            
            error_output_str += output;
            output_str += output;
            error_changed(output);
            output_changed(output);
            
            return true;
        });
    }
}
