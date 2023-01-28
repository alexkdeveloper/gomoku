
public class Net : Object {
    public int dim;

    private Slot[] all_slots;
    private Slot[] active_slots_0;
    private Slot[] active_slots_b;
    private Slot[] active_slots_w;
    private Point[] all_points;
    private Point[] empty_points;
    private Step[] steps;

    public Net(int dim, Step[] steps) {
        this.dim = dim;
        this.all_slots = new Slot[0];
        
        this.active_slots_b = new Slot[0];
        this.active_slots_w = new Slot[0];
        this.all_points = new Point[dim * dim];
        this.empty_points = new Point[dim * dim];
        this.steps = new Step[0];

        int count_slots = 0;
        for (int i = 0; i < dim * dim; i++) {
            Point p = new Point(this, (int)(i/dim), i % dim);
            this.all_points[i] = p;
            this.empty_points[i] = p;
            for (int d = 0; d < 4; d++) {
                if (p.is_valid_scp(d)) {
                    Slot s = new Slot(this, p, d);
                    this.all_slots += s;
                    count_slots++;
                }
            }
        }
        this.active_slots_0 = new Slot[count_slots];
        for (int i = 0; i < count_slots; i++) {
            this.all_slots[i].init();
            this.active_slots_0[i] = all_slots[i];
        }
        foreach (Step s in steps) {
            add_step(s);
        }
    }

    public Point get_point(int x, int y) {
        return all_points[x * dim + y];
    }

    public Result calculate() {

        if (check_win()) {
            stdout.printf("Net: calculate before win\n");
            return new Result(State.WIN, null, _("YOU WON!"));
        }
        if (check_draw()) {
            stdout.printf("Net: calculate before draw\n");
            return new Result(State.DRAW, null, _("DRAW!"));
        }
        
        Step new_step = calc_point();
        stdout.printf("Net: calculated step: %s\n", new_step.to_string());
        add_step(new_step);
        
        if (check_win()) {
            stdout.printf("Net: calculate after win\n");
            return new Result(State.WIN, new_step, _("YOU LOSE!"));
        }
        if (check_draw()) {
            stdout.printf("Net: calculate after draw\n");
            return new Result(State.DRAW, new_step, _("DRAW!"));
        }
        Result res = new Result(State.CONTINUE, new_step, "");
        return res;
    }

    public void add_step(Step step) {
        Point p = get_point(step.x, step.y);
        int c = steps.length % 2;

        stdout.printf("Net: add step start: n:%d, c: %d, %s  will be added \n", steps.length, c, p.to_string());

        p.s = c + 1;
        int n = find_point(empty_points, p);
        if (n < 0) {
            stdout.printf("Net: add step error: %s is not found in empty_points\n", p.to_string());
            return;
        }
        empty_points.move(n + 1, n, empty_points.length - n - 1);
        empty_points.resize(empty_points.length - 1);
        int i = 0;
        foreach(Slot s in p.get_slots()) {
            if (s.s == 0) {
                p.r[0]--;
			    p.r[c + 1]++;
			    s.s = c + 1;
                s.r = 1;

                int m = find_slot(active_slots_0, s);
                if (m < 0) {
                    stdout.printf("Net: add step error: slot (%d, %d) is not found in active_slots_0\n", s.scp.x, s.scp.y);
                    return;
                }
                active_slots_0.move(m + 1, m, active_slots_0.length - m - 1);
                active_slots_0.resize(active_slots_0.length - 1);
                if (c == 0) {
                    active_slots_b += s; 
                }
                if (c == 1) {
                    active_slots_w += s; 
                } 
            } else if (s.s == (c + 1)) {
                p.r[c + 1]++;
    			s.r++;
            } else if (s.s != 3) {
                p.r[c + 1]--;
                if (s.s == 1) {
                    int m = find_slot(active_slots_b, s);
                    if (m < 0) {
                        stdout.printf("Net: add step error: slot (%d, %d) is not found in active_slots_b\n", s.scp.x, s.scp.y);
                        return;
                    }
                    active_slots_b.move(m + 1, m, active_slots_b.length - m - 1);
                    active_slots_b.resize(active_slots_b.length - 1);
                }
                if (s.s == 2) {
                    int m = find_slot(active_slots_w, s);
                    if (m < 0) {
                        stdout.printf("Net: add step error: slot (%d, %d) is not found in active_slots_w\n", s.scp.x, s.scp.y);
                        return;
                    }
                    active_slots_w.move(m + 1, m, active_slots_w.length - m - 1);
                    active_slots_w.resize(active_slots_w.length - 1);
                }
                s.s = 3;
            } 
            i++;
        }
        steps += step;
        stdout.printf("Net: add step end: n:%d, c: %d, %s  will be added \n", steps.length, c, p.to_string());
    }

