public class DateTime.Plug : Switchboard.Plug {
    private Gtk.Grid main_grid;
    private DateTime1 datetime1;
    private TimeMap time_map;
    private Settings clock_settings;
    private bool changing_clock_format = false;
    private uint timeout = 0;

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
            main_grid.expand = true;
            main_grid.margin = 12;
            main_grid.column_spacing = 12;
            main_grid.row_spacing = 6;

            var network_time_label = new Gtk.Label ("<b>%s</b>".printf (_("Network Time:")));
            network_time_label.use_markup = true;
            network_time_label.xalign = 1;
            var network_time_switch = new Gtk.Switch ();

            var switch_grid = new Gtk.Grid ();
            switch_grid.add (network_time_switch);

            var time_label = new Gtk.Label (_("Time:"));
            time_label.xalign = 1;
            var time_picker = new Granite.Widgets.TimePicker ();

            var date_label = new Gtk.Label (_("Date:"));
            date_label.xalign = 1;
            var date_picker = new Granite.Widgets.DatePicker ();

            var time_format_label = new Gtk.Label (_("Time Format:"));
            time_format_label.xalign = 1;
            var time_format_combobox = new Gtk.ComboBoxText ();
            time_format_combobox.append ("24h", _("24h"));
            time_format_combobox.append ("ampm", _("AM/PM"));

            var time_zone_label = new Gtk.Label (_("Time Zone:"));
            time_zone_label.xalign = 1;
            var time_zone_button = new Gtk.Button ();
            var time_zone_grid = new Gtk.Grid ();
            time_zone_grid.column_spacing = 5;
            time_zone_grid.halign = Gtk.Align.CENTER;
            var tz_continent_label = new Gtk.Label ("Europe");
            var tz_city_label = new Gtk.Label ("Paris");
            time_zone_grid.add (tz_continent_label);
            time_zone_grid.add (new Gtk.Separator (Gtk.Orientation.VERTICAL));
            time_zone_grid.add (tz_city_label);
            time_zone_button.add (time_zone_grid);

            time_map = new TimeMap ();
            time_map.expand = true;

            main_grid.attach (network_time_label, 1, 0, 1, 1);
            main_grid.attach (switch_grid, 2, 0, 1, 1);
            main_grid.attach (time_label, 1, 1, 1, 1);
            main_grid.attach (time_picker, 2, 1, 1, 1);
            main_grid.attach (date_label, 1, 2, 1, 1);
            main_grid.attach (date_picker, 2, 2, 1, 1);
            main_grid.attach (time_format_label, 1, 3, 1, 1);
            main_grid.attach (time_format_combobox, 2, 3, 1, 1);
            main_grid.attach (time_zone_label, 1, 4, 1, 1);
            main_grid.attach (time_zone_button, 2, 4, 1, 1);
            main_grid.attach (time_map, 0, 5, 4, 1);

            var fake_grid_1 = new Gtk.Grid ();
            fake_grid_1.hexpand = true;
            var fake_grid_2 = new Gtk.Grid ();
            fake_grid_2.hexpand = true;
            main_grid.attach (fake_grid_1, 0, 0, 1, 1);
            main_grid.attach (fake_grid_2, 3, 0, 1, 1);
            main_grid.show_all ();

            /*
             * Setup Time
             */
            time_picker.time_changed.connect (() => {
                warning ("CHANGED");
            });
            var very_next_minute = time_picker.time.add_seconds (-time_picker.time.get_seconds ()).add_minutes (1);
            var timespan = very_next_minute.difference (time_picker.time);
            timeout = Timeout.add ((uint) (timespan/1000), () => {
                time_picker.time = very_next_minute;
                return false;
            });

            /*
             * Setup Clock Format
             */
            clock_settings = new Settings ();
            if (clock_settings.clock_format == "12h") {
                time_format_combobox.active = 1;
            } else {
                time_format_combobox.active = 0;
            }

            clock_settings.notify["clock-format"].connect (() => {
                if (changing_clock_format == true)
                    return;

                changing_clock_format = true;
                if (clock_settings.clock_format == "12h") {
                    time_format_combobox.active = 1;
                } else {
                    time_format_combobox.active = 0;
                }
                changing_clock_format = false;
            });

            time_format_combobox.changed.connect (() => {
                if (changing_clock_format == true)
                    return;

                changing_clock_format = true;
                if (time_format_combobox.active == 0) {
                    clock_settings.clock_format = "24h";
                } else {
                    clock_settings.clock_format = "12h";
                }

                changing_clock_format = false;
            });

            /*
             * Setup TimeZone Button
             */
            time_zone_button.clicked.connect (() => {
                var popover = new DateTime.TZPopover ();
                popover.position = Gtk.PositionType.BOTTOM;
                popover.relative_to = time_zone_button;
                popover.show_all ();
            });

            /*
             * Setup Network Time
             */
            network_time_switch.notify["active"].connect (() => {
                bool active = network_time_switch.active;
                time_picker.sensitive = !active;
                date_picker.sensitive = !active;
                time_label.sensitive = !active;
                date_label.sensitive = !active;
            });

            try {
                datetime1 = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.timedate1", "/org/freedesktop/timedate1");
            } catch (IOError e) {
                critical (e.message);
            }

            if (datetime1.CanNTP == false) {
                network_time_switch.sensitive = false;
            }

            network_time_switch.active = datetime1.NTP;
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
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Date & Time plug");
    var plug = new DateTime.Plug ();
    return plug;
}
