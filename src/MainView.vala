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

public class DateTime.MainView : Switchboard.SettingsPage {
    private TimeZoneGrid time_zone_picker;
    private DateTime1 datetime1;
    private CurrentTimeManager ct_manager;
    private GLib.Settings clock_settings;
    private Gtk.CheckButton meridiem_time_format;
    private Gtk.CheckButton military_time_format;
    private Pantheon.AccountsService? pantheon_act = null;

    private static GLib.Settings time_zone_settings;

    public MainView () {
        Object (
            icon: new ThemedIcon ("preferences-system-time"),
            title: _("Date & Time")
        );
    }

    static construct {
        time_zone_settings = new GLib.Settings ("org.gnome.desktop.datetime");
    }

    construct {
        var appearance_header = new Granite.HeaderLabel (_("Appearance"));

        var time_format_label = new Gtk.Label (_("Time format:")) {
            halign = Gtk.Align.END
        };

        meridiem_time_format = new Gtk.CheckButton.with_label (_("AM/PM"));

        military_time_format = new Gtk.CheckButton.with_label (_("24-hour")) {
            group = meridiem_time_format
        };

        var time_format_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        time_format_box.append (meridiem_time_format);
        time_format_box.append (military_time_format);

        var time_zone_label = new Granite.HeaderLabel (_("Time Zone"));

        var auto_time_zone_icon = new Gtk.Image.from_icon_name ("location-inactive-symbolic") {
            pixel_size = 24
        };
        auto_time_zone_icon.add_css_class (Granite.STYLE_CLASS_ACCENT);
        auto_time_zone_icon.add_css_class ("purple");

        var auto_time_zone_label = new Gtk.Label (_("Based on location")) {
            halign = Gtk.Align.START
        };

        var auto_time_zone_hint = new Gtk.Label (_("Automatically updates the time zone when activated")) {
            halign = Gtk.Align.START,
            wrap = true
        };
        auto_time_zone_hint.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        auto_time_zone_hint.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var auto_time_zone_radio = new Gtk.CheckButton ();

        var auto_time_zone_grid = new Gtk.Grid () {
            column_spacing = 3,
            margin_start = 3
        };
        auto_time_zone_grid.attach (auto_time_zone_icon, 0, 0, 1, 2);
        auto_time_zone_grid.attach (auto_time_zone_label, 1, 0);
        auto_time_zone_grid.attach (auto_time_zone_hint, 1, 1);
        auto_time_zone_grid.set_parent (auto_time_zone_radio);

        var manual_time_zone_radio = new Gtk.CheckButton () {
            group = auto_time_zone_radio
        };

        time_zone_picker = new DateTime.TimeZoneGrid () {
            margin_start = 6
        };
        time_zone_picker.set_parent (manual_time_zone_radio);

        var date_time_header = new Granite.HeaderLabel (_("Date & Time"));

        var network_time_radio = new Gtk.CheckButton.with_label (_("Set automatically"));

        var manual_time_radio = new Gtk.CheckButton () {
            group = network_time_radio
        };

        var time_picker = new Granite.TimePicker () {
            hexpand = true
        };
        var date_picker = new Granite.DatePicker ();

        var manual_time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            homogeneous = true,
            margin_start = 6
        };
        manual_time_box.append (time_picker);
        manual_time_box.append (date_picker);
        manual_time_box.set_parent (manual_time_radio);

        var week_number_switch = new Gtk.Switch () {
            valign = CENTER
        };

        var week_number_label = new Granite.HeaderLabel (_("Show Week Numbers")) {
            hexpand = true,
            mnemonic_widget = week_number_switch,
            secondary_text = _("e.g. in Calendar and the Date &amp; Time Panel indicator")
        };

        var week_number_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        week_number_box.append (week_number_label);
        week_number_box.append (week_number_switch);

        var panel_label = new Gtk.Label (_("Show in Panel:")) {
            halign = Gtk.Align.END
        };

        var date_check = new Gtk.CheckButton.with_label (_("Date"));
        var weekday_check = new Gtk.CheckButton.with_label (_("Day of the week"));
        var seconds_check = new Gtk.CheckButton.with_label (_("Seconds"));

        var panel_check_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);

        panel_check_box.append (date_check);
        panel_check_box.append (weekday_check);
        panel_check_box.append (seconds_check);

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 12
        };
        grid.attach (appearance_header, 0, 0, 2);
        grid.attach (time_format_label, 0, 1);
        grid.attach (time_format_box, 1, 1);
        grid.attach (panel_label, 0, 2);
        grid.attach (panel_check_box, 1, 2);
        grid.attach (week_number_box, 0, 3, 2);
        grid.attach (time_zone_label, 0, 4, 2);
        grid.attach (auto_time_zone_radio, 0, 5, 2);
        grid.attach (manual_time_zone_radio, 0, 6, 2);
        grid.attach (date_time_header, 0, 7, 2);
        grid.attach (network_time_radio, 0, 8, 2);
        grid.attach (manual_time_radio, 0, 9, 2);

        child = grid;

        var source = SettingsSchemaSource.get_default ();
        var schema = source.lookup ("io.elementary.desktop.wingpanel.datetime", true);

        GLib.Settings wingpanel_settings = null;

        if (schema == null) {
            grid.remove (week_number_box);
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

        try {
            datetime1 = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.timedate1", "/org/freedesktop/timedate1");

            if (datetime1.CanNTP == false) {
                network_time_radio.sensitive = false;
            } else if (datetime1.NTP) {
                network_time_radio.active = true;
            }
        } catch (IOError e) {
            critical (e.message);
        }

        network_time_radio.toggled.connect (() => {
            try {
                datetime1.SetNTP (network_time_radio.active, true);
                ct_manager.datetime_has_changed ();
            } catch (Error e) {
                manual_time_radio.activate ();
                critical (e.message);
            }
        });

        change_tz (datetime1.Timezone);

        network_time_radio.bind_property ("active", manual_time_box, "sensitive", BindingFlags.INVERT_BOOLEAN | BindingFlags.SYNC_CREATE);
        auto_time_zone_radio.bind_property ("active", manual_time_zone_radio, "active", BindingFlags.INVERT_BOOLEAN | BindingFlags.SYNC_CREATE);

        time_zone_settings.bind ("automatic-timezone", auto_time_zone_radio, "active", SettingsBindFlags.DEFAULT);
        time_zone_settings.bind ("automatic-timezone", time_zone_picker, "sensitive", SettingsBindFlags.INVERT_BOOLEAN);

        time_zone_settings.bind_with_mapping ("automatic-timezone", auto_time_zone_icon, "icon-name", GET,
            (value, variant, user_data) => {
                value.set_string (variant.get_boolean () ? "location-active-symbolic" : "location-inactive-symbolic");
                return true;
            }, () => { return true; }, null, null
        );
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
        time_zone_picker.time_zone = _tz;

        if (datetime1.Timezone != _tz) {
            try {
                datetime1.set_timezone (_tz, true);
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
}
