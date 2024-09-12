public class Horis.HabitDetailPage : Gtk.Box {
    private Habit habit;
    private HabitGraph graph;
    private HabitDaysGrid grid;

    private Gtk.Label frequency_label;
    private Gtk.Label reminder_label;
    private Gtk.Label times_value_label;
    private Gtk.Label missed_value_label;
    private Gtk.Label month_percent_value_label;
    private Gtk.Label total_percent_value_label;
    private He.ViewMono view;
    private He.ViewTitle vtitle;

    public signal void habit_changed (Habit updated_habit);

    public HabitDetailPage(Habit habit, He.ViewMono view, He.ViewTitle vtitle) {
        Object(
               orientation: Gtk.Orientation.VERTICAL,
               spacing: 12,
               margin_bottom: 18,
               halign: Gtk.Align.CENTER,
               width_request: 394
        );
        this.habit = habit;
        this.view = view;
        this.vtitle = vtitle;

        vtitle.label = habit.name;
        view.show_back = true;

        build_ui();
        update_stats();
    }

    private void build_ui() {
        append(create_info_box());

        var stats = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12) {
            homogeneous = true
        };
        stats.add_css_class("mini-content-block");
        stats.append(create_stats_box("times", out times_value_label));
        stats.append(create_stats_box("missed", out missed_value_label));
        stats.append(create_stats_box("month", out month_percent_value_label));
        stats.append(create_stats_box("total", out total_percent_value_label));
        append(stats);

        append(create_graph_box());

        append(create_date_grid());
    }

    private Gtk.Widget create_info_box() {
        var info_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12) {
            css_classes = { "mini-content-block" }
        };

        frequency_label = new Gtk.Label(habit.get_frequency()) {
            css_classes = { "cb-title" }
        };
        info_box.append(frequency_label);

        var edit_button = new Gtk.MenuButton() {
            icon_name = "document-edit-symbolic"
        };
        edit_button.get_first_child ().add_css_class ("circular");
        edit_button.get_first_child ().remove_css_class ("image-button");
        edit_button.popover = create_edit_popover();
        info_box.append(edit_button);

        var reminder_switch = new Gtk.Switch() {
            active = habit.reminder,
            valign = Gtk.Align.CENTER
        };
        reminder_switch.state_set.connect((state) => {
            habit.reminder = state;
            update_stats(); // Update the UI to reflect the change
            return false;
        });

        var reminder_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12) {
            hexpand = true,
            halign = Gtk.Align.END
        };
        reminder_box.append(new Gtk.Label("Reminders") {
            css_classes = { "cb-title" }
        });
        reminder_box.append(reminder_switch);

        info_box.append(reminder_box);

        return info_box;
    }

    private Gtk.Popover create_edit_popover() {
        var popover = new Gtk.Popover() {
            has_arrow = false
        };
        var popover_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4) {
            margin_top = 8,
            margin_bottom = 8,
            margin_start = 8,
            margin_end = 8
        };

        var name_entry = new He.TextField () {
            text = habit.name,
            placeholder_text = _("Habit Name")
        };
        popover_box.append(name_entry);

        var color_model = new Gtk.StringList ({});
        color_model.append ("Red");
        color_model.append ("Yellow");
        color_model.append ("Green");
        color_model.append ("Blue");
        color_model.append ("Violet");
        color_model.append ("Brown");
        color_model.append ("Gray");

        uint color_selected = 0;
        var color_dropdown = new Gtk.DropDown (color_model, null);
        color_dropdown.set_selected (get_color_index_from_list (color_model, habit.tagging_color));
        color_dropdown.notify["selected"].connect (() => {
            color_selected = color_dropdown.get_selected ();
        });

        popover_box.append (color_dropdown);

        var frequency_model = new Gtk.StringList ({});
        frequency_model.append ("Daily");
        frequency_model.append ("Once a week");
        for (int i = 2; i < 7; i++) {
            frequency_model.append (i.to_string() + " times a week");
        }

        uint freq_selected = 0;
        var frequency_dropdown = new Gtk.DropDown (frequency_model, null);
        frequency_dropdown.set_selected (get_frequency_index (habit.get_frequency()));
        frequency_dropdown.notify["selected"].connect (() => {
            freq_selected = frequency_dropdown.get_selected ();
        });

        popover_box.append (frequency_dropdown);

        var apply_button = new He.Button ("", _("Change Habit")) {
            is_pill = true
        };
        apply_button.clicked.connect(() => {
            habit.name = name_entry.text;
            habit.tagging_color = get_color_from_list (color_model, (int)color_selected);
            update_frequency_from_combo ((int)freq_selected);
            update_stats();
            habit_changed(habit);
            popover.popdown();
        });
        popover_box.append(apply_button);

        popover.child = popover_box;
        return popover;
    }

    private int get_color_index_from_list (Gtk.StringList color_list, string tagging_color) {
        for (int i = 0; i < color_list.get_n_items (); i++) {
            if (color_list.get_string (i) == tagging_color) {
                return i;
            }
        }
        return 0;
    }
    private string get_color_from_list (Gtk.StringList color_list, int index) {
        return color_list.get_string (index).down ();
    }

    private Gtk.Widget create_stats_box(string type, out Gtk.Label value_label) {
        var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12) {
            homogeneous = true,
            css_classes = { "mini-content-block" }
        };

        value_label = create_stat_label(type, out box);

        return box;
    }

    private Gtk.Widget create_graph_box() {
        var graph_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6) {
            css_classes = { "mini-content-block" }
        };

        var graph_header = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        graph_header.append(new Gtk.Label("Statistic") {
            css_classes = { "cb-title" }
        });

        graph_box.append(graph_header);

        graph = new HabitGraph(habit.marked_dates, habit.active_days, habit);
        graph_box.append(graph);

        return graph_box;
    }

    private Gtk.Widget create_date_grid() {
        var grid_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6) {
            css_classes = { "mini-content-block" }
        };

        var grid_header = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        grid_header.append(new Gtk.Label("History") {
            css_classes = { "cb-title" }
        });

        grid_box.append(grid_header);

        grid = new HabitDaysGrid(habit.marked_dates, habit.active_days, habit);
        grid_box.append(grid);

        return grid_box;
    }

    private Gtk.Label create_stat_label(string type, out Gtk.Box container) {
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };

        var value_label = new Gtk.Label("") {
            css_classes = { "title-2" }
        };
        box.append(value_label);

        var desc_label = new Gtk.Label(type) {
            css_classes = { "caption" }
        };
        box.append(desc_label);

        container = box;
        return value_label;
    }

    private void update_stats() {
        frequency_label.label = habit.get_frequency();
        reminder_label.label = habit.reminder ? "Reminder On" : "Reminder Off";

        var now = new GLib.DateTime.now_local();
        if (now == null) {
            // Handle error: current date-time could not be obtained
            return;
        }

        var start_of_month = new GLib.DateTime.local(now.get_year(), now.get_month(), 1, 0, 0, 0);
        if (start_of_month == null) {
            // Handle error: start of month date-time could not be created
            return;
        }

        int times = habit.get_marked_days_in_range(start_of_month, now);
        int missed = habit.get_missed_days_in_range(start_of_month, now);
        double month_percent = (double)times / (double)(times + missed) * 100;

        var start_of_year = new GLib.DateTime.local(now.get_year(), 1, 1, 0, 0, 0);
        if (start_of_year == null) {
            // Handle error: start of year date-time could not be created
            return;
        }

        int total_times = habit.get_marked_days_in_range(start_of_year, now);
        int total_missed = habit.get_missed_days_in_range(start_of_year, now);
        double total_percent = (double)total_times / (double)(total_times + total_missed) * 100;

        times_value_label.label = times.to_string();
        missed_value_label.label = missed.to_string();
        month_percent_value_label.label = "%.0f%%".printf(month_percent);
        total_percent_value_label.label = "%.0f%%".printf(total_percent);

        update_graph();
        update_grid();
        update_view_title();
    }

    private void update_graph() {
        graph.update_data(habit.marked_dates);
    }

    private void update_grid() {
        grid.update_data(habit.marked_dates);
    }

    private void update_view_title() {
        vtitle.label = habit.name;
    }

    private int get_frequency_index(string frequency) {
        if (frequency == "Daily")return 0;
        if (frequency == "Once a week")return 1;
        int times;
        if (frequency.scanf("%d times a week", out times) == 1) {
            return times - 1;
        }
        return 0; // Default to daily if not recognized
    }

    private void update_frequency_from_combo(int active) {
        bool[] new_active_days = new bool[7];
        if (active == 0) { // Daily
            for (int i = 0; i < 7; i++)new_active_days[i] = true;
        } else if (active == 1) { // Once a week
            new_active_days[0] = true; // Set Monday as default
        } else {
            int days_to_set = active + 1;
            for (int i = 0; i < days_to_set; i++) {
                new_active_days[i] = true;
            }
        }
        habit.active_days = new_active_days;
    }
}