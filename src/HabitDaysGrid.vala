public class Horis.HabitDaysGrid : He.Bin {
    private Gee.Set<string> marked_days;
    private Habit habit;
    private const int MONTHS_TO_DISPLAY = 12;
    private const int BUTTON_SIZE = 16;
    private bool[] active_days;

    private Gtk.Grid grid = new Gtk.Grid();
    private DateTime now = new DateTime.now_local();

    public HabitDaysGrid(Gee.Set<string> marked_days, bool[] active_days, Habit habit) {
        this.marked_days = marked_days;
        this.active_days = active_days;
        this.habit = habit;
        setup_ui();

        grid.margin_bottom = 18;
        grid.column_spacing = 2;
        grid.row_spacing = 2;

        var sw = new Gtk.ScrolledWindow();
        sw.hexpand = true;
        sw.vscrollbar_policy = Gtk.PolicyType.NEVER;
        sw.set_child(grid);

        var scroll_controller = new Gtk.EventControllerScroll(Gtk.EventControllerScrollFlags.VERTICAL);
        scroll_controller.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);

        scroll_controller.scroll.connect((dx, dy) => {
            var hadjustment = sw.get_hadjustment();
            hadjustment.value += dy * hadjustment.step_increment * 2; // Scroll horizontally using dy

            return true;
        });

        sw.add_controller(scroll_controller);

        child = sw;
    }

    private void clear_grid() {
        Gtk.Widget? child = grid.get_first_child();
        while (child != null) {
            Gtk.Widget? next = child.get_next_sibling();
            grid.remove(child);
            child = next;
        }
    }

    private void setup_ui() {
        clear_grid();

        add_weekday_labels();
        add_month_grids();
    }

    private void add_weekday_labels() {
        string[] day_labels = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" };
        for (int i = 0; i < day_labels.length; i++) {
            var day_label = new Gtk.Label(day_labels[i]) {
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER,
                width_request = 28
            };
            day_label.add_css_class("caption");
            grid.attach(day_label, 0, i + 1, 1, 1);
        }
    }

    private void add_month_grids() {
        var last_year = now.add_years(-1).add_days(-1);
        int current_column = 1;
        int current_row = TimeUtil.get_day_of_week(now);

        for (var current_date = now; current_date.compare(last_year) >= 0; current_date = current_date.add_months(-1)) {
            add_month_grid(current_date, ref current_column, ref current_row);
        }
    }

    private void add_month_grid(DateTime month_start, ref int start_column, ref int start_row) {
        int year = month_start.get_year();
        int month = month_start.get_month();
        int last_day_of_month = TimeUtil.get_last_day_of_month(year, month);

        DateTime current = TimeUtil.create_date(year, month, last_day_of_month);

        if (month_start.get_year() == now.get_year() && month_start.get_month() == now.get_month()) {
            current = TimeUtil.create_date(year, month, now.get_day_of_month());
        }

        int start_offset = TimeUtil.get_day_of_week(current);
        if (start_offset == 7)start_offset = 0;

        var month_label = new Gtk.Label(month_start.format("%b")) {
            halign = Gtk.Align.CENTER
        };
        month_label.add_css_class("caption");
        grid.attach(month_label, start_column, 0, 1, 1);

        int column = start_column;
        int row = start_row < 1 ? 7 : start_row;
        int day_of_month = current.get_day_of_month();

        while (day_of_month >= 1) {
            add_day_button(current, ref column, ref row);
            current = current.add_days(-1);
            day_of_month--;
            row--;
            if (row < 1) {
                row = 7;
                column++;
            }
        }

        start_column = column;
        start_row = row;
    }

    private void add_day_button(DateTime date, ref int column, ref int row) {
        var day_button = new Gtk.Button() {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            width_request = BUTTON_SIZE,
            height_request = BUTTON_SIZE
        };

        var day_label = new Gtk.Label(
                                      date.get_day_of_month() < 10 ?
                                      "0" + date.get_day_of_month().to_string() :
                                      date.get_day_of_month().to_string()
            ) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };
        day_label.add_css_class("numeric");
        day_button.set_child(day_label);
        day_button.add_css_class("day-%s".printf(habit.tagging_color));

        string date_str = TimeUtil.format_date(date);
        if (marked_days.contains(date_str)) {
            day_button.add_css_class("marked");
        } else {
            day_button.add_css_class("skipped");
        }

        if (!active_days[(int) date.get_day_of_week() - 1]) {
            day_button.add_css_class("inactive");
        }

        day_button.set_tooltip_text(date.format("%x"));

        grid.attach(day_button, column, row, 1, 1);
    }

    public void update_data(Gee.Set<string> new_marked_days) {
        if (new_marked_days == null) {
            warning("Invalid marked days provided for update.");
        }

        this.marked_days = new_marked_days;
        setup_ui();

        setup_ui();
    }
}