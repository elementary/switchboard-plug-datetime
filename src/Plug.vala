public class DateTime.Plug : Switchboard.Plug {
    private Gtk.Grid main_grid;
    private Gtk.Stack main_stack;
    private DateTime1 datetime1;

    public Plug () {
        Object (category: Category.SYSTEM,
            code_name: "system-pantheon-datetime",
            display_name: _("Date & Time"),
            description: _("Date and Time preferences panel"),
            icon: "preferences-system-time");
    }

    public override Gtk.Widget get_widget () {
        if (main_grid == null) {
            main_grid = new Gtk.Grid ();
            main_stack = new Gtk.Stack ();
            var stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.set_stack (main_stack);
            stack_switcher.halign = Gtk.Align.CENTER;
            stack_switcher.margin = 12;
            main_grid.orientation = Gtk.Orientation.VERTICAL;
            main_grid.add (stack_switcher);
            main_grid.add (main_stack);
            create_date_panel ();
            create_time_panel ();
            main_grid.show_all ();
            /*try {
                datetime1 = Bus.get_proxy_sync (BusType.SYSTEM,
                                                    "org.freedesktop.timedate1",
                                                    "org/freedesktop/timedate1");
            } catch (IOError e) {
                critical (e.message);
            }*/
        }

        return main_grid;
    }

    public override void shown () {
        
    }

    public override void hidden () {
        
    }

    public override void search_callback (string location) {
        
    }

    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        return new Gee.TreeMap<string, string> (null, null);
    }

    private void create_date_panel () {
        main_stack.add_titled (new Gtk.Grid (), "date_panel", _("Date"));
    }

    private void create_time_panel () {
        var grid = new Gtk.Grid ();
        grid.halign = Gtk.Align.CENTER;
        var frame = new Gtk.Frame (null);
        var time_map = new TimeMap ();
        frame.add (time_map);
        grid.expand = true;
        grid.add (frame);
        main_stack.add_titled (grid, "time_panel", _("Time"));
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Date & Time plug");
    var plug = new DateTime.Plug ();
    return plug;
}
