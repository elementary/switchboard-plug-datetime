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

public class DateTime.Plug : Switchboard.Plug {
    private MainView main_view;

    public Plug () {
        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("time", null);
        settings.set ("date", null);
        Object (category: Category.SYSTEM,
            code_name: "io.elementary.switchboard.datetime",
            display_name: _("Date & Time"),
            description: _("Configure date, time, and select time zone"),
            icon: "preferences-system-time",
            supported_settings: settings);
    }

    public override Gtk.Widget get_widget () {
        if (main_view == null) {
            main_view = new DateTime.MainView ();
        }

        return main_view;
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
        search_results.set ("%s → %s".printf (display_name, _("Time Format")), "");
        search_results.set ("%s → %s".printf (display_name, _("Time Zone")), "");
        search_results.set ("%s → %s".printf (display_name, _("Network Time")), "");
        search_results.set ("%s → %s".printf (display_name, _("Show week numbers")), "");
        return search_results;
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Date & Time plug");
    var plug = new DateTime.Plug ();
    return plug;
}
