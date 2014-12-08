[DBus (name = "org.freedesktop.timedate1")]
interface DateTime1 : Object {
    public abstract string Timezone {public owned get;}
    public abstract bool LocalRTC {public get;}
    public abstract bool CanNTP {public get;}
    public abstract bool NTP {public get;}

    public abstract void set_time (int64 usec_utc, bool relative, bool user_interaction) throws IOError;
    public abstract void set_timezone (string timezone, bool user_interaction) throws IOError;
    public abstract void set_local_RTC (bool local_rtc, bool fix_system, bool user_interaction) throws IOError;
    public abstract void set_NTP (bool use_ntp, bool user_interaction) throws IOError;
}
