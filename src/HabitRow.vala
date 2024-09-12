public class Horis.HabitRow : Gtk.ListBoxRow {
    public Habit habit { get; set; }
    private Gtk.Box main_box;
    private Gtk.Label name_label;
    private Gtk.Label frequency_label;
    private Gtk.Box days_box;

    public signal void habit_changed ();
    public signal void delete_requested ();

    public HabitRow (Habit habit) {
        Object (habit: habit);

        create_ui ();
        update_ui ();
    }

    private void create_ui () {
        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        set_child (main_box);

        var header_box = create_header_box ();
        var dow_box = create_dow_box ();
        days_box = create_days_box ();

        main_box.append (header_box);
        main_box.append (dow_box);
        main_box.append (days_box);
        main_box.add_css_class ("mini-content-block");
    }

    private Gtk.Box create_header_box () {
        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);

        name_label = new Gtk.Label (habit.name);
        name_label.add_css_class ("cb-title");
        name_label.halign = Gtk.Align.START;
        name_label.hexpand = true;

        frequency_label = new Gtk.Label (habit.get_frequency ());
        frequency_label.add_css_class ("cb-subtitle");
        frequency_label.halign = Gtk.Align.END;

        var menu_button = create_menu_button ();

        header_box.append (name_label);
        header_box.append (frequency_label);
        header_box.append (menu_button);

        return header_box;
    }

    private Gtk.MenuButton create_menu_button () {
        var menu_button = new Gtk.MenuButton ();
        menu_button.get_first_child ().add_css_class ("circular");
        menu_button.get_first_child ().remove_css_class ("image-button");
        menu_button.icon_name = "view-more-symbolic";
        menu_button.has_frame = false;

        var popover = new Gtk.Popover ();
        popover.has_arrow = false;
        var popover_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
        popover_box.margin_start = popover_box.margin_end = 8;
        popover_box.margin_top = popover_box.margin_bottom = 8;

        var delete_button = new He.Button ("", "Delete") {
            has_frame = false
        };
        delete_button.clicked.connect (() => {
            delete_requested ();
            popover.popdown ();
        });

        popover_box.append (delete_button);
        popover.set_child (popover_box);
        menu_button.popover = popover;

        return menu_button;
    }

    private Gtk.Box create_dow_box () {
        var dow_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 7) {
            homogeneous = true
        };
        string[] day_abbrs = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" };

        for (int i = 0; i < 7; i++) {
            var date_label = new Gtk.Label (day_abbrs[i]);
            date_label.add_css_class ("caption");
            dow_box.append (date_label);
        }

        return dow_box;
    }

    private Gtk.Box create_days_box () {
        var days_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
        days_box.homogeneous = true;

        var today = new GLib.DateTime.now_local ();

        for (int i = 0; i <= 6; i++) {
            var day = today.add_days (-i);
            var button = create_day_button (day);
            days_box.append (button);
        }

        return days_box;
    }

    private Gtk.ToggleButton create_day_button (GLib.DateTime day) {
        var button = new Gtk.ToggleButton ();
        button.add_css_class ("day-button");
        button.add_css_class ("circular");
        button.add_css_class ("%s".printf (habit.tagging_color));
        button.remove_css_class ("text-button");
        button.set_label (day.get_day_of_month ().to_string ());

        button.sensitive = habit.active_days[day.get_day_of_week () - 1];
        button.active = habit.is_date_marked (day);
        button.toggled.connect (() => {
            if (button.active) {
                habit.mark_date (day);
            } else {
                habit.unmark_date (day);
            }
            update_frequency_label ();
            habit_changed ();
        });

        return button;
    }

    public void update_ui () {
        name_label.label = habit.name;
        update_frequency_label ();

        // Update day buttons
        var today = new GLib.DateTime.now_local ();
        var child = days_box.get_first_child ();
        for (int i = 0; child != null && i < 7; i++) {
            var button = (Gtk.ToggleButton) child;
            if (button != null) {
                var day = today.add_days (-i);
                button.sensitive = habit.active_days[day.get_day_of_week () - 1];
                button.active = habit.is_date_marked (day);
            }
            child = child.get_next_sibling ();
        }
    }

    private void update_frequency_label () {
        frequency_label.label = habit.get_frequency ();
    }
}