    private bool check_win() {
        foreach(Slot s in active_slots_b) {
            if (s == null) {
                stdout.printf("Net: active_slots_b slot is null\n");
                return false;
            }
            if (s.r == 5) {
                return true;
            }
        }
        foreach(Slot s in active_slots_w) {
            if (s == null) {
                stdout.printf("Net: active_slots_w slot is null\n");
                return false;
            }
            if (s.r == 5) {
                return true;
            }
        }
        return false;
    }

    private bool check_draw() {
        if(active_slots_0.length == 0 && active_slots_b.length == 0 && active_slots_w.length == 0) return true;
        return false;
    }

    private Step calc_point() {
        int c = steps.length % 2;
        Point[] points;

        points = find_slot_4(c);
        
        if (points.length == 0) points = find_slot_4(1 - c);
        if (points.length == 0) points = find_point_x(c, 2, 1);
        if (points.length == 0) points = find_point_x(1 - c, 2, 1);
        if (points.length == 0) points = find_point_x(c, 1, 5);
        if (points.length == 0) points = find_point_x(1 - c, 1, 5);
        if (points.length == 0) points = find_point_x(c, 1, 4);
        if (points.length == 0) points = find_point_x(1 - c, 1, 4);
        if (points.length == 0) points = find_point_x(c, 1, 3);
        if (points.length == 0) points = find_point_x(1 - c, 1, 3);
        if (points.length == 0) points = find_point_x(c, 1, 2);
        if (points.length == 0) points = find_point_x(1 - c, 1, 2);
        if (points.length == 0) points = find_point_x(c, 1, 1);
        if (points.length == 0) points = find_point_x(1 - c, 1, 1);
        if (points.length == 0) points = find_point_x(c, 0, 10);
        if (points.length == 0) points = find_point_x(1 - c, 0, 10);
        if (points.length == 0) points = find_point_x(c, 0, 9);
        if (points.length == 0) points = find_point_x(1 - c, 0, 9);
        if (points.length == 0) points = find_point_x(c, 0, 8);
        if (points.length == 0) points = find_point_x(1 - c, 0, 8);
        if (points.length == 0) points = find_point_x(c, 0, 7);
        if (points.length == 0) points = find_point_x(1 - c, 0, 7);
        if (points.length == 0) points = calc_point_max_rate(c);
        
        Point res = points[Random.int_range(0, points.length)];
        return new Step(res.x, res.y);
    }

    private Point[] find_point_x(int c, int r, int b) {
        Point[] result = new Point[0];
        foreach (Point p in empty_points) {
            int i = 0;
            foreach (Slot s in p.get_slots()) {
                if (s.s == (c + 1) && s.r > r) {
                    i++;
                    if (i > b) {
                        result += p;
                    }
                }
            }
        }
        if (result.length > 0) stdout.printf("Net: find_point_x r:%d, b:%d, points.length:%d\n", r, b, result.length);
        return result;
    }

    private Point[] find_slot_4(int c) {
        if (c == 0) {
            foreach(Slot s in active_slots_b) {
                if (s.r == 4) {
                    foreach(Point p in s.points) {
                        if (p.s == 0) {
                            stdout.printf("Net: find_slot_4 b point:%s\n", p.to_string());
                            return new Point[]{p};
                        }
                    }
                }
            }
        }
        if (c == 1) {
            foreach(Slot s in active_slots_w) {
                if (s.r == 4) {
                    foreach(Point p in s.points) {
                        if (p.s == 0) {
                            stdout.printf("Net: find_slot_4 w point:%s\n", p.to_string());
                            return new Point[]{p};
                        }
                    }
                }
            }
        }
        return new Point[0];
    }
    

    private Point[] calc_point_max_rate(int c) {
        int r = -1;
	    int d = 0;
        int i = 0;

        Point[] result  = new Point[]{};
        
        foreach(Point p in empty_points) {
            d = 0;
            foreach(Slot s in p.get_slots()) {
                if (s.s == 0) {
                    d += 1;
                } else if (s.s == (c + 1)) {
                    d += (1 + s.r) * (1 + s.r);
                } else if (s.s != 3) {
                    d += (1 + s.r) * (1 + s.r);
                }
            }
            if (d > r) {
                i = 1;
                r = d;
                result = new Point[]{};
                result += p;
            } else if (d == r) {
                i++;
                result += p;
            }
        }
        stdout.printf("Net: calc_point_max_rate points.length:%d\n", result.length);
        return result;
    }
    
