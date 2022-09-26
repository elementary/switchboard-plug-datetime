/*-
 * Copyright (c) 2014 elementary, Inc. (https://elementary.io)
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
    Gtk.TreeView city_view;
    Gtk.ListStore city_list_store;

    private Gtk.ComboBoxText continent_combo;

    string old_selection;
    string current_tz;
    bool setting_cities = false;

    public string time_zone {
        set {
            set_timezone (value);
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
        city_view = new Gtk.TreeView.with_model (city_list_store) {
            headers_visible = false,
            hexpand = true
        };

        var city_cellrenderer = new Gtk.CellRendererText () {
            ellipsize_set = true,
            width_chars = 50,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            ellipsize = Pango.EllipsizeMode.END
        };
        city_view.insert_column_with_attributes (-1, null, city_cellrenderer, "text", 0);
        city_view.get_selection ().changed.connect (() => {
            if (setting_cities == true)
                return;

            Gtk.TreeIter activated_iter;
            if (city_view.get_selection ().get_selected (null, out activated_iter)) {
                Value value;
                city_list_store.get_value (activated_iter, 1, out value);
                request_timezone_change (value.get_string ());
                current_tz = value.get_string ();
            }
        });

        var city_scrolled = new Gtk.ScrolledWindow () {
            child = city_view,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.AUTOMATIC
        };

        spacing = 12;
        append (continent_combo);
        append (city_scrolled);

        continent_combo.changed.connect (() => {
            if (old_selection != continent_combo.active_id) {
                change_city_from_continent (continent_combo.active_id);
                old_selection = continent_combo.active_id;
            }
        });
    }

    public void set_timezone (string tz) {
        current_tz = tz;
        var values = tz.split ("/", 3);

        continent_combo.active_id = values[0];
    }

    private void change_city_from_continent (string continent) {
        setting_cities = true;
        city_list_store.clear ();
        Parser.get_default ().get_timezones_from_continent (continent).foreach ((key, value) => {
            Gtk.TreeIter iter;
            city_list_store.append (out iter);
            city_list_store.set (iter, 0, key, 1, value);
            if (current_tz == value) {
                city_view.get_selection ().select_iter (iter);
                city_view.scroll_to_cell (city_list_store.get_path (iter), null, true, 0, 0);
            }
        });

        setting_cities = false;
    }
}
