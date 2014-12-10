public class DateTime.TimeMap : Gtk.Grid {
    public const int BG_WIDTH = 800;
    public const int BG_HEIGHT = 409;
    public const string TZ0 = "%s/images/timezone_0.png";
    public const string TZ1 = "%s/images/timezone_1.png";
    public const string TZ2 = "%s/images/timezone_2.png";
    public const string TZ3 = "%s/images/timezone_3.png";
    public const string TZ35 = "%s/images/timezone_3.5.png";
    public const string TZ4 = "%s/images/timezone_4.png";
    public const string TZ45 = "%s/images/timezone_4.5.png";
    public const string TZ5 = "%s/images/timezone_5.png";
    public const string TZ55 = "%s/images/timezone_5.5.png";
    public const string TZ575 = "%s/images/timezone_5.75.png";
    public const string TZ6 = "%s/images/timezone_6.png";
    public const string TZ65 = "%s/images/timezone_6.5.png";
    public const string TZ7 = "%s/images/timezone_7.png";
    public const string TZ8 = "%s/images/timezone_8.png";
    public const string TZ875 = "%s/images/timezone_8.75.png";
    public const string TZ9 = "%s/images/timezone_9.png";
    public const string TZ95 = "%s/images/timezone_9.5.png";
    public const string TZ10 = "%s/images/timezone_10.png";
    public const string TZ105 = "%s/images/timezone_10.5.png";
    public const string TZ11 = "%s/images/timezone_11.png";
    public const string TZ115 = "%s/images/timezone_11.5.png";
    public const string TZ12 = "%s/images/timezone_12.png";
    public const string TZ125 = "%s/images/timezone_12.75.png";
    public const string TZ13 = "%s/images/timezone_13.png";
    public const string TZ14 = "%s/images/timezone_14.png";
    public const string TZm1 = "%s/images/timezone_-1.png";
    public const string TZm2 = "%s/images/timezone_-2.png";
    public const string TZm3 = "%s/images/timezone_-3.png";
    public const string TZm35 = "%s/images/timezone_-3.5.png";
    public const string TZm4 = "%s/images/timezone_-4.png";
    public const string TZm45 = "%s/images/timezone_-4.5.png";
    public const string TZm5 = "%s/images/timezone_-5.png";
    public const string TZm55 = "%s/images/timezone_-5.5.png";
    public const string TZm6 = "%s/images/timezone_-6.png";
    public const string TZm7 = "%s/images/timezone_-7.png";
    public const string TZm8 = "%s/images/timezone_-8.png";
    public const string TZm9 = "%s/images/timezone_-9.png";
    public const string TZm95 = "%s/images/timezone_-9.5.png";
    public const string TZm10 = "%s/images/timezone_-10.png";
    public const string TZm11 = "%s/images/timezone_-11.png";

    Gdk.Pixbuf background_map;
    Gdk.Pixbuf background_map_scale;
    Gdk.Pixbuf selected;
    Gdk.Pixbuf selected_scale;
    public TimeMap () {
        background_map = new Gdk.Pixbuf.from_file ("%s/images/bg.png".printf (Constants.PKGDATADIR));
        background_map_scale = background_map;
        switch_to_tz (5.75f);
        get_style_context ().add_class (Gtk.STYLE_CLASS_FRAME);
    }

    /* Widget is asked to draw itself */
    public override bool draw (Cairo.Context cr) {
        //base.draw (cr);
        int width = get_allocated_width ();
        int height = get_allocated_height ();
        int draw_width = BG_WIDTH;
        int draw_height = BG_HEIGHT;
        double ratio = 1;
        int x = (width - BG_WIDTH)/2;
        int y = (height - BG_HEIGHT)/2;

        if ((width < BG_WIDTH) || (height < BG_HEIGHT)) {
            ratio = double.min ((double)width/(double)BG_WIDTH, (double)height/(double)BG_HEIGHT);
            draw_width = (int)(ratio*(double)BG_WIDTH);
            draw_height = (int)(ratio*(double)BG_HEIGHT);
            background_map_scale = background_map.scale_simple (draw_width, draw_height, Gdk.InterpType.BILINEAR);
            selected_scale = selected.scale_simple (draw_width, draw_height, Gdk.InterpType.BILINEAR);
            x = (width - draw_width)/2;
            y = (height - draw_height)/2;
        } else if (width >= BG_WIDTH && height >= BG_HEIGHT) {
            background_map_scale = background_map;
            selected_scale = selected;
        }

        if (x < 0)
            x = 0;
        if (y < 0)
            y = 0;
        cr.set_operator (Cairo.Operator.OVER);
        Gdk.cairo_set_source_pixbuf (cr, background_map_scale, x, y);
        cr.paint ();
        Gdk.cairo_set_source_pixbuf (cr, selected_scale, x, y);
        cr.paint ();
        get_style_context ().render_frame (cr, x, y, draw_width, draw_height);

        return false;
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
            switch ((int)offset) {
                case 1:
                    selected = new Gdk.Pixbuf.from_file (TZ1.printf (Constants.PKGDATADIR));
                    break;
                case 2:
                    selected = new Gdk.Pixbuf.from_file (TZ2.printf (Constants.PKGDATADIR));
                    break;
                case 3:
                    if (offset == 3)
                        selected = new Gdk.Pixbuf.from_file (TZ3.printf (Constants.PKGDATADIR));
                    else
                        selected = new Gdk.Pixbuf.from_file (TZ35.printf (Constants.PKGDATADIR));
                    break;
                case 4:
                    if (offset == 4)
                        selected = new Gdk.Pixbuf.from_file (TZ4.printf (Constants.PKGDATADIR));
                    else
                        selected = new Gdk.Pixbuf.from_file (TZ45.printf (Constants.PKGDATADIR));
                    break;
                case 5:
                    if (offset == 5)
                        selected = new Gdk.Pixbuf.from_file (TZ5.printf (Constants.PKGDATADIR));
                    else if (offset == 5.5)
                        selected = new Gdk.Pixbuf.from_file (TZ55.printf (Constants.PKGDATADIR));
                    else
                        selected = new Gdk.Pixbuf.from_file (TZ575.printf (Constants.PKGDATADIR));
                    break;
                case 6:
                    if (offset == 6)
                        selected = new Gdk.Pixbuf.from_file (TZ6.printf (Constants.PKGDATADIR));
                    else
                        selected = new Gdk.Pixbuf.from_file (TZ65.printf (Constants.PKGDATADIR));
                    break;
                case 7:
                    selected = new Gdk.Pixbuf.from_file (TZ7.printf (Constants.PKGDATADIR));
                    break;
                case 8:
                    if (offset == 8)
                        selected = new Gdk.Pixbuf.from_file (TZ8.printf (Constants.PKGDATADIR));
                    else
                        selected = new Gdk.Pixbuf.from_file (TZ875.printf (Constants.PKGDATADIR));
                    break;
                case 9:
                    if (offset == 9)
                        selected = new Gdk.Pixbuf.from_file (TZ9.printf (Constants.PKGDATADIR));
                    else
                        selected = new Gdk.Pixbuf.from_file (TZ95.printf (Constants.PKGDATADIR));
                    break;
                case 10:
                    if (offset == 10)
                        selected = new Gdk.Pixbuf.from_file (TZ10.printf (Constants.PKGDATADIR));
                    else
                        selected = new Gdk.Pixbuf.from_file (TZ105.printf (Constants.PKGDATADIR));
                    break;
                case 11:
                    if (offset == 11)
                        selected = new Gdk.Pixbuf.from_file (TZ11.printf (Constants.PKGDATADIR));
                    else
                        selected = new Gdk.Pixbuf.from_file (TZ115.printf (Constants.PKGDATADIR));
                    break;
                case 12:
                    if (offset == 12)
                        selected = new Gdk.Pixbuf.from_file (TZ12.printf (Constants.PKGDATADIR));
                    else
                        selected = new Gdk.Pixbuf.from_file (TZ125.printf (Constants.PKGDATADIR));
                    break;
                case 13:
                    selected = new Gdk.Pixbuf.from_file (TZ13.printf (Constants.PKGDATADIR));
                    break;
                case 14:
                    selected = new Gdk.Pixbuf.from_file (TZ14.printf (Constants.PKGDATADIR));
                    break;
                case -1:
                    selected = new Gdk.Pixbuf.from_file (TZm1.printf (Constants.PKGDATADIR));
                    break;
                case -2:
                    selected = new Gdk.Pixbuf.from_file (TZm2.printf (Constants.PKGDATADIR));
                    break;
                case -3:
                    if (offset == -3)
                        selected = new Gdk.Pixbuf.from_file (TZm3.printf (Constants.PKGDATADIR));
                    else
                        selected = new Gdk.Pixbuf.from_file (TZm35.printf (Constants.PKGDATADIR));
                    break;
                case -4:
                    if (offset == -4)
                        selected = new Gdk.Pixbuf.from_file (TZm4.printf (Constants.PKGDATADIR));
                    else
                        selected = new Gdk.Pixbuf.from_file (TZm45.printf (Constants.PKGDATADIR));
                    break;
                case -5:
                    if (offset == -5)
                        selected = new Gdk.Pixbuf.from_file (TZm5.printf (Constants.PKGDATADIR));
                    else
                        selected = new Gdk.Pixbuf.from_file (TZm55.printf (Constants.PKGDATADIR));
                    break;
                case -6:
                    selected = new Gdk.Pixbuf.from_file (TZm6.printf (Constants.PKGDATADIR));
                    break;
                case -7:
                    selected = new Gdk.Pixbuf.from_file (TZm7.printf (Constants.PKGDATADIR));
                    break;
                case -8:
                    selected = new Gdk.Pixbuf.from_file (TZm8.printf (Constants.PKGDATADIR));
                    break;
                case -9:
                    if (offset == -9)
                        selected = new Gdk.Pixbuf.from_file (TZm9.printf (Constants.PKGDATADIR));
                    else
                        selected = new Gdk.Pixbuf.from_file (TZm95.printf (Constants.PKGDATADIR));
                    break;
                case -10:
                    selected = new Gdk.Pixbuf.from_file (TZm10.printf (Constants.PKGDATADIR));
                    break;
                case -11:
                    selected = new Gdk.Pixbuf.from_file (TZm11.printf (Constants.PKGDATADIR));
                    break;
                default:
                    selected = new Gdk.Pixbuf.from_file (TZ0.printf (Constants.PKGDATADIR));
                    break;
            }
        } catch (Error e) {
            critical (e.message);
        }

        selected_scale = selected;
        queue_draw ();
    }
}
