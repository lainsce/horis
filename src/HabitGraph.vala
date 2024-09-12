public class Horis.HabitGraph : He.Bin {
    private Gee.Set<string> marked_dates;
    private Gee.HashMap<string, int> month_data;
    private int[] monthly_percentages;
    private bool[] active_days;
    private Gtk.DrawingArea da;
    private Habit habit;

    private DateTime now = new DateTime.now_local();

    public HabitGraph(Gee.Set<string> dates, bool[] active_days, Habit hab) {
        this.marked_dates = dates;
        this.active_days = active_days;
        this.habit = hab;
        this.monthly_percentages = new int[12];
        month_data = new Gee.HashMap<string, int> ();

        da = new Gtk.DrawingArea() {
            hexpand = true,
            vexpand = true,
            content_height = 200,
            content_width = 300
        };

        foreach (string date in marked_dates) {
            add_data(date);
        }

        da.set_draw_func((widget, cr, width, height) => {
            draw(widget, cr, width, height);
        });

        child = da;
        width_request = 300;
        height_request = 200;
    }

    private void add_data(string date) {
        if (date != null && date != "") {
            var dt = new DateTime.from_iso8601(date, new TimeZone.local());
            string month_key = "%04u-%02u".printf(dt.get_year(), dt.get_month());

            // Increment or initialize the count
            month_data.set(month_key, month_data.get(month_key) + 1);
        }
    }

    public void update_data(Gee.Set<string> new_dates) {
        this.marked_dates = new_dates;
        calculate_percentages();
        da.queue_draw();
    }

    private void calculate_percentages() {
        int year = now.get_year();
        var current = new GLib.DateTime.local(year, 1, 1, 0, 0, 0);
        int[] month_lengths = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

        // Adjust for leap year
        if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
            month_lengths[1] = 29;
        }

        int day_of_year = 1;
        for (int month = 0; month < 12; month++) {
            int marked_days = 0;
            int active_days_count = 0;
            int month_end = day_of_year + month_lengths[month];

            while (day_of_year < month_end) {
                int weekday = ((day_of_year - 1) % 7) + 1;
                if (active_days[weekday - 1]) {
                    active_days_count++;
                    if (marked_dates.contains(current.format("%Y-%m-%d"))) {
                        marked_days++;
                    }
                }
                current = current.add_days(1);
                day_of_year++;
            }

            monthly_percentages[month] = (active_days_count > 0) ? (marked_days * 100) / active_days_count : 0;
        }
    }

    private void draw(Gtk.DrawingArea da, Cairo.Context cr, int width, int height) {
        int point_radius = 6;
        int graph_height = height - 32;

        double[] points_x = new double[12];
        double[] points_y = new double[12];

        Gdk.RGBA color = color_name_to_rgba(habit.tagging_color);

        // Precompute x positions
        for (int month = 0; month < 12; month++) {
            points_x[month] = 23 + (month * (width / 12.0));
        }

        // Precompute y positions based on percentages
        for (int month = 0; month < 12; month++) {
            points_y[month] = (height - 6) - (monthly_percentages[month] / 100.0 * graph_height);
        }

        draw_graph(da, cr, points_x, points_y, color, point_radius, graph_height);
    }

    private void draw_graph(Gtk.DrawingArea da, Cairo.Context cr, double[] points_x, double[] points_y, Gdk.RGBA color, int point_radius, int graph_height) {
        // Draw axes and lines
        draw_axes(cr, da.get_width(), da.get_height(), graph_height);
        draw_lines(cr, points_x, points_y, color, point_radius);
    }

    private void draw_axes(Cairo.Context cr, int width, int height, int graph_height) {
        cr.set_source_rgb(0.2, 0.2, 0.2);
        for (int i = 0; i <= 100; i += 25) {
            int y = (height - 6) - (int) (graph_height * (i / 100.0));
            cr.move_to(0, y);
            cr.line_to(width, y);
            cr.stroke();
        }

        cr.set_font_size(12);
        cr.set_source_rgb(0.5, 0.5, 0.5);
        for (int i = 0; i <= 100; i += 25) {
            int y = (height - 6) - (int) (graph_height * (i / 100.0));
            cr.move_to(0, y);
            cr.show_text("%d%%".printf(i));
        }
    }

    private void draw_lines(Cairo.Context cr, double[] points_x, double[] points_y, Gdk.RGBA color, int point_radius) {
        cr.set_line_width(4.0);
        cr.set_source_rgb(color.red, color.green, color.blue);

        cr.move_to(points_x[0], points_y[0]);
        for (int i = 0; i < 12; i++) {
            cr.line_to(points_x[i], points_y[i]);
        }
        cr.stroke();

        // Draw circles at each data point
        for (int i = 0; i < 12; i++) {
            cr.set_source_rgb(color.red, color.green, color.blue);
            cr.arc(points_x[i], points_y[i], point_radius - 1, 0, 2 * Math.PI);
            cr.fill();
            cr.set_line_width(3.0);
            cr.set_source_rgb(0.114, 0.114, 0.114);
            cr.arc(points_x[i], points_y[i], point_radius, 0, 2 * Math.PI);
            cr.stroke();
        }
    }

    private Gdk.RGBA color_name_to_rgba(string color_name) {
        Gee.HashMap<string, string> color_map = new Gee.HashMap<string, string> ();
        if (color_map != null) {
            color_map.set("red", "#fa6363");
            color_map.set("yellow", "#fee562");
            color_map.set("green", "#2ec977");
            color_map.set("blue", "#4484ff");
            color_map.set("violet", "#8f6df1");
            color_map.set("brown", "#c38a55");
            color_map.set("gray", "#929292");
        }

        string color_hex = color_map.get(color_name); // Default to white
        Gdk.RGBA rgba = {};
        if (!rgba.parse(color_hex)) {
            stderr.printf("Invalid color string: %s\n", color_hex);
            rgba.red = rgba.green = rgba.blue = (float) 1.0; // Default to white
            rgba.alpha = (float) 1.0;
        }

        return rgba;
    }
}
