package main

import "core:fmt"
import "core:math"
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
    part_1_result := part_1(parsed_input)
    utils.end_measure()

    utils.start_measure(utils.Step.Part2)
    part_2_result := part_2(parsed_input)
    utils.end_measure()

    utils.print_results(part_1_result, part_2_result)
}

update_stone :: proc(stones: ^map[int]int, value: int, change: int) {
    count := stones[value] or_else 0
    if change < 0 {
        if count > 0 do count += change
    } else {
        count += change
    }
    stones[value] = count
}

parse :: proc(input: string) -> map[int]int {
    input := input
    stones := make(map[int]int)
    for value in strings.fields_iterator(&input) {
        update_stone(&stones, strconv.atoi(value), 1)
    }

    return stones
}

count_digits :: proc(value: int) -> int {
    return cast(int)(math.floor(math.log10(cast(f64)value))) + 1
}

split_digits :: proc(value: int) -> [2]int {
    value := value
    result := [2]int{}
    base :: 10
    divisor := base
    for {
        if (value / divisor) <= divisor do break
        divisor *= base
    }

    result[0] = value / divisor
    result[1] = value % divisor

    return result
}

solve :: proc(stones_original: map[int]int, blinks: int) -> int {
    stones := make(map[int]int)
    defer delete(stones)

    for value, count in stones_original {
        stones[value] = count
    }

    stones_copy := make(map[int]int)
    defer delete(stones_copy)

    for i in 0..<blinks {
        clear(&stones_copy)

        for value, count in stones {
            if count == 0 do continue
            stones_copy[value] = count
        }

        for value, count in stones_copy {
            if value == 0 {
                stones[0] -= count
                update_stone(&stones, 1, count)
                continue
            }

            if count_digits(value) % 2 == 0 {
                split := split_digits(value)
                stones[value] -= count
                update_stone(&stones, split[0], count)
                update_stone(&stones, split[1], count)
                continue
            }

            update_stone(&stones, value * 2024, count)
            stones[value] -= count
        }
    }

    total := 0

    for _, count in stones {
        total += count
    }

    return total
}

part_1 :: proc(stones: map[int]int) -> int {
    return solve(stones, 25)
}

part_2 :: proc(stones: map[int]int) -> int {
    return solve(stones, 75)
}

TEST_INPUT := parse(#load("test_input", string))

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT) == 55312)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT) == 65601038650482)
}
