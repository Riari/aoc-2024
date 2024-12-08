package main

import "core:fmt"
import "core:math"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"

import "../utils"

Operands :: [dynamic]int
Equations :: map[int]Operands

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

parse :: proc(input: string) -> Equations {
    equations: Equations
    for line in strings.split_lines(input) {
        if len(line) == 0 do continue
        parts := strings.split(line, ": ")
        result := strconv.atoi(parts[0])
        operand_strings := strings.split(parts[1], " ")
        operands := make(Operands, len(operand_strings))
        for i in 0..<len(operand_strings) {
            operands[i] = strconv.atoi(operand_strings[i])
        }

        equations[result] = operands
    }

    return equations
}

is_solvable :: proc(target: int, operands: Operands, with_concat: bool) -> bool {
    operands := operands

    if len(operands) == 1 do return target == operands[0]

    last := pop(&operands)

    if target % last == 0 && is_solvable(target / last, operands, with_concat) {
        return true
    }

    if target > last && is_solvable(target - last, operands, with_concat) {
        return true
    }

    if with_concat {
        num_digits_last := cast(int)math.log10(cast(f64)last) + 1
        num_digits_target := cast(int)math.log10(cast(f64)target) + 1

        magnitude := cast(int)math.pow10(cast(f64)num_digits_last)

        end := target % magnitude

        if num_digits_target > num_digits_last && end == last && is_solvable(target / magnitude, operands, with_concat) {
            return true
        }
    }

    return false
}

solve :: proc(equations: Equations, with_concat: bool) -> int {
    total := 0
    for target, operands in equations {
        if is_solvable(target, operands, with_concat) do total += target
    }

    return total
}

part_1 :: proc(equations: Equations) -> int {
    return solve(equations, false)
}

part_2 :: proc(equations: Equations) -> int {
    return solve(equations, true)
}

TEST_INPUT := #load("test_input", string)
TEST_INPUT_PARSED := parse(TEST_INPUT)

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT_PARSED) == 3749)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT_PARSED) == 11387)
}
