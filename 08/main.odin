package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"

import "../utils"

Vector2i :: struct{
    x: int,
    y: int
}

Antennas :: map[u8][dynamic]Vector2i

Antinodes :: map[Vector2i]bool

AntennaMap :: struct{
    data: []string,
    width: int,
    height: int,
    antennas: Antennas
}

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

parse :: proc(input: string) -> AntennaMap {
    data := strings.split_lines(input)
    width := len(data[0])
    height := len(data) - 1
    antennas: Antennas
    for y in 0..<height {
        for x in 0..<width {
            cell := data[y][x]
            if cell == '.' do continue

            position := Vector2i{x, y}

            frequency_antennas := antennas[cell] or_else {}
            append(&frequency_antennas, position)
            antennas[cell] = frequency_antennas
        }
    }

    return {data, width, height, antennas}
}

solve :: proc(antenna_map: AntennaMap, repeating: bool) -> int {
    antinodes := make(Antinodes)
    defer delete(antinodes)
    for frequency, positions in antenna_map.antennas {
        for i in 0..<len(positions) {
            for j in 0..<len(positions) {
                if i == j do continue

                a := positions[i]
                b := positions[j]

                diff := Vector2i{a.x - b.x, a.y - b.y}

                if repeating {
                    pos := Vector2i{b.x + diff.x, b.y + diff.y}
                    for ; pos.x >= 0 && pos.y >= 0 && pos.x < antenna_map.width && pos.y < antenna_map.height; {
                        antinodes[pos] = true
                        pos = Vector2i{pos.x + diff.x, pos.y + diff.y}
                    }

                    continue
                }

                pos := Vector2i{a.x + diff.x, a.y + diff.y}

                if pos.x < 0 || pos.y < 0 || pos.x >= antenna_map.width || pos.y >= antenna_map.height do continue

                antinodes[pos] = true
            }
        }
    }

    return len(antinodes)
}

part_1 :: proc(antenna_map: AntennaMap) -> int {
    return solve(antenna_map, false)
}

part_2 :: proc(antenna_map: AntennaMap) -> int {
    return solve(antenna_map, true)
}

TEST_INPUT := parse(#load("test_input", string))

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT) == 14)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT) == 34)
}
