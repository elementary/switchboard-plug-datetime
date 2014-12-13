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
        timeout = Timeout.add ((uint) (timespan/1000), () => {
            time_has_changed (very_next_minute);
            timeout = 0;
            create_next_minute_timeout ();
            return false;
        });
    }
}
