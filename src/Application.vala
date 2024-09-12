public class Horis.Application : He.Application {
    public static Application app;
    private const GLib.ActionEntry APP_ENTRIES[] = {
        { "quit", quit },
    };

    public static bool background;
    private Xdp.Portal? portal = null;
    public MainWindow window;

    private const OptionEntry[] OPTIONS = {
        { "background", 'b', 0, OptionArg.NONE, out background, "Launch and run in background.", null },
        { null }
    };

    public Application () {
        Object (
                application_id : Config.APP_ID,
                flags: ApplicationFlags.FLAGS_NONE
        );

        app = this;
    }

    construct {
        add_main_option_entries (OPTIONS);
    }

    public static int main (string[] args) {
        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.textdomain (Config.GETTEXT_PACKAGE);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");

        Environment.set_prgname (Config.APP_ID);
        Environment.set_application_name (_("Horis"));

        var context = new OptionContext (_("Horis"));
        context.add_main_entries (OPTIONS, "io.github.lainsce.Horis");

        try {
            context.parse (ref args);
        } catch (Error e) {
            warning (e.message);
        }

        var app = new Horis.Application ();
        return app.run (args);
    }

    protected override void activate () {
        base.activate ();

        if (background) {
            background = false;
            hold ();

            ask_for_background.begin ((obj, res) => {
                if (!ask_for_background.end (res)) {
                    release ();
                }
            });
        }

        if (get_windows () != null) {
            get_windows ().data.present (); // present window if app is already running
            return;
        }

        window = new MainWindow (this);
        window.show ();
    }

    public override void startup () {
        Gdk.RGBA accent_color = { 0 };
        accent_color.parse ("#888");
        default_accent_color = He.from_gdk_rgba (
        {
            accent_color.red,
            accent_color.green,
            accent_color.blue
        });
        override_dark_style = true;
        is_mono = true;

        resource_base_path = Config.APP_PATH;

        base.startup ();

        add_action_entries (APP_ENTRIES, this);
    }

    public async bool ask_for_background () {
        const string[] DAEMON_COMMAND = { "io.github.lainsce.Horis", "--background" };
        if (portal == null) {
            portal = new Xdp.Portal ();
        }

        string reason = _("Horis will run when its window is closed so that it can send habit notifications.");
        var command = new GenericArray<unowned string> (2);
        foreach (unowned var arg in DAEMON_COMMAND) {
            command.add (arg);
        }

        var window = Xdp.parent_new_gtk (active_window);

        try {
            return yield portal.request_background (window, reason, command, AUTOSTART, null);
        } catch (Error e) {
            warning ("Error during portal request: %s", e.message);
            return e is IOError.FAILED;
        }
    }
}