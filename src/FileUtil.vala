public class Horis.FileUtil {
    private const string HABITS_FILE = "habits.json";

    public static List<Habit> load_habits_from_file () {
        var habits = new List<Habit> ();
        var file = File.new_for_path (get_habits_file_path ());

        if (!file.query_exists ()) {
            return habits;
        }

        try {
            string content;
            FileUtils.get_contents (file.get_path (), out content);

            var parser = new Json.Parser ();
            parser.load_from_data (content);

            var root = parser.get_root ().get_array ();
            foreach (var element in root.get_elements ()) {
                var obj = element.get_object ();
                var habit = Habit.from_json (obj);
                habits.append (habit);
            }
        } catch (Error e) {
            warning ("Error loading habits: %s", e.message);
        }

        return habits;
    }

    public static void save_habits_to_file (List<Habit> habits) {
        var file = File.new_for_path (get_habits_file_path ());
        var generator = new Json.Generator ();
        var root = new Json.Node (Json.NodeType.ARRAY);
        var array = new Json.Array ();

        foreach (var habit in habits) {
            array.add_element (habit.to_json ());
        }

        root.set_array (array);
        generator.set_root (root);

        try {
            generator.to_file (file.get_path ());
        } catch (Error e) {
            warning ("Error saving habits: %s", e.message);
        }
    }

    private static string get_habits_file_path () {
        return Path.build_filename (Environment.get_user_data_dir (), "horis", HABITS_FILE);
    }
}