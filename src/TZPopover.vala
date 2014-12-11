public class DateTime.TZPopover : Gtk.Popover {
    private const string AFRICA = "Africa";
    private const string AMERICA = "America";
    private const string ANTARTICA = "Antarctica";
    private const string ASIA = "Asia";
    private const string ATLANTIC = "Atlantic";
    private const string EUROPE = "Europe";
    private const string INDIAN = "Indian";
    private const string PACIFIC = "Pacific";
    Gtk.TreeView continent_view;
    Gtk.ListStore continent_list_store;
    Gtk.TreeView city_view;
    Gtk.ListStore city_list_store;
    DateTime.Parser parser;
    public TZPopover () {
        var main_grid = new Gtk.Grid ();
        add (main_grid);
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
        continent_list_store.set (iter, 0, _("Europe"), 1, EUROPE);
        continent_list_store.append (out iter);
        continent_list_store.set (iter, 0, _("Indian"), 1, INDIAN);
        continent_list_store.append (out iter);
        continent_list_store.set (iter, 0, _("Pacific"), 1, PACIFIC);

        continent_view = new Gtk.TreeView.with_model (continent_list_store);
        continent_view.activate_on_single_click = true;
        continent_view.headers_visible = false;
        continent_view.insert_column_with_attributes (-1, null, new Gtk.CellRendererText (), "text", 0);
        continent_view.row_activated.connect ((path, column) => {
            Gtk.TreeIter activated_iter;
            continent_list_store.get_iter (out activated_iter, path);
            Value value;
            continent_list_store.get_value (activated_iter, 1, out value);
            change_city_from_continent (value.get_string ());
        });

        var continent_scrolled = new Gtk.ScrolledWindow (null, null);
        continent_scrolled.add (continent_view);
        continent_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;

        parser = new DateTime.Parser ();
        city_list_store = new Gtk.ListStore (2, typeof (string), typeof (string));
        city_list_store.set_default_sort_func ((model, a, b) => {
            Value value_a;
            Value value_b;
            model.get_value (a, 0, out value_a);
            model.get_value (b, 0, out value_b);
            return value_a.get_string ().collate (value_b.get_string ());
        });

        city_list_store.set_sort_column_id (Gtk.TREE_SORTABLE_DEFAULT_SORT_COLUMN_ID, Gtk.SortType.ASCENDING);
        parser.get_timezones ().foreach ((key, value) => {
            city_list_store.append (out iter);
            city_list_store.set (iter, 0, key, 1, value);
        });

        city_view = new Gtk.TreeView.with_model (city_list_store);
        city_view.headers_visible = false;
        city_view.insert_column_with_attributes (-1, null, new Gtk.CellRendererText (), "text", 0);
        var city_scrolled = new Gtk.ScrolledWindow (null, null);
        city_scrolled.add (city_view);
        city_scrolled.set_size_request (250, 200);

        main_grid.add (continent_scrolled);
        main_grid.add (city_scrolled);

    }

    private void change_city_from_continent (string continent) {
        city_list_store.clear ();
        parser.get_timezones_from_continent (continent).foreach ((key, value) => {
            Gtk.TreeIter iter;
            city_list_store.append (out iter);
            city_list_store.set (iter, 0, key, 1, value);
        });
    }
}

public class DateTime.Parser : GLib.Object {
    List<string> lines;
    public Parser () {
        var file = File.new_for_path ("/usr/share/zoneinfo/zone.tab");
        if (!file.query_exists ()) {
            critical ("/usr/share/zoneinfo/zone.tab doesn't exist !");
            return;
        }

        lines = new List<string> ();
        try {
            var dis = new DataInputStream (file.read ());
            string line;
            while ((line = dis.read_line (null)) != null) {
                if (line.has_prefix ("#")) {
                    continue;
                }

                lines.append (line);
            }
        } catch (Error e) {
            critical (e.message);
        }
    }

    public HashTable<string, string> get_timezones () {
        var timezones = new HashTable<string, string> (str_hash, str_equal);
        foreach (var line in lines) {
            var items = line.split ("\t", 4);
            string key;
            string value = items[2];
            if (items[3] != null) {
                key = items[3];
            } else {
                key = items[2].split ("/", 2)[1];
            }

            timezones.set (key, value);
        }

        return timezones;
    }

    public HashTable<string, string> get_timezones_from_continent (string continent) {
        var timezones = new HashTable<string, string> (str_hash, str_equal);
        foreach (var line in lines) {
            var items = line.split ("\t", 4);
            string value = items[2];
            if (value.has_prefix (continent) == false)
                continue;

            string key;
            if (items[3] != null) {
                key = items[3];
            } else {
                key = items[2].split ("/", 2)[1];
            }

            timezones.set (key, value);
        }

        return timezones;
    }
}
