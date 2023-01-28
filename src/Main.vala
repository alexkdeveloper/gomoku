using Gtk;

public class Gomoku : Gtk.Application {

	private ApplicationWindow window;
	private ComboBoxText cb_color;
	private Button new_game_button;
	private Desk desk;
	private Net net;
	private bool is_play;
	private bool is_think;
	private int hum_color;
    private int game_counter;

	public Gomoku () {
		Object(application_id: "io.github.alexkdeveloper.gomoku",
				flags: ApplicationFlags.FLAGS_NONE);
		this.is_play = false;
		this.is_think = false;
        this.game_counter = 0;
	}

	private bool quit_confirm() {
		Dialog dlg = new Dialog.with_buttons(_("Quit"), window, DialogFlags.MODAL);
        var label = new Label(_("Quit the game?\nThe unfinished game will be reset.")); 
        label.margin_start = 10;
		label.margin_end = 10;
	    label.margin_top = 15;
	    label.margin_bottom = 15;
	    Pango.AttrList attrs = new Pango.AttrList (); 
        attrs.insert (Pango.attr_scale_new (Pango.Scale.X_LARGE)); 
		label.attributes = attrs;
		dlg.get_content_area().add(label);
		dlg.add_button("Ok", 0);
		dlg.add_button(_("Cancel"), 1);
        dlg.show_all();
		bool r = dlg.run() == 0 ? true : false;
		if(game_counter == 0){
            is_play = false;
        }else{
            is_play = !r;
        }
        dlg.close();
        return r;
    }

	private void over_info(string message) {
		Dialog dlg = new MessageDialog(window, DialogFlags.MODAL, MessageType.INFO, ButtonsType.OK, message);
        dlg.set_title(_("The game is over"));
		dlg.response.connect((src, id)=>{src.close();});
		dlg.show();
	}

	private void init_widgets() {
		HeaderBar headerbar = new HeaderBar();
        headerbar.set_title("Gomoku");
        headerbar.show_close_button = true;
		window.set_titlebar(headerbar);
		
		cb_color = new ComboBoxText();
		cb_color.changed.connect((cmb)=>{
		if(cmb.active_id == "b") hum_color = 0;
			else hum_color = 1;
		});
		cb_color.append("b", _("Black"));
		cb_color.append("w", _("White"));
		cb_color.active_id ="b";
		headerbar.pack_start(cb_color);

		new_game_button = new Button.with_label(_("New Game"));
		new_game_button.clicked.connect(new_game);
		headerbar.pack_end(new_game_button);

		desk = new Desk();
		window.add (desk);
	}

	private void new_game() {
        game_counter++;
		cb_color.set_sensitive(false);
		new_game_button.set_sensitive(false);
		desk.clean();
		is_play = true;
		Step st = new Step(7, 7);
		desk.add_step(st);
		is_think = true;
		net = new Net(DIM, new Step[]{st});
		Result result;
		if (hum_color == 0) {
			result = net.calculate();
			stdout.printf("new_game: calculate result: %s\n", result.step.to_string());
			desk.add_step(result.step);
		}
		is_think = false;
	}

	private void next_step(Step step) {
		is_think = true;
		net.add_step(step);
		Result result = net.calculate();
		stdout.printf("new_game: calculate result: %s\n", result.to_string());
		if (result.step != null) desk.add_step(result.step);
		is_think = false;
		if (result.state != State.CONTINUE) game_over(result.message);
	}

	private void game_over(string mess) {
		is_play = false;
		set_cursor("default");
		over_info(mess);
		cb_color.set_sensitive(true);
		new_game_button.set_sensitive(true);
	}

	private void set_cursor(string name) {
		Gdk.Window win = window.get_window();
		win.set_cursor(new Gdk.Cursor.from_name(win.get_display(), name));
	}

	protected override void activate () {
		window = new ApplicationWindow (this);
		window.set_default_size (800, 850);
		window.title = "Gomoku";
		window.delete_event.connect(() => {
			stdout.printf("App window delete_event\n");
			return !quit_confirm();			
		});

		init_widgets();

		window.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK |
			Gdk.EventMask.BUTTON_RELEASE_MASK |
			Gdk.EventMask.POINTER_MOTION_MASK
		);

		window.button_release_event.connect((evt)=> {
			if (!is_play || is_think) return true;
			stdout.printf("main mouse click x:%f, y:%f\n", evt.x, evt.y);
			int x, y;
			window.translate_coordinates(desk, (int)evt.x, (int)evt.y, out x, out y);
			Step step = desk.get_step_from_cord(x, y);
			if (step.x != -1 && step.y != -1 && desk.is_empty(step.x, step.y)) {
				desk.add_step(step);
				next_step(step);
			}
			return true;
		});
		
		window.motion_notify_event.connect((evt)=> {
			if (!is_play || is_think) return true;
			int x, y;
			window.translate_coordinates(desk, (int)evt.x, (int)evt.y, out x, out y);
			
			Step step = desk.get_step_from_cord(x, y);
			if (step.x != -1 && step.y != -1 && desk.is_empty(step.x, step.y)) 
				set_cursor("crosshair");
			else 
				set_cursor("default");
			return true;
		});
		window.show_all ();
	}

	public static int main (string[] args) {
        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Config.GETTEXT_PACKAGE);
		Gomoku app = new Gomoku ();
		return app.run (args);
	}
}
