/*-
 * Copyright 2014-2024 elementary, Inc. (https://elementary.io)
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

public class DateTime.TimeZoneGrid : Gtk.Box {
    public signal void request_timezone_change (string tz);

    // Enum representation of "clock-format" key in org.gnome.desktop.interface GSettings
    enum ClockFormat {
        24_H,
        12_H
    }

    private Gtk.DropDown dropdown;
    private ListStore timezone_list;
    private string time_format;

    private string _time_zone;
    public string time_zone {
        get {
            return _time_zone;
        }
        set {
            for (int i = 0; i < timezone_list.get_n_items (); i++) {
                if (((ICal.Timezone) timezone_list.get_item (i)).get_display_name () == value) {
                    dropdown.selected = i;
                    break;
                }
            }

            _time_zone = value;
        }
    }

    ~TimeZoneGrid () {
        ICal.Timezone.free_builtin_timezones ();
    }

    construct {
        time_format = Granite.DateTime.get_default_time_format (
            new Settings ("org.gnome.desktop.interface").get_enum ("clock-format") == ClockFormat.12_H,
            false
        );

        timezone_list = new ListStore (typeof (ICal.Timezone));

        var timezone_array = ICal.Timezone.get_builtin_timezones ();
        for (int i = 0; i < timezone_array.size (); i++) {
            timezone_list.insert_sorted (timezone_array.timezone_element_at (i), (a, b) => {
                var a_name = ((ICal.Timezone) a).get_display_name ();
                var b_name = ((ICal.Timezone) b).get_display_name ();

                return a_name.collate (b_name);
            });
        }

        var expression = new Gtk.CClosureExpression (
            typeof (string),
            null,
            {},
            (Callback) get_timezone_name,
            null,
            null
        );

        var list_factory = new Gtk.SignalListItemFactory ();
        list_factory.setup.connect (setup_factory);
        list_factory.bind.connect (bind_factory);

        dropdown = new Gtk.DropDown (timezone_list, null) {
            enable_search = true,
            expression = expression,
            factory = list_factory,
            hexpand = true,
            search_match_mode = SUBSTRING
        };

        append (dropdown);

        dropdown.notify["selected"].connect (() => {
            var timezone = (ICal.Timezone) dropdown.get_selected_item ();
            request_timezone_change (timezone.get_display_name ());
        });
    }

    static string get_timezone_name (ICal.Timezone timezone) {
        return Parser.format_city (timezone.get_display_name ());
    }

    private void setup_factory (Object object) {
        var title = new Gtk.Label ("");

        var time = new Gtk.Label ("") {
            halign = END,
            hexpand = true,
            use_markup = true
        };
        time.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.append (title);
        box.append (time);

        var list_item = object as Gtk.ListItem;
        list_item.set_data ("title", title);
        list_item.set_data ("time", time);
        list_item.set_child (box);
    }

    private void bind_factory (Object object) {
        var list_item = object as Gtk.ListItem;

        var ical_timezone = (ICal.Timezone) list_item.get_item ();

        var title = list_item.get_data<Gtk.Label> ("title");
        try {
            var glib_timezone = new TimeZone.identifier (ical_timezone.get_display_name ());

            var datetime = new GLib.DateTime.now (glib_timezone);

            var offset = glib_timezone.get_offset (
                glib_timezone.find_interval (UNIVERSAL, datetime.to_unix ())
            );

            // TRANSLATORS: The first "%s" represents the timezone name
            // and the second "%s" represents the offset from UTC.
            // e.g. "America, Santiago (UTC - 4:00)"
            title.label = _("%s (%s)").printf (
                Parser.format_city (ical_timezone.get_display_name ()),
                seconds_to_utc_offset (offset)
            );

            var time = list_item.get_data<Gtk.Label> ("time");
            time.label = "<span font-features='tnum'>%s</span>".printf (datetime.format (time_format));
        } catch (Error e) {
            warning (e.message);
            title.label = Parser.format_city (ical_timezone.get_display_name ());
        }
    }

    private string seconds_to_utc_offset (int seconds) {
        if (seconds == 0) {
            return _("UTC");
        }

        var hours = seconds / 3600;
        var minutes = seconds % 3600 / 60;

        if (hours > 0) {
            return _("UTC +%i:%02i").printf (hours, minutes);
        }

        // Make sure we use typographical minus
        return _("UTC −%i:%02i").printf (hours.abs (), minutes.abs ());
    }
}
