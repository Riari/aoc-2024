package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:unicode/utf8"

import "../utils"

main :: proc() {
    input := #load("test_input", string)

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

part_2 :: proc(original_input: Input) -> int {
    input := clone_input(original_input, true)

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


    }

    return 0
}

TEST_INPUT := parse(#load("test_input", string))

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT) == 10092)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT) == 0)
}
