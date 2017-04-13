/*
* Copyright (c) 2014-2017 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
 * Authored by: Corentin Noël <corentin@elementary.io>
*/

public class TimeZoneButton : Gtk.Button {
    public Gtk.Label continent_label;
    public Gtk.Label city_label;

    construct {
        continent_label = new Gtk.Label (null);
        continent_label.xalign = 1;

        city_label = new Gtk.Label (null);
        city_label.xalign = 0;

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        size_group.add_widget (continent_label);
        size_group.add_widget (city_label);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.halign = Gtk.Align.CENTER;
        grid.add (continent_label);
        grid.add (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        grid.add (city_label);

        add (grid);
    }
}
