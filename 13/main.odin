package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:text/regex"

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

Machine :: struct{
    a: Vector2i,
    b: Vector2i,
    prize: Vector2i
}

parse :: proc(input: string) -> []Machine {
    input := input
    machines: [dynamic]Machine

    numbers_regex, error := regex.create("(\\d+),\\s..(\\d+)", { .Global })
    numbers_capture := regex.Capture{make([][2]int, 10), make([]string, 10)}

    i := 0
    machine: Machine
    for line in strings.split_lines_iterator(&input) {
        if len(line) == 0 do continue

        num_groups, success := regex.match_with_preallocated_capture(numbers_regex, line, &numbers_capture)

        if !success {
            fmt.printfln("Regex broke :(")
            return {}
        }

        x := numbers_capture.groups[1]
        y := numbers_capture.groups[2]
        vector := Vector2i{strconv.atoi(x), strconv.atoi(y)}

        switch i {
        case 0: machine.a = vector
        case 1: machine.b = vector
        case 2: machine.prize = vector
        }

        if i == 2 {
            append(&machines, machine)
            i = 0
        } else {
            i += 1
        }
    }

    return machines[:]
}

solve_machine :: proc(machine: ^Machine, offset: int) -> int {
    prize := Vector2i{machine.prize.x + offset, machine.prize.y + offset}
    determinant := machine.a.x * machine.b.y - machine.a.y * machine.b.x
    a := (prize.x * machine.b.y - prize.y * machine.b.x) / determinant
    b := (machine.a.x * prize.y - machine.a.y * prize.x) / determinant

    vector := Vector2i{machine.a.x * a + machine.b.x * b, machine.a.y * a + machine.b.y * b}

    return vector == prize ? a * 3 + b : 0
}

solve :: proc(machines: []Machine, offset: int) -> int {
    tokens := 0

    for &machine in machines {
        tokens += solve_machine(&machine, offset)
    }

    return tokens
}

part_1 :: proc(machines: []Machine) -> int {
    return solve(machines, 0)
}

part_2 :: proc(machines: []Machine) -> int {
    return solve(machines, 10000000000000)
}

TEST_INPUT := parse(#load("test_input", string))

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT) == 480)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT) == 875318608908)
}
