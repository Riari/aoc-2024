package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:unicode"

import "../utils"

Disk :: struct{
    layout: [dynamic]int,
    blocks: [dynamic]int
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

parse :: proc(input: string) -> Disk {
    disk: Disk
    is_file := true
    id := 0
    for char in input {
        if unicode.is_space(char) do continue
        number := strconv.atoi(fmt.tprint(char))
        append(&disk.layout, number)
        if is_file {
            for i in 0..<number {
                append(&disk.blocks, id)
            }

            id += 1
        } else {
            for i in 0..<number do append(&disk.blocks, -1)
        }

        is_file = !is_file
    }

    return disk
}

solve :: proc(disk: Disk) -> int {
    disk := disk

    write_seek_from := len(disk.blocks) - 1
    for i := 0; i < len(disk.blocks); i += 1 {
        if write_seek_from <= i do break
        if disk.blocks[i] != -1 do continue

        byte: u8
        for j := write_seek_from; j > i; j -= 1 {
            if disk.blocks[j] == -1 do continue
            disk.blocks[i] = disk.blocks[j]
            disk.blocks[j] = -1
            write_seek_from = j
            break
        }
    }

    checksum := 0
    for i := 0; i < len(disk.blocks); i += 1 {
        if disk.blocks[i] == -1 do continue
        id := disk.blocks[i]
        checksum += i * id
    }

    return checksum
}

part_1 :: proc(disk: Disk) -> int {
    return solve(disk)
}

part_2 :: proc(disk: Disk) -> int {
    return solve(disk)
}

TEST_INPUT := parse(#load("test_input", string))

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT) == 1928)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT) == 1928)
}
