package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"

import "../utils"

main :: proc() {
    input := #load("input", string)

    utils.start_measure(utils.Step.Parse)
    parsed_input := parse(input)
    utils.end_measure()

    utils.start_measure(utils.Step.Part1)
    part_1_result := part_1()
    utils.end_measure()

    utils.start_measure(utils.Step.Part2)
    part_2_result := part_2()
    utils.end_measure()

    utils.print_results(part_1_result, part_2_result)
}

parse :: proc(input: string) -> []string {
    return {}
}

part_1 :: proc() -> int {
    return 0
}

part_2 :: proc() -> int {
    return 0
}

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1() == 0)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2() == 0)
}
