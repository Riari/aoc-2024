package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:unicode/utf8"

import "../utils"

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

Vector2i :: struct{
    x: int,
    y: int
}

Input :: struct{
    warehouse: [dynamic][]rune,
    robot_position: Vector2i,
    moves: [dynamic]Vector2i
}

N := Vector2i{0, -1}
E := Vector2i{1, 0}
S := Vector2i{0, 1}
W := Vector2i{-1, 0}

parse :: proc(raw_input: string) -> Input {
    raw_input := raw_input

    input: Input

    parsing_warehouse := true
    y := 0
    for line in strings.split_lines_iterator(&raw_input) {
        if len(line) == 0 {
            parsing_warehouse = false
            continue
        }

        if parsing_warehouse {
            for x in 0..<len(line) {
                if line[x] == '@' {
                    input.robot_position = {x, y}
                }
            }

            append(&input.warehouse, utf8.string_to_runes(line))

            y += 1
        } else {
            for char in line {
                switch char {
                case '^': append(&input.moves, N)
                case '>': append(&input.moves, E)
                case 'v': append(&input.moves, S)
                case '<': append(&input.moves, W)
                }
            }
        }
    }

    return input
}

clone_input :: proc(input: Input, widen: bool) -> Input {
    input_clone: Input
    for row in input.warehouse {
        new_row: [dynamic]rune
        if widen {
            for char in row {
                switch char {
                case '#':
                    append(&new_row, '#')
                    append(&new_row, '#')
                case '@':
                    append(&new_row, '@')
                    append(&new_row, '.')
                case 'O':
                    append(&new_row, '[')
                    append(&new_row, ']')
                case '.':
                    append(&new_row, '.')
                    append(&new_row, '.')
                }
            }
        } else {
            for char in row do append(&new_row, char)
        }

        append(&input_clone.warehouse, new_row[:])
    }

    loop_y: for y in 0..<len(input_clone.warehouse) {
        for x in 0..<len(input_clone.warehouse[0]) {
            if input_clone.warehouse[y][x] == '@' {
                input_clone.robot_position = {x, y}
                break loop_y
            }
        }
    }

    input_clone.moves = input.moves

    return input_clone
}

part_1 :: proc(original_input: Input) -> int {
    input := clone_input(original_input, false)

    next: Vector2i
    for i in 0..<len(input.moves) {
        move := input.moves[i]
        next = {input.robot_position.x + move.x, input.robot_position.y + move.y}

        if input.warehouse[next.y][next.x] == '.' {
            input.warehouse[input.robot_position.y][input.robot_position.x] = '.'
            input.warehouse[next.y][next.x] = '@'
            input.robot_position = next
            continue
        }

        if input.warehouse[next.y][next.x] == '#' do continue

        scan_position := Vector2i{next.x + move.x, next.y + move.y}
        next_space := input.warehouse[scan_position.y][scan_position.x]
        for {
            if next_space == '#' do break
            if next_space == 'O' {
                scan_position.x += move.x
                scan_position.y += move.y
                next_space = input.warehouse[scan_position.y][scan_position.x]
                continue
            }
            if next_space == '.' {
                input.warehouse[scan_position.y][scan_position.x] = 'O'
                input.warehouse[input.robot_position.y][input.robot_position.x] = '.'
                input.warehouse[next.y][next.x] = '@'
                input.robot_position = next
                break
            }
        }
    }

    gps_sum := 0
    for y in 0..<len(input.warehouse) {
        for x in 0..<len(input.warehouse[0]) {
            if input.warehouse[y][x] != 'O' do continue
            gps_sum += 100 * y + x
        }
    }

    return gps_sum
}

