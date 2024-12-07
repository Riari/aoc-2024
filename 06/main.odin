package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:unicode/utf8"

import "../utils"

Vector2i :: struct{
    x: int,
    y: int
}

PatrolMap :: [dynamic][]rune

RouteSegment :: [2]Vector2i

PatrolResult :: struct{
    // The start position marked on the map
    start: Vector2i,
    // True if the patrol is a loop
    is_loop: bool,
    // A list of all the visited positions
    visited: [dynamic]Vector2i,
    // Start and end coordinates for each segment in the route
    route_segments: [dynamic]RouteSegment,
    // Direction of travel (as indices into DIRECTIONS) for each segment in the route
    route_directions: [dynamic]int
}

OBSTACLE := '#'
EMPTY := '.'
START := '^'

DIRECTIONS := [4]Vector2i{
    {0, -1},    // N
    {1, 0},     // E
    {0, 1},     // S
    {-1, 0}     // W
}

main :: proc() {
    input := #load("input", string)

    utils.start_measure(utils.Step.Parse)
    parsed_input := parse(input)
    utils.end_measure()

    utils.start_measure(utils.Step.Part1)
    part_1_result := part_1(parsed_input)
    utils.end_measure()

    utils.start_measure(utils.Step.Part2)
    part_2_result := part_2(parsed_input)
    utils.end_measure()

    utils.print_results(part_1_result, part_2_result)
}

parse :: proc(input: string) -> PatrolMap {
    lines, _ := strings.split_lines(input)
    patrol_map := make(PatrolMap, len(lines) - 1)

    for i in 0..<len(lines) {
        if len(lines[i]) == 0 do break
        patrol_map[i] = utf8.string_to_runes(lines[i])
    }

    return patrol_map
}

clone_map :: proc(patrol_map: PatrolMap) -> PatrolMap {
    new_map := make(PatrolMap, len(patrol_map))
    for i in 0..<len(patrol_map) {
        new_map[i] = slice.clone(patrol_map[i])
    }
    return new_map
}

delete_map :: proc(patrol_map: PatrolMap) {
    for i in 0..<len(patrol_map) {
        delete(patrol_map[i])
    }
    delete(patrol_map)
}

delete_result :: proc(result: PatrolResult) {
    delete(result.visited)
    delete(result.route_segments)
    delete(result.route_directions)
}

print_map :: proc(patrol_map: PatrolMap, visited: [dynamic]Vector2i) {
    width, height := len(patrol_map[0]), len(patrol_map)

    for y in 0..<height {
        loop_x: for x in 0..<width {
            for position in visited {
                if position.x == x && position.y == y {
                    fmt.print('X')
                    continue loop_x
                }
            }

            fmt.print(patrol_map[y][x])
        }
        fmt.print("\n")
    }

    fmt.println("\n\n")
}

check_patrol :: proc(patrol_map: PatrolMap, record_visited: bool) -> PatrolResult {
    width, height := len(patrol_map[0]), len(patrol_map)

    start_position: Vector2i
    start_direction := DIRECTIONS[0]

    current_direction_index := 0
    current_direction := start_direction
    current_position: Vector2i

    loop_find_start: for y in 0..<height {
        for x in 0..<width {
            if patrol_map[y][x] == START {
                current_position = {x, y}
                start_position = current_position
                break loop_find_start
            }
        }
    }

    is_loop := true
    route_segments := make([dynamic]RouteSegment)
    route_directions := make([dynamic]int)
    segment_start := current_position
    loop_patrol: for {
        next := Vector2i{current_position.x + current_direction.x, current_position.y + current_direction.y}

        if next.x < 0 || next.x >= width || next.y < 0 || next.y >= height {
            is_loop = false
            append(&route_segments, RouteSegment{segment_start, next})
            append(&route_directions, current_direction_index)
            break
        }

        if patrol_map[next.y][next.x] == OBSTACLE {
            route_segment := RouteSegment{segment_start, current_position}

            for segment in route_segments {
                if segment[0].x == route_segment[0].x && segment[0].y == route_segment[0].y && segment[1].x == route_segment[1].x && segment[1].y == route_segment[1].y {
                    break loop_patrol
                }
            }

            append(&route_segments, route_segment)
            append(&route_directions, current_direction_index)

            segment_start = current_position

            current_direction_index += 1
            if current_direction_index >= len(DIRECTIONS) do current_direction_index = 0
            current_direction = DIRECTIONS[current_direction_index]
            continue
        }

        current_position = next
    }

    visited := make([dynamic]Vector2i)
    if record_visited {
        for segment in route_segments {
            a, b := segment[0], segment[1]

            start_x, end_x := a.x, b.x
            start_y, end_y := a.y, b.y

            if start_x == end_x do end_x += 1
            if start_y == end_y do end_y += 1

            reverse_x := start_x > end_x
            reverse_y := start_y > end_y

            for x := start_x; reverse_x ? x > end_x : x < end_x; x += reverse_x ? -1 : 1  {
                for y:= start_y; reverse_y ? y > end_y : y < end_y; y += reverse_y ? -1 : 1 {
                    position := Vector2i{x, y}
                    index, found := slice.linear_search(visited[:], position)
                    if !found do append(&visited, position)
                }
            }
        }
    }

    return PatrolResult{start_position, is_loop, visited, route_segments, route_directions}
}

solve :: proc(patrol_map: PatrolMap, find_obstacles: bool) -> int {
    result := check_patrol(patrol_map, true)
    defer delete_result(result)

    if !find_obstacles do return len(result.visited)

    looping_obstacles := 0
    for i in 0..<len(result.visited) {
        position := result.visited[i]

        if result.start == position do continue

        patrol_map_copy := clone_map(patrol_map)
        defer delete_map(patrol_map_copy)
        patrol_map_copy[position.y][position.x] = OBSTACLE

        modified_patrol_result := check_patrol(patrol_map_copy, false)
        defer delete_result(modified_patrol_result)
        if modified_patrol_result.is_loop do looping_obstacles += 1
    }

    return looping_obstacles
}

part_1 :: proc(patrol_map: PatrolMap) -> int {
    return solve(patrol_map, false)
}

part_2 :: proc(patrol_map: PatrolMap) -> int {
    return solve(patrol_map, true)
}

TEST_INPUT := #load("test_input", string)
TEST_LINES := parse(TEST_INPUT)

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_LINES) == 41)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_LINES) == 6)
}
