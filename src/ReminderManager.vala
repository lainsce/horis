public class Horis.ReminderManager {
    private GLib.List<Habit> habits;
    private GLib.HashTable<int, uint> scheduled_reminders;

    public signal void reminder_triggered (Habit habit);

    public ReminderManager () {
        habits = new GLib.List<Habit> ();
        scheduled_reminders = new GLib.HashTable<int, uint> (GLib.direct_hash, GLib.direct_equal);
    }

    public void add_habit (Habit habit) {
        habits.append (habit);
        if (habit.reminder) {
            schedule_reminder (habit);
        }
    }

    public void remove_habit (Habit habit) {
        habits.remove (habit);
        unschedule_reminder (habit);
    }

    public void update_habit (Habit habit) {
        unschedule_reminder (habit);
        if (habit.reminder) {
            schedule_reminder (habit);
        }
    }

    private void schedule_reminder (Habit habit) {
        DateTime now = new DateTime.now_local ();
        DateTime reminder_time;

        string[] time_parts = habit.reminder_time.split (":");
        int hour = int.parse (time_parts[0]);
        int minute = int.parse (time_parts[1]);

        reminder_time = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), hour, minute, 0);

        if (reminder_time.compare (now) <= 0) {
            reminder_time = reminder_time.add_days (1);
        }

        TimeSpan time_until_reminder = reminder_time.difference (now);
        uint timer_id = GLib.Timeout.add ((uint) time_until_reminder / 1000, () => {
            trigger_reminder (habit);
            return GLib.Source.REMOVE;
        });

        habit.reminder_id = (int64) timer_id;
        scheduled_reminders.insert ((int) habit.reminder_id, timer_id);
    }

    private void unschedule_reminder (Habit habit) {
        if (habit.reminder_id != 0) {
            uint timer_id;
            if (scheduled_reminders.lookup_extended ((int) habit.reminder_id, null, out timer_id)) {
                GLib.Source.remove (timer_id);
                scheduled_reminders.remove ((int) habit.reminder_id);
            }
            habit.reminder_id = 0;
        }
    }

    private bool trigger_reminder (Habit habit) {
        reminder_triggered (habit);
        schedule_reminder (habit);
        return GLib.Source.REMOVE;
    }
}