    private int find_point(Point[] points, Point point) {
        int i = 0;
        foreach(Point p in points) {
            if(point.x == p.x && point.y == p.y) return i;
            i++;
        }
        return -1;
    }

    private int find_slot(Slot[] slots, Slot slot) {
        int i = 0;
        foreach(Slot s in slots) {
            if (s == null) {
                stdout.printf("Net: find_slot slot is null\n");
                return -1;
            }
            if(slot.scp.x == s.scp.x && slot.scp.y == s.scp.y && slot.d == s.d) return i;
            i++;
        }
        return -1;
    }
}

public class Point : Object {
    public int x {get; construct;}
    public int y {get; construct;}

    public int s;
    public int r[3];

    private Slot[] slots;
    private Net net;
	

    public Point(Net net, int x, int y) {
        Object(x: x, y: y);
        this.net = net;
        this.r = new int[] {0, 0, 0};
        this.s = 0;
        this.slots = new Slot[] {};
    }

    public string to_string() {
        return @"Point(x:$x, y:$y, s:$s, r:[$(r[0]),$(r[1]),$(r[2])])";
    }

    public Slot[] get_slots() {
        return slots;
    }

    public void add_slot(Slot slot) {
        slots += slot;
        r[slot.s]++;
    }

    public void print_slots() {
        stdout.printf("count: %d (", slots.length);
        foreach(Slot s in slots) {
            stdout.printf("%d,", s.d);
        }
        stdout.printf(")\n");
    }

    public bool is_valid_scp(int d) {
        int mn = 1;
        int mx = net.dim - 2;

        // 0 - vert, 1 - horiz, 2 - up, 3 - down
        if (d == 0 && y > mn && y < mx) {
            return true;
        }
        if (d == 1 && x > mn && x < mx) {
            return true;
        }
        if (d == 2 && (x > mn && y < mx) && (x < mx && y > mn)) {
            return true;
        }
        if (d == 3 && (x > mn && y > mn) && (x < mx && y < mx)) {
            return true;
        }
        return false;
    }
    
}

public class Slot : Object {
    public int d {get; construct;}
    public int r;
    public int s;
    public Point scp;
    public Point points[5];
    
    private Net net;
	
	
    public Slot(Net net, Point scp, int d) {
        Object(d: d);
        this.net = net;
        this.scp = scp;
        this.points = new Point[5] {};
    }

    public string to_string() {
        return @"Slot(scp:$scp, d:$d, s:$s, r:$r)";
    }

    public void init() {
        points[2] = net.get_point(scp.x, scp.y);
	    if (d == 0) {
            points[0] = net.get_point(scp.x, scp.y - 2);
            points[1] = net.get_point(scp.x, scp.y - 1);
            points[3] = net.get_point(scp.x, scp.y + 1);
            points[4] = net.get_point(scp.x, scp.y + 2);
	    } else if (d == 1) {
            points[0] = net.get_point(scp.x - 2, scp.y);
            points[1] = net.get_point(scp.x - 1, scp.y);
            points[3] = net.get_point(scp.x + 1, scp.y);
            points[4] = net.get_point(scp.x + 2, scp.y);
	    } else if (d == 2) {
            points[0] = net.get_point(scp.x - 2, scp.y - 2);
            points[1] = net.get_point(scp.x - 1, scp.y - 1);
            points[3] = net.get_point(scp.x + 1, scp.y + 1);
            points[4] = net.get_point(scp.x + 2, scp.y + 2);
	    } else if (d == 3) {
            points[0] = net.get_point(scp.x - 2, scp.y + 2);
            points[1] = net.get_point(scp.x - 1, scp.y + 1);
            points[3] = net.get_point(scp.x + 1, scp.y - 1);
            points[4] = net.get_point(scp.x + 2, scp.y - 2);
	    }
	    foreach (Point p in points) {
		    p.add_slot(this);
	    }
    }
}

public enum State {
    CONTINUE,
    DRAW,
    WIN 
}

public class Result : Object {
    public State state;
    public Step? step;
    public string message;

    public Result(State state, Step? step, string message) {
        this.state = state;
        this.step = step;
        this.message = message;
    }

    public string state_to_string(State st) {
        switch (st) {
        case State.CONTINUE:
            return "CONTINUE";
        case State.WIN:
            return "WIN";
        case State.DRAW:
            return "DRAW";
        }
        return "UNKNOWN";
    }

    public string to_string() {
        if (step != null)
            return @"Result(step:$step, state: $(state_to_string(state)))";
        else
            return @"Result(step:null, state: $(state_to_string(state)))";
    }
}

