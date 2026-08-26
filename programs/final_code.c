typedef struct {
    int x;
    int y;
} Point;

volatile int global_offset = 50000;
volatile int final_result;

__attribute__((noinline))
int compute_movement(Point *point_address, int step)
{
    int current_x = point_address->x;
    int scale_step = step << 3;
    int next_x = current_x + scale_step;

    if (next_x >= global_offset) {
        next_x = next_x - 10;
    } else {
        next_x = next_x + 10;
    }

    point_address->x = next_x;

    return next_x;
}

void main(void)
{
    Point my_point;

    my_point.x = 100;
    my_point.y = 200;

    final_result = compute_movement(&my_point, 5);

    while (1) {
    }
}