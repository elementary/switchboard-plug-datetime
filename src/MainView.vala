/*
 * Copyright 2014-2019 elementary, Inc. (https://elementary.io)
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

public class DateTime.MainView : Gtk.Grid {
    private Gtk.Image auto_time_zone_icon;
    private TimeZoneButton time_zone_button;
    private DateTime1 datetime1;
    private CurrentTimeManager ct_manager;
    private GLib.Settings clock_settings;
    private Granite.Widgets.ModeButton time_format;
    private Greeter.AccountsService? greeter_act = null;

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
    }

    construct {
        var network_time_label = new Gtk.Label (_("Network Time:"));
        network_time_label.xalign = 1;

        var network_time_switch = new Gtk.Switch ();
        network_time_switch.valign = Gtk.Align.CENTER;
        network_time_switch.halign = Gtk.Align.START;

        var time_picker = new Granite.Widgets.TimePicker ();
        var date_picker = new Granite.Widgets.DatePicker ();

        var time_format_label = new Gtk.Label (_("Time Format:"));
        time_format_label.xalign = 1;

        time_format = new Granite.Widgets.ModeButton ();
        time_format.append_text (_("AM/PM"));
        time_format.append_text (_("24h"));

        var time_zone_label = new Gtk.Label (_("Time Zone:"));
        time_zone_label.xalign = 1;

        auto_time_zone_icon = new Gtk.Image ();
        auto_time_zone_icon.gicon = new ThemedIcon ("location-inactive-symbolic");
        auto_time_zone_icon.pixel_size = 16;

        var auto_time_zone_button = new Gtk.ToggleButton ();
        auto_time_zone_button.image = auto_time_zone_icon;
        auto_time_zone_button.tooltip_text = _("Automatically update time zone");

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/switchboard/plug/datetime/Plug.css");

        var auto_time_zone_button_context = auto_time_zone_button.get_style_context ();
        auto_time_zone_button_context.add_class ("auto-timezone");
        auto_time_zone_button_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        time_zone_button = new TimeZoneButton ();
        time_zone_button.hexpand = true;
        time_zone_button.request_timezone_change.connect (change_tz);

        var time_zone_grid = new Gtk.Grid ();
        time_zone_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        time_zone_grid.add (time_zone_button);
        time_zone_grid.add (auto_time_zone_button);

        var week_number_label = new Gtk.Label (_("Show week numbers:"));
        week_number_label.xalign = 1;

        var week_number_switch = new Gtk.Switch ();
        week_number_switch.valign = Gtk.Align.CENTER;
        week_number_switch.halign = Gtk.Align.START;

        column_spacing = 12;
        row_spacing = 12;
        attach (time_format_label, 0, 0);
        attach (time_format, 1, 0, 3);
        attach (time_zone_label, 0, 1);
        attach (time_zone_grid, 1, 1, 3);
        attach (network_time_label, 0, 2);
        attach (network_time_switch, 1, 2);
        attach (week_number_label, 0, 3);
        attach (week_number_switch, 1, 3);
        attach (time_picker, 2, 2);
        attach (date_picker, 3, 2);
        show_all ();

        var source = SettingsSchemaSource.get_default ();
        var schema = source.lookup ("io.elementary.desktop.wingpanel.datetime", false);

        if (schema == null) {
            week_number_label.no_show_all = true;
            week_number_switch.no_show_all = true;
        } else {
            var week_number_settings = new GLib.Settings ("io.elementary.desktop.wingpanel.datetime");
            week_number_settings.bind ("show-weeks", week_number_switch, "active", SettingsBindFlags.DEFAULT);
        }

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
        clock_settings = new GLib.Settings ("org.gnome.desktop.interface");
        time_format.mode_changed.connect (() => {
            unowned string new_format = time_format.selected == 0 ? "12h" : "24h";
            clock_settings.set_string ("clock-format", new_format);
            if (greeter_act != null) {
                greeter_act.time_format = new_format;
            }
        });

        setup_time_format.begin ();

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

        time_zone_settings.bind ("automatic-timezone", auto_time_zone_button, "active", SettingsBindFlags.DEFAULT);
        time_zone_settings.bind ("automatic-timezone", time_zone_button, "sensitive", SettingsBindFlags.INVERT_BOOLEAN);
        time_zone_settings.bind ("automatic-timezone", time_zone_label, "sensitive", SettingsBindFlags.INVERT_BOOLEAN);
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

            greeter_act = yield GLib.Bus.get_proxy (
                GLib.BusType.SYSTEM,
                "org.freedesktop.Accounts",
                user_path,
                GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES
            );
            time_format.set_active (greeter_act.time_format == "12h" ? 0 : 1);
        } catch (Error e) {
            critical (e.message);
            // Connect to the GSettings instead
            clock_settings.changed["clock-format"].connect (() => {
                if (clock_settings.get_string ("clock-format").contains ("12h")) {
                    time_format.selected = 0;
                } else {
                    time_format.selected = 1;
                }
            });

            if (clock_settings.get_string ("clock-format").contains ("12h")) {
                time_format.selected = 0;
            } else {
                time_format.selected = 1;
            }
        }
    }

    private void change_tz (string _tz) {
        var tz = _(_tz);
        var english_tz = _tz;

        time_zone_button.time_zone = tz;

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

        if (local_time.is_daylight_savings ()) {
            offset--;
        }
    }
}
