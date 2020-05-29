/*
 * Copyright (C) 2014 PerfectCarl - https://github.com/PerfectCarl/vala-stacktrace
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

public class Stacktrace {

    public class Frame {
        // Address used by addr2line
        public string address  { get;private set;default = "";}

        public string line { get;private set;default = "";}

        public string line_number { get;private set;default = "";}

        public string file_path { get;private set;default = "";}

        public string file_short_path { get;private set;default = "";}

        public string function { get;private set;default = "";}

        public Frame (string address, string line, string function, string file_path, string file_short_path) {
            this._address = address;
            this._line = line;

            this._file_path = file_path;
            this._file_short_path = file_short_path;
            this._function = function;
            this.line_number = extract_line (line);
        }

        public string to_string () {
            var result = line;
            if (result == "")
                result = " C library at address [" + address + "]";
            return result + " [" + address + "]";
        }

    }

    public enum Style {
        RESET = 0,
        BRIGHT = 1,
        DIM = 2,
        UNDERLINE = 3,
        BLINK = 4,
        REVERSE = 7,
        HIDDEN = 8
    }

    public enum CriticalHandler {
        IGNORE,
        PRINT_STACKTRACE,
        CRASH
    }

    public enum Color {
        BLACK = 0,
        RED = 1,
        GREEN = 2,
        YELLOW = 3,
        BLUE = 4,
        MAGENTA = 5,
        CYAN = 6,
        WHITE = 7
    }

    public Gee.ArrayList<Frame> _frames = new Gee.ArrayList<Frame>();

    private Frame first_vala = null;

    private int max_file_name_length = 0;

    private int max_line_number_length = 0;

    private bool is_all_function_name_blank = true;

    private bool is_all_file_name_blank = true;

    private ProcessSignal sig;

    public static bool enabled { get;set;default = true;}

    public static bool hide_installed_libraries { get;set;default = false;}

    public static Color default_highlight_color { get;set;default = Color.WHITE;}

    public static Color default_error_background { get;set;default = Color.RED;}

    public Color highlight_color { get;set;default = Color.WHITE;}

    public Color error_background { get;set;default = Color.RED;}

    public Gee.ArrayList<Frame> frames {
        get {
            return _frames;
        }
    }

    public Stacktrace (GLib.ProcessSignal sig = GLib.ProcessSignal.TTOU) {
        this.sig = sig;
        error_background = default_error_background;
        highlight_color = default_highlight_color;
        //hide_installed_libraries = true;
        create_stacktrace ();
    }

    private string get_module_name () {
        var path = new char[1024];
        Posix.readlink ("/proc/self/exe", path);
        string result = (string) path;
        return result;
    }

    // TODO CARL convert this piece of code to vala conventions
    public static string get_relative_path (string p_fullDestinationPath, string p_startPath) {

        string[] l_startPathParts = p_startPath.split ("/");
        string[] l_destinationPathParts = p_fullDestinationPath.split ("/");

        int l_sameCounter = 0;
        while ((l_sameCounter < l_startPathParts.length) &&
               (l_sameCounter < l_destinationPathParts.length) &&
               l_startPathParts[l_sameCounter] == l_destinationPathParts[l_sameCounter]) {
            l_sameCounter++;
        }

        if (l_sameCounter == 0) {
            return p_fullDestinationPath;             // There is no relative link.
        }

        StringBuilder l_builder = new StringBuilder ();
        for (int i = l_sameCounter ; i < l_startPathParts.length ; i++) {
            l_builder.append ("../");
        }

        for (int i = l_sameCounter ; i < l_destinationPathParts.length ; i++) {
            l_builder.append (l_destinationPathParts[i] + "/");
        }

        // CARL l_builder.Length--;
        // Remove the last /
        var result = l_builder.str;
        result = result.substring (0, result.length - 1);
        return result;
    }

    private string extract_short_file_path (string file_path) {
        var path = Environment.get_current_dir ();
        /*var i = file_path.index_of ( path );
           if( i>=0 )
            return file_path.substring ( path.length, file_path.length - path.length );
           return file_path; */
        var result = get_relative_path (file_path, path);
        return result;
    }

    public bool is_custom {
        get {
            return sig == ProcessSignal.TTOU;
        }
    }
    // input : '/home/cran/Documents/Projects/elementary/noise/instant-beta/build/core/libnoise-core.so.0(noise_job_repository_create_job+0x309) [0x7ff60a021e69]'
    // ouput: 0x309
    private int extract_base_address (string line) {
        int result = 0 ;
        var start = line.last_index_of ("+");
        if (start >= 0) {
            var end = line.last_index_of (")");
            if( end > start ) {
                var text = line.substring (start+3,end-start-3) ;
                text.scanf("%x",  &result);
            }
        }
        return result ;
    }

    private void process_info_for_file (string full_line, string str ) {
        func = "" ;
        file_path = "";
        short_file_path = "";
        l = "";
        file_line = "";
        func_line = "";

        var lines = full_line.split ("\n");

        if (lines.length > 0)
            func_line = lines[0];

        if (lines.length > 1)
            file_line = lines[1];
        if (file_line == "??:0" || file_line == "??:?")
            file_line = "";
        func = extract_function_name (str);

        file_path = "";
        short_file_path = "";
        l = "";
        if (file_line != "") {
            if (func == "")
                func = extract_function_name_from_line (func_line);
            file_path = extract_file_path (file_line);
            short_file_path = extract_short_file_path (file_path);
            l = extract_line (file_line);
        }
    }

    string func = "" ;
    string file_path = "";
    string short_file_path = "";
    string l = "";
    string file_line = "";
    string func_line = "";

    private void process_info_from_lib (string file_path, string str) {
        var cmd2 = "nm %s".printf(file_path) ;
        var addr1_s = execute_command_sync_get_output (cmd2) ;
        MatchInfo info ;
        try {
            Regex regex = new Regex ("\\n[^ ]* T "+func);

            if( regex.match (addr1_s, 0, out info) )
            {
                while( info.matches() ){
                    var lll = info.fetch(0) ;
                    //stdout.printf ( "lll '%s'\n", lll ) ;
                    addr1_s = lll.substring(0, lll.index_of(" ")) ;
                    info.next();
                }
            }
        } catch (RegexError e)
        {
            critical( "Error while processing regex %s", e.message ) ;
        }
        //stdout.printf ("addr1_s %s\n", addr1_s) ;
        int addr1 = 0 ;
        addr1_s.scanf("%x",  &addr1);
        if( addr1 != 0 ) {
            int addr2 = extract_base_address (str) ;
            string addr3 = "%#08x".printf (addr1+addr2);
            var new_full_line = process_line (file_path, addr3);
            process_info_for_file (new_full_line, str ) ;
        }
    }

    private void create_stacktrace () {
        int frame_count = 100;
        int skipped_frames_count = 5;
        // Stacktrace not due to a crash
        if (is_custom)
            skipped_frames_count = 3;

        void *[] array = new void *[frame_count];

        _frames.clear ();
        first_vala = null;
        max_file_name_length = 0;
        is_all_function_name_blank = true;
        is_all_file_name_blank = true;

        #if VALA_0_26
        var size = Linux.Backtrace.@get (array);
        var strings = Linux.Backtrace.symbols (array);
        #else
        int size = Linux.backtrace (array, frame_count);
        unowned string[] strings = Linux.backtrace_symbols (array, size);
        // Needed because of some weird bug
        strings.length = size;
        #endif

        int[] addresses = (int[])array;
        string module = get_module_name ();
        // First ones are the handler
        for (int i = skipped_frames_count ; i < size ; i++) {
            int address = addresses[i];
            string str = strings[i];
            var addr = extract_address (str);

            var full_line = process_line (module, addr);
            process_info_for_file( full_line, str) ;
            if (file_line == "") {
                file_path = extract_file_path_from (str);

            }
            if( file_path.has_suffix(".so.0")) {
                process_info_from_lib (file_path, str) ;
            }

            //stdout.printf ("Building %d \n  . addr: [%s]\n  . full_line: '%s'\n  . file_line: '%s'\n  . func_line: '%s'\n  . str : '%s'\n  . func: '%s'\n  . file: '%s'\n  . line: '%s'\n",
             //i, addr, full_line, file_line, func_line, str, func, file_path, l);

            if (func != "" && file_path.has_suffix (".vala") && is_all_function_name_blank)
                is_all_function_name_blank = false;

            if (short_file_path != "" && is_all_file_name_blank)
                is_all_file_name_blank = false;

            var frame = new Frame (addr, file_line, func, file_path, short_file_path);

            if (first_vala == null && file_path.has_suffix (".vala"))
                first_vala = frame;

            if (short_file_path.length > max_file_name_length)
                max_file_name_length = short_file_path.length;
            if (l.length > max_line_number_length)
                max_line_number_length = l.length;
            _frames.add (frame);
        }
    }

    private string extract_function_name (string line) {
        if (line == "")
            return "";
        var start = line.index_of ("(");
        if (start >= 0) {
            var end = line.index_of ("+", start);
            if (end >= 0) {
                var result = line.substring (start + 1, end - start - 1);
                return result.strip ();
            }
        }
        return "";
    }

    private string extract_function_name_from_line (string line) {
        return line.strip ();
    }

    private string extract_file_path_from (string str) {
        if (str == "")
            return "";
        /*if( str.index_of("??") >= 0)
            //result = result.substring (4, line.length - 4 );
            stdout.printf ("ERR2?? : %s\n", str ) ; */
        var start = str.index_of ("(");
        if (start >= 0) {
            return str.substring (0, start).strip ();
        }
        return str.strip ();
    }

    private string extract_file_path (string line) {
        var result = line;
        if (result == "")
            return "";
        if (result == "??:0??:0")
            return "";
        // For some reason, the file name can starts with ??:0
        if (result.has_prefix ("??:0"))
            result = result.substring (4, line.length - 4);
        // stdout.printf ("ERR1?? : %s\n", line ) ;
        var start = result.index_of (":");
        if (start >= 0) {
            result = result.substring (0, start);
            return result.strip ();
        }
        return "";
    }

    public static string extract_line (string line) {
        var result = line;
        if (result == "")
            return "";
        if (result.has_prefix ("??:0"))
            result = result.substring (4, line.length - 4);
        var start = result.index_of (":");
        if (start >= 0) {
            result = result.substring (start + 1, line.length - start - 1);
            var end = result.index_of ("(");
            if (end >= 0) {
                result = result.substring (0, end);
            }
            return result.strip ();
        }
        return "";
    }

    private string extract_address (string line) {
        if (line == "")
            return "";
        var start = line.index_of ("[");
        if (start >= 0) {
            var end = line.index_of ("]", start);
            if (end >= 0) {
                var result = line.substring (start + 1, end - start - 1);
                return result.strip ();
            }
        }
        return "";
    }

    private string execute_command_sync_get_output (string cmd) {
        try {
            int exitCode;
            string std_out;
            string std_err;
            Process.spawn_command_line_sync (cmd, out std_out, out std_err, out exitCode);
            return std_out;
        }
        catch (Error e) {
            warning (@"Error while executing '$cmd': $(e.message)");
            return "";
        }
    }

    // Poor's man demangler. libunwind is another dep
    // TODO : Optimize this
    // module : app
    // address : 0x007f80
    // output : /home/cran/Projects/noise/noise-perf-instant-search/tests/errors.vala:87
    string process_line (string module, string address) {
        var cmd = "addr2line -f -e %s %s".printf (module, address);
        var result = execute_command_sync_get_output (cmd);
        //stdout.printf( "CMD %s\n", cmd) ;
        return result;
    }

    private string get_reset_code () {
        // return get_color_code (Style.RESET, Colors.WHITE, Colors.BLACK);
        return "\x1b[0m";
    }

    private string get_reset_style () {
        return get_color_code (Style.DIM, highlight_color, background_color);
    }

    private string get_color_code (Style attr, Color fg, Color bg = background_color) {
        /* Command is the control command to the terminal */
        if (bg == Color.BLACK)
            return "%c[%d;%dm".printf (0x1B, (int) attr, (int) fg + 30);
        else
            return "%c[%d;%d;%dm".printf (0x1B, (int) attr, (int) fg + 30, (int) bg + 40);
    }

    private string get_signal_name () {
        return sig.to_string ();
    }

    private string get_highlight_code () {
        return get_color_code (Style.BRIGHT, highlight_color);
    }

    private string get_printable_function (Frame frame, int padding = 0) {
        var result = "";
        var is_unknown = false;
        if (frame.function == "") {
            result = "<unknown> " + frame.address;
            is_unknown = true;
        } else {
            var s = "";
            int count = padding - get_signal_name ().length;
            if (padding != 0 && count > 0)
                s = string.nfill (count, ' ');
            result = "'" + frame.function + "'" + s;
        }
        if (is_unknown)
            return result + get_reset_code ();
        else
            return get_highlight_code () + result + get_reset_code ();
    }

    private string get_printable_line_number (Frame frame, bool pad = true) {
        var path = frame.line_number;
        var result = "";
        var color = get_highlight_code ();
        if (path.length >= max_line_number_length || !pad)
            result = color + path + get_reset_style ();
        else {
            result = color + path + get_reset_style ();
            result = string.nfill (max_line_number_length - path.length, ' ') + result;
        }
        return result;
    }

    private string get_printable_file_short_path (Frame frame, bool pad = true) {
        var path = frame.file_short_path;
        var result = "";
        var color = get_highlight_code ();
        if (path.length >= max_file_name_length || !pad)
            result = color + path + get_reset_style ();
        else {
            result = color + path + get_reset_style ();
            result = result + string.nfill (max_file_name_length - path.length, ' ');
        }
        return result;
    }

    Color background_color = Color.BLACK;
    int title_length = 0;

    private string get_printable_title () {
        var c = get_color_code (Style.DIM, highlight_color, background_color);
        var color = get_highlight_code ();

        var result = "" ;

        if( is_custom)
            result = "%sA function was called in %s".printf (
                c,
                get_reset_style ());
        else
            result = "%sAn error occured %s(%s)%s".printf (
                c,
                color,
                get_signal_name (),
                get_reset_style ());

        title_length = get_signal_name ().length;
        return result;
    }

    private string get_reason () {
        // var c = get_reset_code();
        var color = get_highlight_code ();
        if (sig == ProcessSignal.TRAP) {
            return "The reason is likely %san uncaught error%s".printf (
                color, get_reset_code ());
        }
        if (sig == ProcessSignal.ABRT) {
            return "The reason is likely %sa failed assertion (assert...)%s".printf (
                color, get_reset_code ());
        }
        if (sig == ProcessSignal.SEGV) {
            return "The reason is likely %sa null reference being used%s".printf (
                color, get_reset_code ());
        }
        return "Unknown reason";
    }

    public void print () {
        stdout.printf ("\n");
        background_color = error_background;
        var header = "%s%s\n".printf (get_printable_title (),
                                      get_reset_code ());

        if (first_vala != null) {
            header = "%s in %s, line %s in %s\n".printf (
                get_printable_title (),
                get_printable_file_short_path (first_vala, false),
                get_printable_line_number (first_vala, false),
                get_printable_function (first_vala) + get_reset_code ());
            title_length += first_vala.line_number.length +
                            first_vala.function.length +
                            first_vala.file_short_path.length;
        }
        stdout.printf (header);
        background_color = Color.BLACK;
        if( !is_custom) {
            var reason = get_reason ();
            stdout.printf ("%s\n", reason);
        }

        // Has the user forgot to compile with -g -X -rdynamic flag ?
        if (is_all_file_name_blank) {
            //var advice = "   %sNote%s: no file path and line numbers can be retrieved. Are you sure %syou added -g -X -rdynamic%s to valac command line?\n";
            var advice = "%sNote%s: no vala function name can be retrieved.";
            var color = get_highlight_code ();
            stdout.printf (advice, color, get_reset_code (), color, get_reset_code ());
        }

        // Has the user forgot to compile with rdynamic flag ?
        if (is_all_function_name_blank && !is_all_file_name_blank) {
            var advice = "%sNote%s: no vala function name can be retrieved.";
            //var advice = "   %sNote%s: no vala function name can be retrieved. Are you sure %syou added -X -rdynamic%s to valac command line?\n";
            var color = get_highlight_code ();
            stdout.printf (advice, color, get_reset_code (), color, get_reset_code ());
        }

        stdout.printf ("\n");
        int i = 1;
        bool has_displayed_first_vala = false;
        foreach (var frame in _frames) {
            var show_frame = frame.function != "" || frame.file_path.has_suffix (".vala") || frame.file_path.has_suffix (".c");
            if (hide_installed_libraries && has_displayed_first_vala)
                show_frame = show_frame && frame.file_short_path != "";

            // Ignore glib tracing code if displayed before the first vala frame
            if ((frame.function == "g_logv" || frame.function == "g_log") && !has_displayed_first_vala)
                show_frame = false;
            if (show_frame) {
                // #2  ./OtherModule.c      line 80      in 'other_module_do_it'
                // at /home/cran/Projects/noise/noise-perf-instant-search/tests/errors/module/OtherModule.vala:10
                var str = " %s  #%d  %s    line %s in %s\n";
                background_color = Color.BLACK;
                var lead = " ";
                var function_padding = 0;
                if (frame == first_vala) {
                    has_displayed_first_vala = true;
                    lead = "*";
                    background_color = error_background;
                    function_padding = 22;
                }
                var l_number = "";
                if (frame.line_number == "") {
                    str = " %s  #%d  <unknown>  %s in %s\n";
                    var func_name = get_printable_function (frame);
                    var fill_len = int.max (max_file_name_length + max_line_number_length - 1, 0);
                    str = str.printf (
                        lead,
                        i,
                        string.nfill (fill_len, ' '),
                        func_name);
                } else {
                    str = str.printf (
                        lead,
                        i,
                        get_printable_file_short_path (frame),
                        get_printable_line_number (frame),
                        get_printable_function (frame, function_padding));
                    l_number = ":" + frame.line_number;
                }
                stdout.printf (str);
                str = "        at %s%s\n".printf (
                    frame.file_path, l_number);
                stdout.printf (str);

                i++;
            }
        }
    }

    public static void register_handlers () {
        Process.@signal (ProcessSignal.SEGV, handler);
        Process.@signal (ProcessSignal.ABRT, handler);
        Process.@signal (ProcessSignal.TRAP, handler);
    }

    public static CriticalHandler critical_handling  { get;set;default = CriticalHandler.PRINT_STACKTRACE;}

    public static void handler (int sig) {
        Stacktrace stack = new Stacktrace ((ProcessSignal) sig);
        stack.print ();
        if (sig != ProcessSignal.TRAP ||
            (sig == ProcessSignal.TRAP && critical_handling == CriticalHandler.CRASH))
            Process.exit (1);
    }

}

