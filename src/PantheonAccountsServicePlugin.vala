[DBus (name = "io.elementary.pantheon.AccountsService")]
interface DateTime.Pantheon.AccountsService : Object {
    public abstract string time_format { owned get; set; }
}

[DBus (name = "org.freedesktop.Accounts")]
interface DateTime.FDO.Accounts : Object {
    public abstract string find_user_by_name (string username) throws GLib.Error;
}
