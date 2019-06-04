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

public class DateTime.TimeZoneGrid : Gtk.Grid {
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
    Gtk.TreeView continent_view;
    Gtk.ListStore continent_list_store;
    Gtk.TreeView city_view;
    Gtk.ListStore city_list_store;
    string old_selection;
    string current_tz;
    bool setting_cities = false;

    public string time_zone {
        set {
            set_timezone (value);
        }
    }

    public TimeZoneGrid () {
        var main_grid = new Gtk.Grid ();
        continent_list_store = new Gtk.ListStore (2, typeof (string), typeof (string));
        continent_list_store.set_default_sort_func ((model, a, b) => {
            Value value_a;
            Value value_b;
            model.get_value (a, 0, out value_a);
            model.get_value (b, 0, out value_b);
            return value_a.get_string ().collate (value_b.get_string ());
        });

        continent_list_store.set_sort_column_id (Gtk.TREE_SORTABLE_DEFAULT_SORT_COLUMN_ID, Gtk.SortType.ASCENDING);
        Gtk.TreeIter iter;
        continent_list_store.append (out iter);
        continent_list_store.set (iter, 0, _("Africa"), 1, AFRICA);
        continent_list_store.append (out iter);
        continent_list_store.set (iter, 0, _("America"), 1, AMERICA);
        continent_list_store.append (out iter);
        continent_list_store.set (iter, 0, _("Antarctica"), 1, ANTARTICA);
        continent_list_store.append (out iter);
        continent_list_store.set (iter, 0, _("Asia"), 1, ASIA);
        continent_list_store.append (out iter);
        continent_list_store.set (iter, 0, _("Atlantic"), 1, ATLANTIC);
        continent_list_store.append (out iter);
        continent_list_store.set (iter, 0, _("Australia"), 1, AUSTRALIA);
        continent_list_store.append (out iter);
        continent_list_store.set (iter, 0, _("Europe"), 1, EUROPE);
        continent_list_store.append (out iter);
        continent_list_store.set (iter, 0, _("Indian"), 1, INDIAN);
        continent_list_store.append (out iter);
        continent_list_store.set (iter, 0, _("Pacific"), 1, PACIFIC);

        continent_view = new Gtk.TreeView.with_model (continent_list_store);
        continent_view.get_style_context ().add_class ("sidebar");
        continent_view.headers_visible = false;
        continent_view.get_selection ().mode = Gtk.SelectionMode.BROWSE;

        var cellrenderer = new Gtk.CellRendererText ();
        cellrenderer.xpad = 12;
        continent_view.insert_column_with_attributes (-1, null, cellrenderer, "text", 0);
        continent_view.get_selection ().changed.connect (() => {
            Gtk.TreeIter activated_iter;
            if (continent_view.get_selection ().get_selected (null, out activated_iter)) {
                Value value;
                continent_list_store.get_value (activated_iter, 1, out value);
                if (old_selection != value.get_string ()) {
                    change_city_from_continent (value.get_string ());
                    old_selection = value.get_string ();
                }
            }
        });

        city_list_store = new Gtk.ListStore (2, typeof (string), typeof (string));
        city_list_store.set_default_sort_func ((model, a, b) => {
            Value value_a;
            Value value_b;
            model.get_value (a, 0, out value_a);
            model.get_value (b, 0, out value_b);
            return value_a.get_string ().collate (value_b.get_string ());
        });

        city_list_store.set_sort_column_id (Gtk.TREE_SORTABLE_DEFAULT_SORT_COLUMN_ID, Gtk.SortType.ASCENDING);
        city_view = new Gtk.TreeView.with_model (city_list_store);
        city_view.headers_visible = false;

        var city_cellrenderer = new Gtk.CellRendererText ();
        city_cellrenderer.ellipsize_set = true;
        city_cellrenderer.width_chars = 50;
        city_cellrenderer.wrap_mode = Pango.WrapMode.WORD_CHAR;
        city_cellrenderer.ellipsize = Pango.EllipsizeMode.END;
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

        var city_scrolled = new Gtk.ScrolledWindow (null, null);
        city_scrolled.add (city_view);
        city_scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

        main_grid.add (continent_view);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        main_grid.add (city_scrolled);
        main_grid.show_all ();

        add (main_grid);
    }

    public void set_timezone (string tz) {
        current_tz = tz;
        var values = tz.split ("/", 3);
        continent_list_store.@foreach ((model, path, iter) => {
            Value value;
            model.get_value (iter, 1, out value);
            if (values[0] == value.get_string ()) {
                continent_view.get_selection ().select_iter (iter);
                city_view.scroll_to_cell (city_list_store.get_path (iter), null, false, 0, 0);
                return true;
            }

            return false;
        });
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
                city_view.scroll_to_cell (city_list_store.get_path (iter), null, false, 0, 0);
            }
        });

        setting_cities = false;
    }
}

