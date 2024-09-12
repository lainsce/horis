public class Horis.Habit {
    public string name { get; set; }
    public string tagging_color { get; set; }
    public bool[] active_days { get; set; }
    public int64 reminder_id { get; set; }
    public bool reminder { get; set; }
    public string reminder_time { get; set; }
    public string reminder_label { get; set; }
    public Gee.Set<string> marked_dates { get; set; }

    public Habit (string name, string tagging_color, bool[] active_days) {
        this.name = name;
        this.tagging_color = tagging_color;
        this.active_days = active_days;
        this.reminder = false;
        this.reminder_time = "";
        this.reminder_label = "";
        this.marked_dates = new Gee.HashSet<string> ();
    }

    public Json.Node to_json () {
        var obj = new Json.Object ();
        obj.set_string_member ("name", name);
        obj.set_string_member ("tagging_color", tagging_color);
        set_active_days_array (obj, active_days);
        obj.set_int_member ("reminder_id", reminder_id);
        obj.set_boolean_member ("reminder", reminder);
        obj.set_string_member ("reminder_time", reminder_time);
        obj.set_string_member ("reminder_label", reminder_label);

        var dates_array = new Json.Array ();
        foreach (var date in marked_dates) {
            dates_array.add_string_element (date);
        }
        obj.set_array_member ("marked_dates", dates_array);

        var node = new Json.Node (Json.NodeType.OBJECT);
        node.set_object (obj);
        return node;
    }

    void set_active_days_array (Json.Object obj, bool[] active_days) {
        Json.Array json_array = new Json.Array ();

        foreach (bool day in active_days) {
            json_array.add_boolean_element (day);
        }

        obj.set_array_member ("active_days", json_array);
    }

    public static Habit from_json (Json.Object obj) {
        var name = obj.get_string_member ("name");
        var tagging_color = obj.get_string_member ("tagging_color");
        var active_days_json_array = obj.get_array_member ("active_days");
        bool[] active_days_array = new bool[active_days_json_array.get_length ()];

        for (int i = 0; i < active_days_json_array.get_length (); i++) {
            active_days_array[i] = active_days_json_array.get_boolean_element (i);
        }

        var habit = new Habit (name, tagging_color, active_days_array) {
            reminder = obj.get_boolean_member ("reminder"),
            reminder_time = obj.get_string_member ("reminder_time"),
            reminder_label = obj.get_string_member ("reminder_label")
        };

        habit.reminder_id = obj.get_int_member ("reminder_id");

        var marked_dates_array = obj.get_array_member ("marked_dates");
        foreach (var element in marked_dates_array.get_elements ()) {
            habit.marked_dates.add (element.get_string ());
        }

        return habit;
    }

    public void mark_date (GLib.DateTime date) {
        marked_dates.add (date.format ("%Y-%m-%d"));
    }

    public void unmark_date (GLib.DateTime date) {
        marked_dates.remove (date.format ("%Y-%m-%d"));
    }

    public bool is_date_marked (GLib.DateTime date) {
        return marked_dates.contains (date.format ("%Y-%m-%d"));
    }

    public int get_marked_days_in_range (GLib.DateTime start, GLib.DateTime end) {
        int count = 0;
        var current = start;
        while (current.compare (end) <= 0) {
            if (is_date_marked (current)) {
                count++;
            }
            current = current.add_days (1);
        }
        return count;
    }

    public int get_missed_days_in_range (GLib.DateTime start, GLib.DateTime end) {
        int missed = 0;
        var current = start;
        while (current.compare (end) <= 0) {
            int day_of_week = current.get_day_of_week () - 1; // 0-based index
            if (active_days[day_of_week] && !is_date_marked (current)) {
                missed++;
            }
            current = current.add_days (1);
        }
        return missed;
    }

    public string get_frequency () {
        int count = 0;
        foreach (bool day in active_days) {
            if (day)count++;
        }
        if (count == 7) {
            return "Daily";
        } else if (count == 1) {
            return "Once a week";
        } else {
            return "%d times a week".printf (count);
        }
    }

    public void update_frequency (int frequency_index) {
        bool[] new_active_days = new bool[7];
        if (frequency_index == 0) { // Daily
            for (int i = 0; i < 7; i++)new_active_days[i] = true;
        } else if (frequency_index == 1) { // Once a week
            new_active_days[0] = true; // Set Monday as default
        } else {
            int days_to_set = frequency_index + 1;
            for (int i = 0; i < days_to_set; i++) {
                new_active_days[i] = true;
            }
        }
        this.active_days = new_active_days;
    }

    public void set_reminder_details (bool enabled, string time, string label) {
        this.reminder = enabled;
        this.reminder_time = time;
        this.reminder_label = label;
    }
}