execute_vertical_move :: proc(warehouse: ^[dynamic][]rune, box_left: Vector2i, box_right: Vector2i, move: Vector2i, simulate_only: bool) -> bool {
    next_pos_left := Vector2i{box_left.x, box_left.y + move.y}
    next_pos_right := Vector2i{box_right.x, box_right.y + move.y}
    next_cell_left := warehouse[next_pos_left.y][next_pos_left.x]
    next_cell_right := warehouse[next_pos_right.y][next_pos_right.x]

    if next_cell_left == '#' || next_cell_right == '#' do return false

    if next_cell_left == '.' && next_cell_right == '.' {
        if !simulate_only {
            warehouse[next_pos_left.y][next_pos_left.x] = '['
            warehouse[next_pos_right.y][next_pos_right.x] = ']'
            warehouse[box_left.y][box_left.x] = '.'
            warehouse[box_right.y][box_right.x] = '.'
        }

        return true
    }

    if next_cell_left == '[' {
        // Aligned box
        can_move := execute_vertical_move(warehouse, next_pos_left, next_pos_right, move, simulate_only)
        if can_move && !simulate_only {
            warehouse[next_pos_left.y][next_pos_left.x] = '['
            warehouse[next_pos_right.y][next_pos_right.x] = ']'
            warehouse[box_left.y][box_left.x] = '.'
            warehouse[box_right.y][box_right.x] = '.'
        }

        return can_move
    }

    // Offset box - find any affected boxes and test them
    a_left := Vector2i{next_pos_left.x - 1, next_pos_left.y}
    a_right := Vector2i{next_pos_left.x, next_pos_left.y}
    b_left := Vector2i{next_pos_right.x, next_pos_right.y}
    b_right := Vector2i{next_pos_right.x + 1, next_pos_right.y}

    a_is_box := warehouse[a_left.y][a_left.x] == '['
    b_is_box := warehouse[b_left.y][b_left.x] == '['

    can_move_a, can_move_b := false, false
    if a_is_box {
        can_move_a = execute_vertical_move(warehouse, a_left, a_right, move, simulate_only)
    } else {
        can_move_a = true
    }

    if b_is_box {
        can_move_b = execute_vertical_move(warehouse, b_left, b_right, move, simulate_only)
    } else {
        can_move_b = true
    }

    if can_move_a && can_move_b {
        if !simulate_only {
            warehouse[a_right.y][a_right.x] = '['
            warehouse[b_left.y][b_left.x] = ']'

            warehouse[box_left.y][box_left.x] = '.'
            warehouse[box_right.y][box_right.x] = '.'
        }

        return true
    }

    return false
}

execute_horizontal_move :: proc(warehouse: ^[dynamic][]rune, position: Vector2i, move: Vector2i) -> bool {
    scan_position := Vector2i{position.x + move.x, position.y}
    next_space := warehouse[scan_position.y][scan_position.x]
    for {
        if next_space == '#' do return false
        if next_space == ']' || next_space == '[' {
            scan_position.x += move.x
            next_space = warehouse[scan_position.y][scan_position.x]
            continue
        }
        if next_space == '.' {
            if move == E {
                for {
                    box_position_left := Vector2i{scan_position.x - 2, scan_position.y}
                    box_position_right := Vector2i{scan_position.x - 1, scan_position.y}

                    warehouse[scan_position.y][scan_position.x] = warehouse[box_position_right.y][box_position_right.x]
                    warehouse[box_position_right.y][box_position_right.x] = warehouse[box_position_left.y][box_position_left.x]

                    scan_position.x -= 2

                    if scan_position.x <= position.x do return true
                }
            } else {
                for {
                    box_position_left := Vector2i{scan_position.x + 1, scan_position.y}
                    box_position_right := Vector2i{scan_position.x + 2, scan_position.y}

                    warehouse[scan_position.y][scan_position.x] = warehouse[box_position_left.y][box_position_left.x]
                    warehouse[box_position_left.y][box_position_left.x] = warehouse[box_position_right.y][box_position_right.x]

                    scan_position.x += 2

                    if scan_position.x >= position.x do return true
                }
            }
        }
    }

    return false
}

print_warehouse :: proc(warehouse: [dynamic][]rune) {
    for row in warehouse {
        for char in row do fmt.print(char)
        fmt.print('\n')
    }
}

WideBox :: struct{
    left: Vector2i,
    right: Vector2i
}

part_2 :: proc(original_input: Input) -> int {
    input := clone_input(original_input, true)

    next: Vector2i
    for i in 0..<len(input.moves) {
        move := input.moves[i]
        next = {input.robot_position.x + move.x, input.robot_position.y + move.y}
        next_cell := input.warehouse[next.y][next.x]

        if next_cell == '.' {
            input.warehouse[input.robot_position.y][input.robot_position.x] = '.'
            input.warehouse[next.y][next.x] = '@'
            input.robot_position = next
            continue
        }

        if next_cell == '#' do continue

        moved := false
        if move == N || move == S {
            box_left := next_cell == '[' ? next : Vector2i{next.x - 1, next.y}
            box_right := next_cell == ']' ? next : Vector2i{next.x + 1, next.y}
            moved = execute_vertical_move(&input.warehouse, box_left, box_right, move, false)
            if moved do execute_vertical_move(&input.warehouse, box_left, box_right, move, true)
        } else {
            moved = execute_horizontal_move(&input.warehouse, input.robot_position, move)
        }

        if moved {
            input.warehouse[input.robot_position.y][input.robot_position.x] = '.'
            input.warehouse[next.y][next.x] = '@'
            input.robot_position = next
        }
    }

    print_warehouse(input.warehouse)

    gps_sum := 0
    for y in 0..<len(input.warehouse) {
        for x in 0..<len(input.warehouse[0]) {
            if input.warehouse[y][x] != '[' do continue

            distance_left := 0
            for count_x in 0..<x do distance_left += 1

            distance_top := 0
            for count_y in 0..<y do distance_top += 1

            gps_sum += 100 * distance_top + distance_left
        }
    }

    return gps_sum
}

TEST_INPUT := parse(#load("test_input", string))

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT) == 10092)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT) == 9021)
}
