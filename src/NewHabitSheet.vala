namespace Horis {
    public class NewHabitSheet : Gtk.Box {
        public signal void habit_added (Habit habit);
        private He.TextField name_entry;
        private Gtk.Box color_box;
        private Gtk.CheckButton[] color_buttons;
        private Gtk.Box days_of_week_box;
        private Gtk.ToggleButton[] day_buttons;
        private Gtk.Switch reminder_switch;
        private He.TimePicker time_picker;
        private He.TextField reminder_name_entry;

        private string[] colors = { "red", "yellow", "green", "blue", "violet", "brown", "gray" };
        private string[] days = { _("Sun"), _("Mon"), _("Tue"), _("Wed"), _("Thu"), _("Fri"), _("Sat") };

        public NewHabitSheet () {
            orientation = Gtk.Orientation.VERTICAL;
            spacing = 24;
            width_request = 380;

            name_entry = new He.TextField ();
            name_entry.placeholder_text = _("Habit Name");
            append (name_entry);

            color_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            color_buttons = new Gtk.CheckButton[colors.length];

            for (int i = 0; i < colors.length; i++) {
                var button = new Gtk.CheckButton ();
                button.add_css_class ("tag-toggle-%s".printf (colors[i]));
                button.add_css_class ("selection-mode");
                button.group = color_buttons[0];
                color_buttons[i] = button;
                color_box.append (button);
            }
            append (color_box);

            days_of_week_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            days_of_week_box.add_css_class ("linked");
            day_buttons = new Gtk.ToggleButton[7];

            for (int i = 0; i < days.length; i++) {
                var button = new Gtk.ToggleButton.with_label (days[i]);
                button.width_request = 54;
                day_buttons[i] = button;
                days_of_week_box.append (button);
            }
            append (days_of_week_box);

            var div = new He.Divider ();
            append (div);

            var vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
            append (vbox);

            var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);

            var reminders_label = new Gtk.Label("Reminders");
            reminders_label.add_css_class ("cb-subtitle");
            hbox.append(reminders_label);

            reminder_switch = new Gtk.Switch() {
                halign = Gtk.Align.END,
                hexpand = true
            };
            hbox.append(reminder_switch);

            vbox.append(hbox);

            reminder_name_entry = new He.TextField ();
            reminder_name_entry.visible = false;
            reminder_name_entry.placeholder_text = _("Reminder Title");
            vbox.append(reminder_name_entry);

            time_picker = new He.TimePicker();
            time_picker.visible = false;
            vbox.append(time_picker);

            reminder_switch.notify["active"].connect (() => {
                if (reminder_switch.active) {
                    time_picker.visible = true;
                    reminder_name_entry.visible = true;
                } else {
                    time_picker.visible = false;
                    reminder_name_entry.visible = false;
                }
            });

            var add_button = new He.Button ("", _("Add Habit")) {
                vexpand = true,
                valign = Gtk.Align.END,
                is_pill = true
            };
            add_button.clicked.connect (create_habit);
            append (add_button);
        }

        private void create_habit () {
            var name = name_entry.get_internal_entry ().text.strip ();
            var reminder_name = reminder_name_entry.get_internal_entry ().text.strip ();
            string color = null;

            // Get the selected color from the toggle buttons
            for (int i = 0; i < color_buttons.length; i++) {
                if (color_buttons[i].active) {
                    color = colors[i];
                    break;
                }
            }
            // Default color if none selected
            color = color ?? "red";

            var active_days = new bool[7];

            for (int i = 0; i < 7; i++) {
                active_days[i] = day_buttons[i].active;
            }

            if (name.length > 0) {
                var habit = new Habit (name, color, active_days);
                habit.reminder = reminder_switch.active;
                habit.reminder_label = reminder_name;
                habit.reminder_time = time_picker.time.format ("%H:%M");
                habit_added (habit);
                reset_form ();
            }
        }

        private void reset_form () {
            name_entry.text = "";
            foreach (var button in color_buttons) {
                button.active = false;
            }
            foreach (var button in day_buttons) {
                button.active = false;
            }
        }
    }
}