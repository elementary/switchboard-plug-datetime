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


public class DateTime.TimeMap : Gtk.EventBox {
    public const int BG_WIDTH = 768;
    public const int BG_HEIGHT = 382;
    public const string TZ = "%s/images/timezone_%s.svg";

    public signal void map_selected (string timezone);

    Gtk.Image background_map;
    Gtk.Image selected;
    public TimeMap () {
        background_map = new Gtk.Image.from_file ("%s/images/bg.svg".printf (Constants.PKGDATADIR));

        selected = new Gtk.Image ();

        var overlay = new Gtk.Overlay ();
        overlay.set_size_request (BG_WIDTH, BG_HEIGHT);
        overlay.add_overlay (background_map);
        overlay.add_overlay (selected);

        add (overlay);

        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        button_press_event.connect (map_clicked);
    }

    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        base.get_preferred_width (out minimum_width, out natural_width);
        minimum_width = BG_WIDTH/4;
        natural_width = BG_WIDTH;
    }

    public override void get_preferred_height (out int minimum_height, out int natural_height) {
        base.get_preferred_height (out minimum_height, out natural_height);
        minimum_height = BG_HEIGHT/3;
        natural_height = BG_HEIGHT;
    }

    public void switch_to_tz (float offset) {
        try {
            //This doesn't work if the locale representation of 3.5 is 3,5 for example.
            string buffer = "%g".printf (offset);
            buffer = buffer.replace (Posix.nl_langinfo (Posix.NLItem.RADIXCHAR), ".");
            selected.file = TZ.printf (Constants.PKGDATADIR, buffer);
        } catch (Error e) {
            critical (e.message);
        }
        queue_draw ();
    }

    private bool map_clicked (Gdk.EventButton event) {
        if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == Gdk.BUTTON_PRIMARY) {
            int x, y, width, height;
            get_current_background_properties (out x, out y, out width, out height);
            if (event.x < x || event.x > x+width || event.y > y+height || event.y < y)
                return false;

            var locations = Parser.get_default ().get_locations ();
            string location = "";
            double distance = BG_WIDTH*BG_WIDTH + BG_HEIGHT*BG_HEIGHT;
            locations.foreach ((key, val) => {
                double latitude, longitude;
                convert_string_to_longitude_latitude (key, out latitude, out longitude);
                var pointx = convert_longtitude_to_x (longitude, width);
                var pointy = convert_latitude_to_y (latitude, height);
                
                var dx = pointx - event.x + x;
                var dy = pointy - event.y + y;
                var dist = dx * dx + dy * dy;
                if (dist < distance) {
                    distance = dist;
                    location = val;
                }
            });

            if (location != "")
                map_selected (location);

            return true;
        }

        return false;
    }

    private void get_current_background_properties (out int x, out int y, out int draw_width, out int draw_height) {
        int total_width = get_allocated_width ();
        int total_height = get_allocated_height ();
        draw_width = BG_WIDTH;
        draw_height = BG_HEIGHT;
        double ratio = 1;
        x = (total_width - BG_WIDTH)/2;
        y = (total_height - BG_HEIGHT)/2;

        if (total_width < BG_WIDTH || total_height < BG_HEIGHT) {
            ratio = double.min ((double)total_width/(double)BG_WIDTH, (double)total_height/(double)BG_HEIGHT);
            draw_width = (int)(ratio*(double)BG_WIDTH);
            draw_height = (int)(ratio*(double)BG_HEIGHT);
            x = (total_width - draw_width)/2;
            y = (total_height - draw_height)/2;
        }
    }

    private void convert_string_to_longitude_latitude (string in_string, out double latitude, out double longitude) {
        bool first = true;
        string precedent_string = "";
        string latitude_str = "";
        string longitude_str = "";
        foreach (char c in in_string.to_utf8 ()) {
            if (c == '+' || c == '-') {
                if (precedent_string != "") {
                    if (first == true) {
                        latitude_str = precedent_string;
                    } else {
                        longitude_str = precedent_string;
                    }

                    precedent_string = "";
                }
            }

            precedent_string = "%s%c".printf (precedent_string, c);
        }

        if (precedent_string != "") {
            longitude_str = precedent_string;
        }

        // latitudes are xx.xxxx, longitudes are xxx.xxxx, but the file does store them as integer…
        latitude = double.parse (latitude_str) / GLib.Math.pow (10, latitude_str.length - 3);
        longitude = double.parse (longitude_str) / GLib.Math.pow (10, longitude_str.length - 4);
    }

    private double convert_longtitude_to_x (double longitude, int map_width) {
        double xdeg_offset = -6;
        double x = (map_width * (180.0 + longitude) / 360.0) + (map_width * xdeg_offset / 180.0);
        return x;
    }

    private double radians (double degrees) {
        return (degrees / 180.0) * GLib.Math.PI;
    }

    private double convert_latitude_to_y (double latitude, double map_height) {
        double bottom_lat = -59;
        double top_lat = 81;
        double top_per, y, full_range, top_offset, map_range;

        top_per = top_lat / 180.0;
        y = 1.25 * GLib.Math.log (GLib.Math.tan (GLib.Math.PI_4 + 0.4 * radians (latitude)));
        full_range = 4.6068250867599998;
        top_offset = full_range * top_per;
        map_range = GLib.Math.fabs (1.25 * GLib.Math.log (GLib.Math.tan (GLib.Math.PI_4 + 0.4 * radians (bottom_lat))) - top_offset);
        y = GLib.Math.fabs (y - top_offset);
        y = y / map_range;
        y = y * map_height;
        return y;
    }
}
