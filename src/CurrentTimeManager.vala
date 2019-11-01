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

public class DateTime.CurrentTimeManager : GLib.Object {
    public signal void time_has_changed (GLib.DateTime dt);
    private uint timeout = 0;
    private GLib.DateTime very_next_minute;
    public CurrentTimeManager () {
        create_next_minute_timeout ();
    }

    public void timezone_has_changed () {
        var now_local = new GLib.DateTime.now_local ();
        time_has_changed (now_local);
        create_next_minute_timeout ();
    }

    public void datetime_has_changed () {
        create_next_minute_timeout ();
    }

    private void create_next_minute_timeout () {
        if (timeout != 0)
            GLib.Source.remove (timeout);

        var now_local = new GLib.DateTime.now_local ();
        very_next_minute = now_local.add_seconds (-now_local.get_seconds ()).add_minutes (1);
        var timespan = very_next_minute.difference (now_local);
        timeout = Timeout.add ((uint) (timespan / 1000), () => {
            time_has_changed (very_next_minute);
            timeout = 0;
            create_next_minute_timeout ();
            return false;
        });
    }
}
