[GtkTemplate (ui = "/io/github/lainsce/Horis/mainwindow.ui")]
public class Horis.MainWindow : He.ApplicationWindow {
    private const GLib.ActionEntry WINDOW_ENTRIES[] = {
        { "about", action_about },
    };

    [GtkChild]
    private unowned Gtk.Stack main_stack;
    [GtkChild]
    private unowned Gtk.ListBox main_list;
    [GtkChild]
    private unowned He.Button add_button;
    [GtkChild]
    private unowned Gtk.MenuButton menu_button;
    [GtkChild]
    private unowned He.BottomSheet sheet;
    [GtkChild]
    private unowned He.ViewMono view;
    [GtkChild]
    private unowned He.ViewTitle vtitle;
    [GtkChild]
    private unowned He.TextField search_entry;
    [GtkChild]
    private unowned He.EmptyPage empty_state_box;

    private NewHabitSheet new_habit_sheet;
    private List<Habit> habits;
    private ReminderManager reminder_manager;

    public MainWindow (He.Application application) {
        Object (
                application: application,
                icon_name: Config.APP_ID,
                title: _("Horis")
        );
    }

    construct {
        add_action_entries (WINDOW_ENTRIES, this);

        menu_button.get_popover ().has_arrow = false;

        habits = new List<Habit> ();

        main_list.row_activated.connect (on_row_activated);

        new_habit_sheet = new NewHabitSheet ();
        sheet.sheet = new_habit_sheet;

        new_habit_sheet.habit_added.connect (on_habit_added);

        add_button.clicked.connect (() => {
            sheet.show_sheet = true;
        });

        main_stack.notify["visible-child-name"].connect (() => {
            if (main_stack.get_visible_child_name () == "habits") {
                vtitle.label = _("Habits");
                view.show_back = false;

                GLib.Timeout.add (400, () => {
                    Gtk.Widget? target_page = main_stack.get_child_by_name ("habits");

                    if (target_page == null) {
                        warning ("No page found with the name 'habits'.");
                        return false;
                    }

                    Gtk.Widget? child = main_stack.get_first_child ();

                    while (child != null) {
                        Gtk.Widget? next_child = child.get_next_sibling ();

                        if (child != target_page) {
                            main_stack.remove (child);
                        }

                        child = next_child;
                    }
                    return false;
                });
            }
        });

        search_entry.get_internal_entry ().changed.connect (() => {
            filter_habits (search_entry.get_internal_entry ().text);
        });

        reminder_manager = new ReminderManager ();
        reminder_manager.reminder_triggered.connect (on_reminder_triggered);

        load_habits ();

        empty_state_box.action_button.clicked.connect (() => {
            sheet.show_sheet = true;
        });

        update_empty_state ();
    }

    private void update_empty_state () {
        bool has_habits = habits.length () > 0;
        empty_state_box.visible = !has_habits;
        main_list.visible = has_habits;
        search_entry.visible = has_habits;
    }

    private void load_habits () {
        habits = FileUtil.load_habits_from_file ();
        foreach (var habit in habits) {
            add_habit_to_list (habit);
            reminder_manager.add_habit (habit);
        }
    }

    private void save_habits () {
        FileUtil.save_habits_to_file (habits);
    }

    private void on_habit_added (Habit habit) {
        habits.append (habit);
        add_habit_to_list (habit);
        reminder_manager.add_habit (habit);
        save_habits ();
        sheet.show_sheet = false;
        update_empty_state ();
    }

    private void add_habit_to_list (Habit habit) {
        var habit_item = new HabitRow (habit);
        habit_item.habit_changed.connect (() => {
            save_habits ();
        });
        habit_item.delete_requested.connect (() => {
            delete_habit (habit, habit_item);
        });
        main_list.append (habit_item);
    }

    private void on_row_activated (Gtk.ListBoxRow row) {
        var habit_item = (HabitRow) row;
        if (habit_item != null) {
            show_habit_detail (habit_item.habit);
        }
    }

    private void show_habit_detail (Habit habit) {
        var detail_page = new HabitDetailPage (habit, view, vtitle);
        string page_name = "habit_detail_" + habit.name.down ().replace (" ", "_");

        detail_page.habit_changed.connect ((updated_habit) => {
            update_habit_row (updated_habit);
            save_habits ();
        });

        var detail_page_sw = new Gtk.ScrolledWindow ();
        detail_page_sw.set_child (detail_page);

        if (main_stack.get_child_by_name (page_name) == null) {
            main_stack.add_named (detail_page_sw, page_name);
            main_stack.visible_child = detail_page_sw;
        } else {
            main_stack.visible_child = detail_page_sw;
        }
    }

    private void update_habit_row (Habit updated_habit) {
        Gtk.ListBoxRow? row_to_update = null;
        int index = 0;

        while (true) {
            var row = main_list.get_row_at_index (index);
            if (row == null) {
                break;
            }

            var habit_item = (HabitRow) row;
            if (habit_item != null && habit_item.habit.name == updated_habit.name) {
                row_to_update = row;
                break;
            }

            index++;
        }

        if (row_to_update != null) {
            main_list.remove (row_to_update);
            add_habit_to_list (updated_habit);
        }
    }

    private void delete_habit (Habit habit, Gtk.ListBoxRow row) {
        var dialog = new Gtk.AlertDialog ("Delete the Habit '%s'?".printf (habit.name));
        dialog.set_modal (true);
        dialog.set_detail (_("This action cannot be undone."));
        dialog.set_buttons ({ "Cancel", "Delete" });
        dialog.set_default_button (1);
        dialog.set_cancel_button (0);

        dialog.choose.begin (
                             (Gtk.Window) this,
                             null,
                             (obj, res) => {
            try {
                var response = dialog.choose.end (res);
                if (response == 1) {
                    habits.remove (habit);
                    main_list.remove (row);
                    reminder_manager.remove_habit (habit);
                    save_habits ();
                    update_empty_state ();
                }
            } catch (Error e) {
                warning ("Error showing dialog: %s", e.message);
            }
        });
    }

    private void filter_habits (string search_text) {
        main_list.set_filter_func ((row) => {
            var habit_item = (HabitRow) row;
            if (habit_item == null) {
                return false;
            }
            return search_text.down () in habit_item.habit.name.down ();
        });
    }

    private void on_reminder_triggered (Habit habit) {
        var notification = new Notification (habit.name);
        notification.set_body (habit.reminder_label);
        notification.set_icon (new ThemedIcon ("appointment"));

        application.send_notification ("habit-reminder", notification);
    }

    private void action_about () {
        new He.AboutWindow (
                            this,
                            _("Horis") + Config.NAME_SUFFIX,
                            Config.APP_ID,
                            Config.VERSION,
                            Config.APP_ID,
                            null,
                            "https://github.com/lainsce/horis/issues",
                            "https://github.com/lainsce/horis",
                            null,
                            { "Lains" },
                            2024,
                            He.AboutWindow.Licenses.GPLV3,
                            He.Colors.LIGHT
        ).present ();
    }
}
