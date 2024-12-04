package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:unicode"
import "core:unicode/utf8"

import "../utils"

main :: proc() {
    input := utils.read_input()

    part_1_result := part_1(input)
    part_2_result := part_2(input)

    fmt.printfln("Part 1: %d", part_1_result)
    fmt.printfln("Part 2: %d", part_2_result)
    return
}

PATTERN_MUL := []rune{'m', 'u', 'l', '(', ',', ')'}
PATTERN_DONT := []rune{'d', 'o', 'n', '\'', 't', '(', ')'}
PATTERN_DO := []rune{'d', 'o', '(', ')'}

solve :: proc(memory: string, ignore_disabling: bool) -> int {
    mul_index := 0
    dont_index := 0
    do_index := 0

    mul_enabled := true

    total := 0
    finished_left := false
    left := [dynamic]rune{}
    right := [dynamic]rune{}
    defer {
        delete(left)
        delete(right)
    }

    for character in memory {
        if !ignore_disabling {
            if character == PATTERN_DONT[dont_index] {
                dont_index += 1
                if dont_index >= len(PATTERN_DONT) {
                    mul_enabled = false
                    dont_index = 0
                }
            } else {
                dont_index = 0
            }

            if character == PATTERN_DO[do_index] {
                do_index += 1
                if do_index >= len(PATTERN_DO) {
                    mul_enabled = true
                    do_index = 0
                }
            } else {
                do_index = 0
            }
        }

        looking_for := PATTERN_MUL[mul_index]

        if unicode.is_number(character) && (looking_for == ',' || looking_for == ')') {
            if looking_for == ',' {
                append(&left, character)
            } else {
                append(&right, character)
            }

            continue
        }

        if character == PATTERN_MUL[mul_index] {
            if character == ')' {
                if ignore_disabling || mul_enabled {
                    left_string := utf8.runes_to_string(left[:])
                    right_string := utf8.runes_to_string(right[:])
                    defer {
                        delete(left_string)
                        delete(right_string)
                    }

                    a, _ := strconv.parse_int(left_string)
                    b, _ := strconv.parse_int(right_string)

                    total += a * b
                }

                mul_index = 0
                clear(&left)
                clear(&right)
            } else {
                mul_index += 1
            }
        } else {
            mul_index = 0
            clear(&left)
            clear(&right)
        }
    }

    return total
}

part_1 :: proc(memory: string) -> int {
    return solve(memory, true)
}

part_2 :: proc(memory: string) -> int {
    return solve(memory, false)
}

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1("xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))") == 161)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2("xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))") == 48)
}
