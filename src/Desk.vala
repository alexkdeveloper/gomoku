using Gtk;

const int DIM = 15;
const int D = 41;

public class Desk : DrawingArea {
    
    private int dim;
    private int w;
    private int h;
    private int d;
    private double wpad;
    private double hpad;
    private double[] cx;
    private double[] cy;
    private Step[] steps;
    private int n_steps;

    public Desk() {
        dim = DIM;
        d = D;

        n_steps = 0;
        steps = new Step[dim * dim];

        w = (dim + 1) * d;
        h = (dim + 1) * d;

        cx = new double[dim];
        cy = new double[dim];

        for (int i = 0; i < dim; i++) {
            cx[i] = (i + 1) * d;
            cy[i] = (i + 1) * d;
        }

        set_size_request(w, h);

        draw.connect((cr)=>{
            return draw_all(cr);
        });

    }

    public void add_step(Step step) {
        stdout.printf("Desk add_step:%d, c:%d, x:%d, y:%d\n", n_steps, get_step_color(n_steps), step.x, step.y);
        steps[n_steps] = step;
        n_steps++;
        queue_draw();
    }

    public void clean() {
        for(int i = 0; i < dim * dim; i++)  steps[i] = null;
        n_steps = 0;
    }

    public Step get_step_from_cord(int x, int y) {
        int sx = -1, sy = -1;
        for (int i = 0; i < dim; i++) {
            if ((x >= (cx[i] + wpad - d/2)) && (x < (cx[i] + wpad + d/2))) {
                sx = i;
            }
            if ((y >= (cy[i] + hpad - d/2)) && (y < (cy[i] + hpad + d/2))) {
                sy = i;
            }
        }
        return new Step(sx, sy);
    }

    public bool is_empty(int x, int y) {
        for(int i = 0; i < n_steps; i++) {
            if (steps[i].x == x && steps[i].y == y) return false;
        }
        return true;
    }

    private int get_step_color(int n) {
        return n % 2;
    }

    private bool draw_all(Cairo.Context cr) {
        
        int aw = get_allocated_width();
        int ah = get_allocated_height();

        wpad = (aw - w) / 2;
        hpad = (ah - h) / 2;

        cr.save();

        cr.set_source_rgb(0.8, 0.8, 0.8);
        cr.rectangle(wpad, hpad, w, h);
        cr.fill();

        cr.set_line_width(2);
        cr.set_source_rgb(0.1, 0.1, 0.1);
        cr.rectangle(wpad, hpad, w, h);
        cr.stroke();

        cr.set_line_width(1);
        for (int i = 0; i < dim; i++) {
            double x = wpad + cx[i];
            cr.move_to(x, hpad + d);
            cr.line_to(x, hpad + h - d);
            double y = hpad + cy[i];
            cr.move_to(wpad + d, y);
            cr.line_to(wpad + w - d, y);
        }
        cr.stroke();

        if (n_steps > 0) { 

            for (int i = 0; i < n_steps; i++) {
                int sx = steps[i].x;
                int sy = steps[i].y;
                double x = wpad + cx[sx];
                double y = hpad + cy[sy];
                int c = get_step_color(i);
            
                if (c == 0) cr.set_source_rgb(0.1, 0.1, 0.1);
                else cr.set_source_rgb(0.9, 0.9, 0.9);

                cr.arc(x, y, d / 2, 0, 2 * 3.1415);
                cr.fill();

                cr.set_source_rgb(0.1, 0.1, 0.1);

                cr.arc(x, y, d / 2, 0, 2 * 3.1415);
                cr.stroke();

                if (c == 1) cr.set_source_rgb(0.1, 0.1, 0.1);
                else cr.set_source_rgb(0.9, 0.9, 0.9);

                string t = @"$(i+1)";
                Cairo.TextExtents ext;
                cr.set_font_size(d/2 - 2);
                cr.text_extents(t, out ext);

                cr.move_to(x - ext.width/2 - 1, y + ext.height/2 - 1);
                cr.show_text(t);
            
            }
        }
       
        cr.restore();
        return true;
    }
}
