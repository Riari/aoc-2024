package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"

import "../utils"

Vector2i :: struct {
    x: i16,
    y: i16
}

DIRECTIONS := [8]Vector2i{
    {0, -1},    // ↑
    {1, -1},    // ↗
    {1, 0},     // →
    {1, 1},     // ↘
    {0, 1},     // ↓
    {-1, 1},    // ↙
    {-1, 0},    // ←
    {-1, -1},   // ↖
}

DIRECTIONS_DIAGONALS_ONLY := [4]Vector2i{
    DIRECTIONS[1],
    DIRECTIONS[3],
    DIRECTIONS[5],
    DIRECTIONS[7],
}

main :: proc() {
    input := utils.read_input()
    lines, _ := strings.split_lines(input)

    part_1_result := part_1(lines)
    part_2_result := part_2(lines)

    fmt.printfln("Part 1: %d", part_1_result)
    fmt.printfln("Part 2: %d", part_2_result)
    return
}

search :: proc(grid: []string, position: Vector2i, direction: Vector2i, word: string) -> Vector2i {
    width := i16(len(grid[0]))
    height := i16(len(grid) - 1)
    position := position
    position_a := Vector2i{-1, -1}
    for i in 1..<len(word) {
        position.x += direction.x
        position.y += direction.y

        if position.y < 0 || position.y >= height || position.x < 0 || position.x >= width { return {-1, -1} }

        if grid[position.y][position.x] != word[i] { return {-1, -1} }

        if word[i] == 'A' { position_a = position }
    }

    return position_a
}

solve :: proc(grid: []string, word: string, x_mas_mode: bool) -> int {
    width := i16(len(grid[0]))
    height := i16(len(grid) - 1)

    mas_centres := make(map[Vector2i]int)
    defer delete(mas_centres)

    directions := x_mas_mode ? DIRECTIONS_DIAGONALS_ONLY[:] : DIRECTIONS[:];

    count := 0
    for y in 0..<height {
        for x in 0..<width {
            if grid[y][x] == word[0] {
                for direction in directions {
                    position_a := search(grid, {x, y}, direction, word)
                    if position_a.x >= 0 && position_a.y >= 0 {
                        if x_mas_mode {
                            mas_centres[position_a] += 1
                        } else {
                            count += 1
                        }
                    }
                }
            }
        }
    }

    if x_mas_mode {
        for position, occurrences in mas_centres {
            if occurrences == 2 { count += 1 }
        }
    }

    return count
}

part_1 :: proc(grid: []string) -> int {
    return solve(grid, "XMAS", false)
}

part_2 :: proc(grid: []string) -> int {
    return solve(grid, "MAS", true)
}

TEST_INPUT := []string{
    "MMMSXXMASM",
    "MSAMXMSMSA",
    "AMXSXMAAMM",
    "MSAMASMSMX",
    "XMASAMXAMM",
    "XXAMMXXAMA",
    "SMSMSASXSS",
    "SAXAMASAAA",
    "MAMMMXMMMM",
    "MXMXAXMASX",
    "" // need a blank line because split_lines ends up with this for the real input even though the file has no empty line at the end :(
}

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT) == 18)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT) == 9)
}
