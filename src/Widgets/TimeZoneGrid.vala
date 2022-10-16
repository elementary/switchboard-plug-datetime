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

    private string _time_zone;
    public string time_zone {
        get {
            return _time_zone;
        }
        set {
            _time_zone = value;
        }
    }

    public TimeZoneGrid () {
        var timezone_list = new ListStore (typeof (ICal.Timezone));

        var timezone_array = ICal.Timezone.get_builtin_timezones ();
        for (int i = 0; i < timezone_array.size (); i++) {
            timezone_list.append (timezone_array.timezone_element_at (i));
        }

        var list_factory = new Gtk.SignalListItemFactory ();
        list_factory.setup.connect (setup_factory);
        list_factory.bind.connect (bind_factory);

        var dropdown = new Gtk.DropDown (timezone_list, null) {
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

    private void setup_factory (Gtk.SignalListItemFactory factory, Gtk.ListItem list_item) {
        var title = new Gtk.Label ("");

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.append (title);

        list_item.set_data ("title", title);
        list_item.set_child (box);
    }

    private void bind_factory (Gtk.SignalListItemFactory factory, Gtk.ListItem list_item) {
        var timezone = (ICal.Timezone) list_item.get_item ();
        var title = list_item.get_data<Gtk.Label>("title");

        title.label = timezone.get_display_name ();
    }
}
