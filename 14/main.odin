package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:text/regex"

import "../utils"

REAL_AREA := Vector2i{101, 103}
TEST_AREA := Vector2i{11, 7}

main :: proc() {
    input := #load("input", string)

    utils.start_measure(utils.Step.Parse)
    parsed_input := parse(input)
    utils.end_measure()

    utils.start_measure(utils.Step.Part1)
    part_1_result := part_1(parsed_input, REAL_AREA)
    utils.end_measure()

    utils.start_measure(utils.Step.Part2)
    part_2_result := part_2(parsed_input, REAL_AREA)
    utils.end_measure()

    utils.print_results(part_1_result, part_2_result)
}

Vector2i :: struct{
    x: int,
    y: int
}

Robot :: struct{
    position: Vector2i,
    velocity: Vector2i
}

parse :: proc(input: string) -> []Robot {
    input := input

    robots: [dynamic]Robot

    numbers_regex, error := regex.create("(\\d+),(\\d+) v=(-*\\d+),(-*\\d+)", { .Global })
    numbers_capture := regex.Capture{make([][2]int, 10), make([]string, 10)}

    robot: Robot
    for line in strings.split_lines_iterator(&input) {
        if len(line) == 0 do continue

        num_groups, success := regex.match_with_preallocated_capture(numbers_regex, line, &numbers_capture)

        if !success {
            fmt.println("Regex broke :(")
            return {}
        }

        px := numbers_capture.groups[1]
        py := numbers_capture.groups[2]
        vx := numbers_capture.groups[3]
        vy := numbers_capture.groups[4]

        robot.position = Vector2i{strconv.atoi(px), strconv.atoi(py)}
        robot.velocity = Vector2i{strconv.atoi(vx), strconv.atoi(vy)}

        append(&robots, robot)
    }

    return robots[:]
}

add :: proc(a: Vector2i, b: Vector2i) -> Vector2i {
    return Vector2i{a.x + b.x, a.y + b.y}
}

count_robots_at :: proc(robots: []Robot, position: Vector2i) -> int {
    count := 0
    for i in 0..<len(robots) {
        if robots[i].position == position do count += 1
    }

    return count
}

count_robots_between :: proc(robots: []Robot, from: Vector2i, to: Vector2i) -> int {
    count := 0
    for i in 0..<len(robots) {
        pos := robots[i].position
        if pos.x >= from.x && pos.x < to.x && pos.y >= from.y && pos.y < to.y do count += 1
    }

    return count
}

print_robots :: proc(robots: []Robot, area: Vector2i) {
    for y in 0..<area.y {
        for x in 0..<area.x {
            count := count_robots_at(robots, {x, y})
            if count > 0 {
                fmt.print(count)
            } else {
                fmt.print(".")
            }
        }
        fmt.print("\n")
    }
    fmt.println("")
}

clone_robots :: proc(robots: []Robot) -> []Robot {
    new_robots: [dynamic]Robot

    for robot in robots {
        append(&new_robots, Robot{robot.position, robot.velocity})
    }

    return new_robots[:]
}

solve :: proc(robots: []Robot, area: Vector2i, seconds: int, identify_tree: bool) -> int {
    robots := clone_robots(robots)

    centre := Vector2i{area.x / 2, area.y / 2}

    rows := make(map[int][dynamic]int)
    defer delete(rows)

    for second in 0..<seconds {
        if identify_tree do clear(&rows)

        for i in 0..<len(robots) {
            robots[i].position = add(robots[i].position, robots[i].velocity)

            if robots[i].position.x < 0 do robots[i].position.x = area.x + robots[i].position.x
            if robots[i].position.y < 0 do robots[i].position.y = area.y + robots[i].position.y

            if robots[i].position.x >= area.x do robots[i].position.x -= area.x
            if robots[i].position.y >= area.y do robots[i].position.y -= area.y

            if identify_tree {
                row := rows[robots[i].position.y] or_else {}
                append(&row, robots[i].position.x)
                rows[robots[i].position.y] = row
            }
        }

        if identify_tree {
            line_minimum :: 13

            loop_y: for y, x_list in rows {
                x_sorted := x_list[:]
                slice.sort(x_sorted)
                consecutive := 0
                for i in 0..<len(x_sorted) - 1 {
                    one := x_sorted[i]
                    two := x_sorted[i + 1]

                    consecutive = two - one == 1 ? consecutive + 1 : 0

                    if consecutive >= line_minimum {
                        print_robots(robots, area)
                        return second + 1
                    }
                }
            }
        }
    }

    safety_factor := count_robots_between(robots, {0, 0}, {centre.x, centre.y})
    safety_factor *= count_robots_between(robots, {centre.x + 1, 0}, {area.x, centre.y})
    safety_factor *= count_robots_between(robots, {centre.x + 1, centre.y + 1}, area)
    safety_factor *= count_robots_between(robots, {0, centre.y + 1}, {centre.x, area.y})

    return safety_factor
}

part_1 :: proc(robots: []Robot, area: Vector2i) -> int {
    return solve(robots, area, 100, false)
}

part_2 :: proc(robots: []Robot, area: Vector2i) -> int {
    return solve(robots, area, 10000, true)
}

TEST_INPUT := parse(#load("test_input", string))

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT, TEST_AREA) == 12)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT, TEST_AREA) > 0)
}
