/*
 * Copyright 2014–2021 elementary, Inc. (https://elementary.io)
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

public class DateTime.MainView : Gtk.Widget {
    private Gtk.ScrolledWindow main_widget;
    private Gtk.Image auto_time_zone_icon;
    private TimeZoneGrid time_zone_picker;
    private DateTime1 datetime1;
    private CurrentTimeManager ct_manager;
    private GLib.Settings clock_settings;
    private Gtk.ToggleButton meridiem_time_format;
    private Gtk.ToggleButton military_time_format;
    private Pantheon.AccountsService? pantheon_act = null;

    private static GLib.Settings time_zone_settings;

    public bool automatic_timezone {
        set {
            if (value) {
                auto_time_zone_icon.icon_name = "location-active-symbolic";
            } else {
                auto_time_zone_icon.icon_name = "location-inactive-symbolic";
            }
        }
    }

    static construct {
        time_zone_settings = new GLib.Settings ("org.gnome.desktop.datetime");
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    construct {
        var network_time_label = new Gtk.Label (_("Network time:")) {
            halign = Gtk.Align.END
        };

        var network_time_switch = new Gtk.Switch () {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER
        };

        var time_picker = new Granite.TimePicker ();
        var date_picker = new Granite.DatePicker ();

        var time_format_label = new Gtk.Label (_("Time format:")) {
            halign = Gtk.Align.END
        };

        meridiem_time_format = new Gtk.ToggleButton.with_label (_("AM/PM")) {
            can_focus = false
        };

        military_time_format = new Gtk.ToggleButton.with_label (_("24-hour")) {
            can_focus = false,
            group = meridiem_time_format
        };

        var time_format_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            homogeneous = true
        };
        time_format_box.append (meridiem_time_format);
        time_format_box.append (military_time_format);

        var time_zone_label = new Gtk.Label (_("Time zone:")) {
            halign = Gtk.Align.END,
            valign = Gtk.Align.START
        };

        auto_time_zone_icon = new Gtk.Image.from_icon_name ("location-inactive-symbolic") {
            pixel_size = 16
        };

        weak Gtk.StyleContext auto_time_zone_icon_context = auto_time_zone_icon.get_style_context ();
        auto_time_zone_icon_context.add_class (Granite.STYLE_CLASS_ACCENT);
        auto_time_zone_icon_context.add_class ("purple");

        var auto_time_zone_switch_label = new Gtk.Label (_("Based on location:"));

        var auto_time_zone_switch = new Gtk.Switch () {
            tooltip_text = _("Automatically updates the time zone when activated")
        };

        var auto_time_zone_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            // column_spacing = 12,
            hexpand = true,
            margin_bottom = 12
        };

        auto_time_zone_box.append (auto_time_zone_icon);
        auto_time_zone_box.append (auto_time_zone_switch_label);
        auto_time_zone_box.append (auto_time_zone_switch);

        time_zone_picker = new DateTime.TimeZoneGrid () {
            hexpand = true
        };
        time_zone_picker.get_style_context ().add_class ("frame");

        var week_number_label = new Gtk.Label (_("Show week numbers:")) {
            halign = Gtk.Align.END
        };

        var week_number_switch = new Gtk.Switch () {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER
        };

        var week_number_info = new Gtk.Label (_("e.g. in Calendar and the Date & Time Panel indicator")) {
            max_width_chars = 40,
            wrap = true,
            xalign = 0
        };
        week_number_info.get_style_context ().add_class (Granite.STYLE_CLASS_DIM_LABEL);

        var panel_label = new Gtk.Label (_("Show in Panel:")) {
            halign = Gtk.Align.END,
            margin_top = 6
        };

        var date_check = new Gtk.CheckButton.with_label (_("Date"));
        var weekday_check = new Gtk.CheckButton.with_label (_("Day of the week"));
        var seconds_check = new Gtk.CheckButton.with_label (_("Seconds"));

        var panel_check_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            // column_spacing = 12,
            margin_top = 6
        };

        panel_check_box.append (date_check);
        panel_check_box.append (weekday_check);
        panel_check_box.append (seconds_check);

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            halign = Gtk.Align.CENTER,
            margin_bottom = 24,
            margin_top = 24,
            row_spacing = 12
        };

        grid.attach (time_format_label, 0, 0);
        grid.attach (time_format_box, 1, 0, 3);
        grid.attach (time_zone_label, 0, 1);
        grid.attach (time_zone_picker, 1, 1, 3);
        grid.attach (auto_time_zone_box, 1, 2, 3);
        grid.attach (network_time_label, 0, 3);
        grid.attach (network_time_switch, 1, 3);
        grid.attach (time_picker, 2, 3);
        grid.attach (date_picker, 3, 3);
        grid.attach (week_number_label, 0, 4);
        grid.attach (week_number_switch, 1, 4);
        grid.attach (week_number_info, 2, 4, 2);
        grid.attach (panel_label, 0, 5);
        grid.attach (panel_check_box, 1, 5, 3);

        main_widget = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = grid
        };
        main_widget.set_parent (this);

        var source = SettingsSchemaSource.get_default ();
        var schema = source.lookup ("io.elementary.desktop.wingpanel.datetime", true);

        GLib.Settings wingpanel_settings = null;

        if (schema == null) {
            week_number_label.visible = false;
            week_number_switch.visible = false;
            week_number_info.visible = false;
            panel_label.visible = false;
            panel_check_box.visible = false;
        } else {
            wingpanel_settings = new GLib.Settings ("io.elementary.desktop.wingpanel.datetime");
            wingpanel_settings.bind ("clock-show-date", date_check, "active", SettingsBindFlags.DEFAULT);
            wingpanel_settings.bind ("clock-show-weekday", weekday_check, "active", SettingsBindFlags.DEFAULT);
            wingpanel_settings.bind ("clock-show-seconds", seconds_check, "active", SettingsBindFlags.DEFAULT);
            wingpanel_settings.bind ("clock-show-date", weekday_check, "sensitive", SettingsBindFlags.DEFAULT);
            wingpanel_settings.bind ("show-weeks", week_number_switch, "active", SettingsBindFlags.DEFAULT);
        }

        time_zone_picker.request_timezone_change.connect (change_tz);

        bool syncing_datetime = false;

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

        clock_settings = new GLib.Settings ("org.gnome.desktop.interface");
        meridiem_time_format.toggled.connect (() => {
            unowned string new_format = meridiem_time_format.active == true ? "12h" : "24h";
            clock_settings.set_string ("clock-format", new_format);

            if (wingpanel_settings != null) {
                wingpanel_settings.set_string ("clock-format", new_format);
            }

            if (pantheon_act != null) {
                pantheon_act.time_format = new_format;
            }

            ct_manager.datetime_has_changed (true);
        });

        setup_time_format.begin ();

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

        time_zone_settings.bind ("automatic-timezone", auto_time_zone_switch, "active", SettingsBindFlags.DEFAULT);
        time_zone_settings.bind ("automatic-timezone", time_zone_picker, "sensitive", SettingsBindFlags.INVERT_BOOLEAN);
        time_zone_settings.bind ("automatic-timezone", this, "automatic-timezone", SettingsBindFlags.GET);
    }

    private async void setup_time_format () {
        try {
            var accounts_service = yield GLib.Bus.get_proxy<FDO.Accounts> (
                GLib.BusType.SYSTEM,
               "org.freedesktop.Accounts",
               "/org/freedesktop/Accounts"
            );
            var user_path = accounts_service.find_user_by_name (GLib.Environment.get_user_name ());

            pantheon_act = yield GLib.Bus.get_proxy (
                GLib.BusType.SYSTEM,
                "org.freedesktop.Accounts",
                user_path,
                GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES
            );

            // the military_time_format toggle button won't be toggled if
            // meridiem_time_format is 'not active' when this plug is opened

            if (pantheon_act.time_format == "12h") {
                meridiem_time_format.active = true;
            } else {
                military_time_format.active = true;
            }
        } catch (Error e) {
            critical (e.message);
            // Connect to the GSettings instead
            clock_settings.changed["clock-format"].connect (() => {
                if (clock_settings.get_string ("clock-format").contains ("12h")) {
                    meridiem_time_format.active = true;
                } else {
                    meridiem_time_format.active = false;
                }
            });

            if (clock_settings.get_string ("clock-format").contains ("12h")) {
                meridiem_time_format.active = true;
            } else {
                meridiem_time_format.active = false;
            }
        }
    }

    private void change_tz (string _tz) {
        var tz = _(_tz);
        var english_tz = _tz;

        time_zone_picker.time_zone = tz;

        if (datetime1.Timezone != english_tz) {
            try {
                datetime1.set_timezone (english_tz, true);
            } catch (Error e) {
                critical (e.message);
            }
            ct_manager.timezone_has_changed ();
        }

        var local_time = new GLib.DateTime.now_local ();

        float offset = (float)(local_time.get_utc_offset ()) / (float)(GLib.TimeSpan.HOUR);

        if (local_time.is_daylight_savings ()) {
            offset--;
        }
    }

    ~MainView () {
        while (this.get_last_child () != null) {
            this.get_last_child ().unparent ();
        }
    }
}
