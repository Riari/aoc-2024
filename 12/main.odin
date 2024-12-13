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
    part_1_result := part_1(parsed_input)
    utils.end_measure()

    utils.start_measure(utils.Step.Part2)
    part_2_result := part_2(parsed_input)
    utils.end_measure()

    utils.print_results(part_1_result, part_2_result)
}

parse :: proc(input: string) -> []string {
    return strings.split_lines(input)
}

Vector2i :: struct{
    x: int,
    y: int
}

Region :: struct{
    type: u8,
    cells: map[Vector2i]bool,
    perimeter: int,
    sides_count: int,
    fence_price: int
}

N :: Vector2i{0, -1}
E :: Vector2i{1, 0}
S :: Vector2i{0, 1}
W :: Vector2i{-1, 0}

fill_region :: proc(grid: ^[]string, position: Vector2i, out_region: ^Region) {
    if position.x < 0 || position.y < 0 || position.x >= len(grid[0]) || position.y >= len(grid) - 1 do return

    if out_region.type != grid[position.y][position.x] do return

    if position in out_region.cells do return

    out_region.cells[position] = true

    fill_region(grid, {position.x + N.x, position.y + N.y}, out_region)
    fill_region(grid, {position.x + E.x, position.y + E.y}, out_region)
    fill_region(grid, {position.x + S.x, position.y + S.y}, out_region)
    fill_region(grid, {position.x + W.x, position.y + W.y}, out_region)
}

calculate_perimeter :: proc(grid: ^[]string, out_region: ^Region, count_sides: bool) {
    out_region.perimeter = 0
    out_region.sides_count = 0

    for position in out_region.cells {
        cells := out_region.cells

        north := Vector2i{position.x + N.x, position.y + N.y}
        east := Vector2i{position.x + E.x, position.y + E.y}
        south := Vector2i{position.x + S.x, position.y + S.y}
        west := Vector2i{position.x + W.x, position.y + W.y}

        has_north := north in cells
        has_east := east in cells
        has_south := south in cells
        has_west := west in cells

        if count_sides {
            sides := 0

            northeast := Vector2i{position.x + N.x + E.x, position.y + N.y + E.y}
            southeast := Vector2i{position.x + S.x + E.x, position.y + S.y + E.y}
            southwest := Vector2i{position.x + S.x + W.x, position.y + S.y + W.y}
            northwest := Vector2i{position.x + N.x + W.x, position.y + N.y + W.y}

            // Number of corners == number of sides

            // Count convex corners
            if !has_north && !has_east do sides += 1
            if !has_south && !has_east do sides += 1
            if !has_south && !has_west do sides += 1
            if !has_north && !has_west do sides += 1

            // Count concave corners
            if has_north && has_east && northeast not_in cells do sides += 1
            if has_south && has_east && southeast not_in cells do sides += 1
            if has_south && has_west && southwest not_in cells do sides += 1
            if has_north && has_west && northwest not_in cells do sides += 1

            out_region.sides_count += sides

            continue
        }

        perimeter := 4
        if has_north do perimeter -= 1
        if has_east do perimeter -= 1
        if has_south do perimeter -= 1
        if has_west do perimeter -= 1

        out_region.perimeter += perimeter
    }
}

solve :: proc(grid: []string, count_sides: bool) -> int {
    grid := grid

    visited := make(map[Vector2i]bool)
    regions := make([dynamic]Region)

    defer {
        delete(visited)
        delete(regions)
    }

    width := len(grid[0])
    height := len(grid) - 1

    current_type: u8 = ' '
    for y in 0..<height {
        for x in 0..<width {
            if grid[y][x] == current_type do continue

            position := Vector2i{x, y}

            if position in visited do continue

            region: Region
            region.type = grid[y][x]
            fill_region(&grid, position, &region)

            for cell in region.cells {
                visited[cell] = true
            }

            append(&regions, region)
        }
    }

    total_price := 0
    for i in 0..<len(regions) {
        calculate_perimeter(&grid, &regions[i], count_sides)
        area := len(regions[i].cells)
        regions[i].fence_price = count_sides ? area * regions[i].sides_count : area * regions[i].perimeter
        total_price += regions[i].fence_price

        delete(regions[i].cells)
    }

    return total_price
}

part_1 :: proc(grid: []string) -> int {
    return solve(grid, false)
}

part_2 :: proc(grid: []string) -> int {
    return solve(grid, true)
}

TEST_INPUT := parse(#load("test_input", string))

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT) == 1930)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT) == 1206)
}
