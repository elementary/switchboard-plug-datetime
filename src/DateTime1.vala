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
