package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"

import "../utils"

main :: proc() {
    input := utils.read_input()
    pairs, _ := strings.split_lines(input)

    left := [dynamic]int{}
    right := [dynamic]int{}
    for pair in pairs {
        fields := strings.fields(pair)
        defer delete(fields)
        if len(fields) != 2 {
            break
        }
        l, _ := strconv.parse_int(fields[0])
        r, _ := strconv.parse_int(fields[1])
        append(&left, l)
        append(&right, r)
    }

    part_1_result := part_1(left[:], right[:])
    part_2_result := part_2(left[:], right[:])

    fmt.printfln("Part 1: %d", part_1_result)
    fmt.printfln("Part 2: %d", part_2_result)
}

part_1 :: proc(left: []int, right: []int) -> int {
    slice.sort(left)
    slice.sort(right)

    sum := 0
    for i in 0..<len(left) {
        sum += abs(left[i] - right[i])
    }

    return sum
}

part_2 :: proc(left: []int, right: []int) -> int {
    // Create a map of value -> number of occurrences
    slice.sort(right)
    occurrences := map[int]int{}
    defer delete(occurrences)
    value := right[0]
    count := 0
    for i in 0..<len(right) {
        if value != right[i] {
            occurrences[value] = count
            value = right[i]
            count = 0
        }

        count += 1
    }

    occurrences[value] = count

    // Use the map to calculate a total similarity score
    sum := 0
    for i in 0..<len(left) {
        value := left[i]
        sum += value * occurrences[value]
    }

    return sum
}

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1({3, 4, 2, 1, 3, 3}, {4, 3, 5, 3, 9, 3}) == 11)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2({3, 4, 2, 1, 3, 3}, {4, 3, 5, 3, 9, 3}) == 31)
}

