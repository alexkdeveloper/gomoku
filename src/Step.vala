public class Step : Object {
    public int x {get; construct;}
    public int y {get; construct;}

    public Step(int x, int y) {
        Object(x: x, y: y);
    }

    public string to_string() {
        return @"Step(x:$x, y:$y)";
    }
}