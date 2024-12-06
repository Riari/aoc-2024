package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:unicode/utf8"

import "../utils"

PatrolMap :: [dynamic][]rune

PatrolResult :: struct{
    is_loop: bool,
    map_with_route: PatrolMap
}

Vector2i :: struct{
    x: int,
    y: int
}

OBSTACLE := '#'
VISITED := 'X'

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

print_map :: proc(patrol_map: PatrolMap) {
    fmt.printfln("Route map has %d rows", len(patrol_map))
    for row in patrol_map {
        fmt.println(row)
    }
    fmt.println("------------\n\n\n")
}

check_patrol :: proc(patrol_map_original: PatrolMap, record_route: bool, min_steps: int) -> PatrolResult {
    patrol_map := clone_map(patrol_map_original)

    width := len(patrol_map[0])
    height := len(patrol_map)

    current_direction_index := 0
    current_direction := DIRECTIONS[0]
    current_position: Vector2i

    outer: for y in 0..<height {
        for x in 0..<width {
            if patrol_map[y][x] == '^' {
                current_position = {x, y}
                break outer
            }
        }
    }

    is_loop := true
    for i in 0..<min_steps {
        if record_route do patrol_map[current_position.y][current_position.x] = VISITED

        next := Vector2i{current_position.x + current_direction.x, current_position.y + current_direction.y}

        if next.x < 0 || next.x >= width || next.y < 0 || next.y >= height {
            is_loop = false
            break
        }

        if patrol_map[next.y][next.x] == OBSTACLE {
            current_direction_index += 1
            if current_direction_index >= len(DIRECTIONS) do current_direction_index = 0
            current_direction = DIRECTIONS[current_direction_index]
            continue
        }

        current_position = next
    }

    return PatrolResult{is_loop, patrol_map}
}

solve :: proc(patrol_map_original: PatrolMap, find_obstacles: bool) -> int {
    patrol_result := check_patrol(patrol_map_original, true, find_obstacles ? 10000 : 6000)
    defer delete_map(patrol_result.map_with_route)

    patrol_map := patrol_result.map_with_route

    width := len(patrol_map[0])
    height := len(patrol_map)

    visited := make([dynamic]Vector2i)
    defer delete(visited)
    for y in 0..<height {
        for x in 0..<width {
            if patrol_map[y][x] == VISITED {
                position := Vector2i{x, y}
                index, found := slice.linear_search(visited[:], position)
                if !found do append(&visited, position)
            }
        }
    }

    if !find_obstacles do return len(visited)

    looping_obstacles := 0
    for position in visited {
        if patrol_map_original[position.y][position.x] == '^' do continue

        patrol_map_copy := clone_map(patrol_map_original)
        defer delete_map(patrol_map_copy)
        patrol_map_copy[position.y][position.x] = OBSTACLE

        modified_patrol_result := check_patrol(patrol_map_copy, false, 10000)
        defer delete_map(modified_patrol_result.map_with_route)
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
