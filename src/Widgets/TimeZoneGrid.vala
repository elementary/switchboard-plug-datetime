/*-
 * Copyright 2014-2022 elementary, Inc. (https://elementary.io)
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

    private Gtk.DropDown dropdown;
    private ListStore timezone_list;

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

    public TimeZoneGrid () {
        timezone_list = new ListStore (typeof (ICal.Timezone));

        var timezone_array = ICal.Timezone.get_builtin_timezones ();
        for (int i = 0; i < timezone_array.size (); i++) {
            timezone_list.insert_sorted (timezone_array.timezone_element_at (i), (a, b) => {
                var a_name = ((ICal.Timezone) a).get_display_name ();
                var b_name = ((ICal.Timezone) b).get_display_name ();

                return a_name.collate (b_name);
            });
        }

        var expression = new Gtk.CClosureExpression (typeof (string), null, null, (Callback) get_timezone_name, null, null);

        var list_factory = new Gtk.SignalListItemFactory ();
        list_factory.setup.connect (setup_factory);
        list_factory.bind.connect (bind_factory);

        dropdown = new Gtk.DropDown (timezone_list, null) {
            expression = expression,
            factory = list_factory,
            enable_search = true,
            hexpand = true
        };

        append (dropdown);

        dropdown.notify["selected"].connect (() => {
            var timezone = (ICal.Timezone) dropdown.get_selected_item ();
            request_timezone_change (timezone.get_display_name ());
        });
    }

    static string get_timezone_name (ICal.Timezone timezone) {
        return timezone.get_display_name ();
    }

    private void setup_factory (Object object) {
        var title = new Gtk.Label ("");

        var time = new Gtk.Label ("") {
            halign = Gtk.Align.END,
            hexpand = true
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

        var timezone = (ICal.Timezone) list_item.get_item ();
        var title = list_item.get_data<Gtk.Label>("title");
        title.label = timezone.get_display_name ();

        var datetime = new GLib.DateTime.now (new TimeZone.identifier (timezone.get_display_name ()));

        var time = list_item.get_data<Gtk.Label>("time");
        time.label = datetime.format ("%X");
    }
}
