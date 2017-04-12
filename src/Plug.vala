// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014 Pantheon Developers (http://launchpad.net/switchboard-plug-datetime)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class DateTime.Plug : Switchboard.Plug {
    private Gtk.Grid main_grid;
    private DateTime1 datetime1;
    private TimeMap time_map;
    private CurrentTimeManager ct_manager;
    private Settings clock_settings;
    private bool changing_clock_format = false;
    private Gtk.Label tz_continent_label;
    private Gtk.Label tz_city_label;

    public Plug () {
        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("time", null);
        settings.set ("date", null);
        Object (category: Category.SYSTEM,
            code_name: "system-pantheon-datetime",
            display_name: _("Date & Time"),
            description: _("Configure date, time, and select time zone"),
            icon: "preferences-system-time",
            supported_settings: settings);
    }

    public override Gtk.Widget get_widget () {
        if (main_grid == null) {

            var network_time_label = new Gtk.Label (_("Network Time:"));
            network_time_label.xalign = 1;

            var network_time_switch = new Gtk.Switch ();
            network_time_switch.halign = Gtk.Align.START;

            var time_picker = new Granite.Widgets.TimePicker ();
            var date_picker = new Granite.Widgets.DatePicker ();

            var time_format_label = new Gtk.Label (_("Time Format:"));
            time_format_label.xalign = 1;

            var time_format = new Granite.Widgets.ModeButton ();
            time_format.append_text (_("AM/PM"));
            time_format.append_text (_("24h"));

            if (Posix.nl_langinfo (Posix.NLItem.AM_STR) == "") {
                time_format_label.no_show_all = true;
                time_format.no_show_all = true;
            }

            var time_zone_label = new Gtk.Label (_("Time Zone:"));
            time_zone_label.xalign = 1;

            tz_continent_label = new Gtk.Label (null);
            tz_continent_label.xalign = 1;

            tz_city_label = new Gtk.Label (null);
            tz_city_label.xalign = 0;

            var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            size_group.add_widget (tz_continent_label);
            size_group.add_widget (tz_city_label);

            var time_zone_grid = new Gtk.Grid ();
            time_zone_grid.column_spacing = 6;
            time_zone_grid.halign = Gtk.Align.CENTER;
            time_zone_grid.add (tz_continent_label);
            time_zone_grid.add (new Gtk.Separator (Gtk.Orientation.VERTICAL));
            time_zone_grid.add (tz_city_label);

            var time_zone_button = new Gtk.Button ();
            time_zone_button.add (time_zone_grid);

            time_map = new TimeMap ();
            time_map.expand = true;
            time_map.map_selected.connect ((tz) => {
                change_tz (tz);
            });

            var widget_grid = new Gtk.Grid ();
            widget_grid.halign = Gtk.Align.CENTER;
            widget_grid.column_spacing = 12;
            widget_grid.row_spacing = 12;
            widget_grid.attach (time_format_label, 0, 0, 1, 1);
            widget_grid.attach (time_format, 1, 0, 3, 1);
            widget_grid.attach (time_zone_label, 0, 1, 1, 1);
            widget_grid.attach (time_zone_button, 1, 1, 3, 1);
            widget_grid.attach (network_time_label, 0, 2, 1, 1);
            widget_grid.attach (network_time_switch, 1, 2, 1, 1);
            widget_grid.attach (time_picker, 2, 2, 1, 1);
            widget_grid.attach (date_picker, 3, 2, 1, 1);

            main_grid = new Gtk.Grid ();
            main_grid.row_spacing = 24;
            main_grid.margin = 24;
            main_grid.attach (time_map, 0, 0, 1, 1);
            main_grid.attach (widget_grid, 0, 1, 1, 1);

            main_grid.show_all ();

            bool syncing_datetime = false;
            /*
             * Setup Time
             */
            time_picker.time_changed.connect (() => {
                var now_local = new GLib.DateTime.now_local ();
                var minutes = time_picker.time.get_minute () - now_local.get_minute ();
                var hours = time_picker.time.get_hour () - now_local.get_hour ();
                var now_utc = new GLib.DateTime.now_utc ();
                var usec_utc = now_utc.add_hours (hours).add_minutes (minutes).to_unix ();
                try {
                    datetime1.set_time (usec_utc * 1000000, false, true);
                } catch (Error e) {
                    critical (e.message);
                }
                ct_manager.datetime_has_changed ();
            });

            /*
             * Setup Date
             */
            date_picker.notify["date"].connect (() => {
                if (syncing_datetime == true)
                    return;

                var now_local = new GLib.DateTime.now_local ();
                var years = date_picker.date.get_year () - now_local.get_year ();
                var days = date_picker.date.get_day_of_year () - now_local.get_day_of_year ();
                var now_utc = new GLib.DateTime.now_utc ();
                var usec_utc = now_utc.add_years (years).add_days (days).to_unix ();
                try {
                    datetime1.set_time (usec_utc * 1000000, false, true);
                } catch (Error e) {
                    critical (e.message);
                }
                ct_manager.datetime_has_changed ();
            });

            /*
             * Stay synced with current time and date.
             */
            ct_manager = new CurrentTimeManager ();
            ct_manager.time_has_changed.connect ((dt) => {
                syncing_datetime = true;
                time_picker.time = dt;
                date_picker.date = dt;
                syncing_datetime = false;
            });

            /*
             * Setup Clock Format
             */
            clock_settings = new Settings ();
            Variant value;
            value = clock_settings.schema.get_value ("clock-format");
            if (value != null && clock_settings.clock_format == "24h") {
                time_format.selected = 1;
            } else {
                time_format.selected = 0;
            }

            clock_settings.notify["clock-format"].connect (() => {
                if (changing_clock_format == true)
                    return;

                changing_clock_format = true;
                if (clock_settings.clock_format == "12h") {
                    time_format.selected = 0;
                } else {
                    time_format.selected = 1;
                }
                changing_clock_format = false;
            });

            time_format.mode_changed.connect (() => {
                if (changing_clock_format == true)
                    return;

                changing_clock_format = true;
                if (time_format.selected == 1) {
                    clock_settings.clock_format = "24h";
                } else {
                    clock_settings.clock_format = "12h";
                }

                changing_clock_format = false;
            });

            /*
             * Setup TimeZone Button
             */
            var popover = new DateTime.TZPopover ();
            popover.relative_to = time_zone_button;
            popover.request_timezone_change.connect (change_tz);
            popover.position = Gtk.PositionType.BOTTOM;
            popover.show_all ();
            time_zone_button.clicked.connect (() => {
                popover.set_timezone (datetime1.Timezone);
                popover.visible = !popover.visible;
            });

            /*
             * Setup Network Time
             */
            network_time_switch.notify["active"].connect (() => {
                bool active = network_time_switch.active;
                time_picker.sensitive = !active;
                date_picker.sensitive = !active;
                try {
                    datetime1.SetNTP (active, true);
                } catch (Error e) {
                    critical (e.message);
                }
                ct_manager.datetime_has_changed ();
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
            change_tz (datetime1.Timezone);
        }

        return main_grid;
    }

    private void change_tz (string _tz) {
        var tz = _(_tz);
        var english_tz = _tz;
        var values = tz.split ("/", 2);
        tz_continent_label.label = values[0];
        tz_city_label.label = Parser.format_city (values[1]);
        if (datetime1.Timezone != english_tz) {
            try {
                datetime1.set_timezone (english_tz, true);
            } catch (Error e) {
                critical (e.message);
            }
            ct_manager.timezone_has_changed ();
        }

        var local_time = new GLib.DateTime.now_local ();
        float offset = (float)(local_time.get_utc_offset ())/(float)(GLib.TimeSpan.HOUR);
        if (local_time.is_daylight_savings ())
            offset--;
        time_map.switch_to_tz (offset);
    }

    public override void shown () {

    }

    public override void hidden () {

    }

    public override void search_callback (string location) {

    }

    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
        search_results.set ("%s → %s".printf (display_name, _("Network Time")), "");
        search_results.set ("%s → %s".printf (display_name, _("Time")), "");
        search_results.set ("%s → %s".printf (display_name, _("Date")), "");
        search_results.set ("%s → %s".printf (display_name, _("Time Zone")), "");
        search_results.set ("%s → %s".printf (display_name, _("Time Format")), "");
        return search_results;
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Date & Time plug");
    var plug = new DateTime.Plug ();
    return plug;
}
