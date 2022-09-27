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

    private const string AFRICA = "Africa";
    private const string AMERICA = "America";
    private const string ANTARTICA = "Antarctica";
    private const string ASIA = "Asia";
    private const string ATLANTIC = "Atlantic";
    private const string AUSTRALIA = "Australia";
    private const string EUROPE = "Europe";
    private const string INDIAN = "Indian";
    private const string PACIFIC = "Pacific";

    private Gtk.ComboBoxText continent_combo;
    private Granite.ValidatedEntry timezone_entry;
    private Gtk.ListStore city_list_store;

    private string old_selection;
    private bool setting_cities = false;

    private string _time_zone;
    public string time_zone {
        get {
            return _time_zone;
        }
        set {
            _time_zone = value;
            var values = value.split ("/", 3);

            if (continent_combo.active_id != values[0]) {
                continent_combo.active_id = values[0];
            }
        }
    }

    public TimeZoneGrid () {
        continent_combo = new Gtk.ComboBoxText ();
        continent_combo.append (AFRICA, _("Africa"));
        continent_combo.append (AMERICA, _("America"));
        continent_combo.append (ANTARTICA, _("Antarctica"));
        continent_combo.append (ASIA, _("Asia"));
        continent_combo.append (ATLANTIC, _("Atlantic"));
        continent_combo.append (AUSTRALIA, _("Australia"));
        continent_combo.append (EUROPE, _("Europe"));
        continent_combo.append (INDIAN, _("Indian"));
        continent_combo.append (PACIFIC, _("Pacific"));

        city_list_store = new Gtk.ListStore (2, typeof (string), typeof (string));
        city_list_store.set_default_sort_func ((model, a, b) => {
            Value value_a;
            Value value_b;
            model.get_value (a, 0, out value_a);
            model.get_value (b, 0, out value_b);
            return value_a.get_string ().collate (value_b.get_string ());
        });

        city_list_store.set_sort_column_id (Gtk.TREE_SORTABLE_DEFAULT_SORT_COLUMN_ID, Gtk.SortType.ASCENDING);

        var entry_completion = new Gtk.EntryCompletion () {
            minimum_key_length = 0,
            model = city_list_store,
            popup_completion = true,
            text_column = 0
        };

        timezone_entry = new Granite.ValidatedEntry () {
            completion = entry_completion,
            hexpand = true,
            placeholder_text = _("City or time zone name")
        };

        spacing = 12;
        append (continent_combo);
        append (timezone_entry);

        continent_combo.changed.connect (() => {
            if (old_selection != continent_combo.active_id) {
                change_city_from_continent (continent_combo.active_id);
                old_selection = continent_combo.active_id;
            }
        });

        timezone_entry.changed.connect (() => {
            if (setting_cities) {
                return;
            }

            city_list_store.@foreach ((model, path, iter) => {
                 Value value;
                 model.get_value (iter, 0, out value);

                 if (timezone_entry.text == value.get_string ()) {
                    Value key;
                    model.get_value (iter, 1, out key);

                    timezone_entry.is_valid = true;

                    time_zone = key.get_string ();
                    request_timezone_change (time_zone);
                    return true;
                 } else {
                     timezone_entry.is_valid = false;
                 }

                 return false;
             });
        });
    }

    private void change_city_from_continent (string continent) {
        setting_cities = true;
        city_list_store.clear ();

        Parser.get_default ().get_timezones_from_continent (continent).foreach ((key, value) => {
            Gtk.TreeIter iter;
            city_list_store.append (out iter);
            city_list_store.set (iter, 0, key, 1, value);

            if (time_zone == value) {
                timezone_entry.text = key;
            }
        });

        setting_cities = false;
    }
}
