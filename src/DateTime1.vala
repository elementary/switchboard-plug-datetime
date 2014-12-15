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

[DBus (name = "org.freedesktop.timedate1")]
interface DateTime1 : Object {
    public abstract string Timezone {public owned get;}
    public abstract bool LocalRTC {public get;}
    public abstract bool CanNTP {public get;}
    public abstract bool NTP {public get;}

    //usec_utc expects number of microseconds since 1 Jan 1970 UTC
    public abstract void set_time (int64 usec_utc, bool relative, bool user_interaction) throws IOError;
    public abstract void set_timezone (string timezone, bool user_interaction) throws IOError;
    public abstract void SetLocalRTC (bool local_rtc, bool fix_system, bool user_interaction) throws IOError;
    public abstract void SetNTP (bool use_ntp, bool user_interaction) throws IOError;
}


public class DateTime.Settings : Granite.Services.Settings {

    public string clock_format { get; set; }

    public Settings () {
        base ("org.gnome.desktop.interface");
    }
}
