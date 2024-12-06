package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"

import "../utils"

Rules :: map[int][dynamic]int
Updates :: [dynamic][dynamic]int

ParsedInput :: struct {
    rules: Rules,
    updates: Updates
}

parse :: proc(input: string) -> ParsedInput {
    lines, _ := strings.split_lines(input)
    parsed_input := ParsedInput{}

    parsing_rules := true
    remaining := input
    for line in strings.split_lines_iterator(&remaining) {
        if len(line) == 0 do break

        parts := strings.split(line, "|")
        before := strconv.atoi(parts[0])
        after := strconv.atoi(parts[1])
        values := parsed_input.rules[before] or_else {}
        append(&values, after)
        parsed_input.rules[before] = values
    }

    for line in strings.split_lines_iterator(&remaining) {
        if len(line) == 0 do break

        parts := strings.split(line, ",")
        pages: [dynamic]int

        for part in parts {
            page := strconv.atoi(part)
            append(&pages, page)
        }

        append(&parsed_input.updates, pages)

    }

    return parsed_input
}

main :: proc() {
    input := #load("input", string)

    utils.start_measure(utils.Step.Parse)
    parsed_input := parse(input)
    utils.end_measure()

    utils.start_measure(utils.Step.Part1)
    part_1_result := part_1(parsed_input.rules, parsed_input.updates)
    utils.end_measure()

    utils.start_measure(utils.Step.Part2)
    part_2_result := part_2(parsed_input.rules, parsed_input.updates)
    utils.end_measure()

    utils.print_results(part_1_result, part_2_result)
}

solve :: proc(rules: Rules, updates: Updates, reorder: bool) -> int {
    updates := updates
    reordered_updates: [dynamic]int
    defer delete(reordered_updates)
    result := 0
    for i_update in 0..<len(updates) {
        update := updates[i_update]
        correct := true
        loop_before: for i_before in 0..<len(update) {
            before := update[i_before]
            after, found := rules[before]
            if !found do continue // this page number is already in the right spot

            loop_reorder: for {
                loop_update: for i_check in 0..<len(update) {
                    for i_after in 0..<len(after) {
                        if update[i_check] == after[i_after] && i_check < i_before {
                            correct = false

                            if reorder {
                                a := update[i_check]
                                b := update[i_before]
                                update[i_check] = b
                                update[i_before] = a
                                break
                            }

                            break loop_before
                        }
                    }

                    if !correct && reorder {
                        _, found := slice.linear_search(reordered_updates[:], i_update)
                        if !found do append(&reordered_updates, i_update)
                    }

                    correct = true
                }

                if !reorder || correct do break
            }
        }

        if correct && !reorder do result += update[len(update) / 2]
    }

    if reorder {
        for index in reordered_updates {
            update := updates[index]
            result += update[len(update) / 2]
        }
    }

    return result
}

part_1 :: proc(rules: Rules, updates: Updates) -> int {
    return solve(rules, updates, false)
}

part_2 :: proc(rules: Rules, updates: Updates) -> int {
    return solve(rules, updates, true)
}

TEST_INPUT := #load("test_input", string)
TEST_INPUT_PARSED := parse(TEST_INPUT)

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT_PARSED.rules, TEST_INPUT_PARSED.updates) == 143)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT_PARSED.rules, TEST_INPUT_PARSED.updates) == 123)
}
