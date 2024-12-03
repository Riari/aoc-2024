package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"

import "../utils"

main :: proc() {
    input := utils.read_input()
    lines, _ := strings.split_lines(input)

    reports := make([dynamic][dynamic]int, len(lines))

    for i in 0..<len(lines) {
        if lines[i] == "" {
            continue
        }
        levels, _ := strings.fields(lines[i])
        level_ints := make([dynamic]int, len(levels))
        for y in 0..<len(levels) {
            level, _ := strconv.parse_int(levels[y])
            level_ints[y] = level
        }

        reports[i] = level_ints
    }

    part_1_result := part_1(reports)
    part_2_result := part_2(reports)

    fmt.printfln("Part 1: %d", part_1_result)
    fmt.printfln("Part 2: %d", part_2_result)
    return
}

test_removals :: proc(report: [dynamic]int, remove: [dynamic]int) -> bool {
    for index in remove {
        alt := slice.clone_to_dynamic(report[:])
        defer delete(alt)

        ordered_remove(&alt, index)

        if is_report_safe(alt, false) {
            fmt.println(report)
            return true
        }
    }

    return false
}

is_report_safe :: proc(report: [dynamic]int, dampen: bool) -> bool {
    increases: [dynamic]int
    decreases: [dynamic]int
    unchanged: [dynamic]int
    too_large: [dynamic]int
    defer {
        delete(increases)
        delete(decreases)
        delete(unchanged)
        delete(too_large)
    }

    for j in 0..<len(report) - 1 {
        a := report[j]
        b := report[j + 1]

        diff := b - a

        if diff > 0 && diff < 4 {
            append(&increases, j)
            append(&increases, j + 1)
        } else if diff > -4 && diff < 0 {
            append(&decreases, j)
            append(&decreases, j + 1)
        } else if diff < -3 || diff > 3 {
            append(&too_large, j)
            append(&too_large, j + 1)
        } else {
            append(&unchanged, j)
            append(&unchanged, j + 1)
        }
    }

    if len(unchanged) == 0 && len(too_large) == 0 {
        if len(increases) == 0 || len(decreases) == 0 {
            return true
        }
    }

    if !dampen {
        return false
    }

    if len(unchanged) > 0 {
        if test_removals(report, unchanged) {
            return true
        }
    }

    if len(too_large) > 0 {
        if test_removals(report, too_large) {
            return true
        }
    }

    if len(increases) > len(decreases) {
        if test_removals(report, decreases) {
            return true
        }
    }

    if len(decreases) > len(increases) {
        if test_removals(report, increases) {
            return true
        }
    }

    return false
}

solve :: proc(reports: [dynamic][dynamic]int, dampen: bool) -> int {
    safe_count := 0
    for i in 0..<len(reports) {
        if len(reports[i]) == 0 { continue }
        if is_report_safe(reports[i], dampen) { safe_count += 1 }
    }

    return safe_count
}

part_1 :: proc(reports: [dynamic][dynamic]int) -> int {
    return solve(reports, false)
}

part_2 :: proc(reports: [dynamic][dynamic]int) -> int {
    return solve(reports, true)
}

TEST_INPUT := [dynamic][dynamic]int{
    {7, 6, 4, 2, 1},
    {1, 2, 7, 8, 9},
    {9, 7, 6, 2, 1},
    {1, 3, 2, 4, 5},
    {8, 6, 4, 4, 1},
    {1, 3, 6, 7, 9},
    {48, 46, 47, 49, 51, 54, 56},
    {1, 1, 2, 3, 4, 5},
    {1, 2, 3, 4, 5, 5},
    {5, 1, 2, 3, 4, 5},
    {1, 4, 3, 2, 1},
    {1, 6, 7, 8, 9},
    {1, 2, 3, 4, 3},
    {9, 8, 7, 6, 7},
    {7, 10, 8, 10, 11},
    {29, 28, 27, 25, 26, 25, 22, 20},
    {1, 2, 3, 10, 4, 5},
    {1, 10, 11, 12, 13},
    {10, 1, 2, 3, 4, 5},
    {75, 77, 72, 70, 69},
    {31, 34, 32, 30, 28, 27, 24, 22},
    {7, 10, 8, 10, 11},
    {1, 2, 3, 4, 5, 5},
    {90, 89, 86, 84, 83, 79},
    {97, 96, 93, 91, 85},
    {29, 26, 24, 25, 21},
    {36, 37, 40, 43, 47},
    {43, 44, 47, 48, 49, 54},
    {35, 33, 31, 29, 27, 25, 22, 18},
    {77, 76, 73, 70, 64},
    {68, 65, 69, 72, 74, 77, 80, 83},
    {37, 40, 42, 43, 44, 47, 51},
    {70, 73, 76, 79, 86}
}

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT) == 2)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT) == 31)
}
