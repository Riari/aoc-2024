package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:unicode"

import "../utils"

Disk1 :: struct{
    layout: [dynamic]int,
    blocks: [dynamic]int
}

File :: struct{
    id: int,
    starts_at: int,
    size: int
}

Disk2 :: struct{
    size: int,
    free: [dynamic]int,
    files: [dynamic]File
}

main :: proc() {
    input := #load("input", string)

    utils.start_measure(utils.Step.Parse)
    parsed_input := parse_part_1(input)
    utils.end_measure()

    utils.start_measure(utils.Step.Part1)
    part_1_result := part_1(parsed_input)
    utils.end_measure()

    utils.start_measure(utils.Step.Part2)
    part_2_result := part_2(parse_part_2(input))
    utils.end_measure()

    utils.print_results(part_1_result, part_2_result)
}

parse_part_1 :: proc(input: string) -> Disk1 {
    disk: Disk1

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

parse_part_2 :: proc(input: string) -> Disk2 {
    disk: Disk2

    resize(&disk.free, 98304)
    for i in 0..<len(disk.free) {
        disk.free[i] = 0
    }

    is_file := true
    file_id := 0
    for char in input {
        if unicode.is_space(char) do continue

        size := strconv.atoi(fmt.tprint(char))

        if is_file {
            file: File
            file.id = file_id
            file.starts_at = disk.size
            file.size = size
            append(&disk.files, file)

            file_id += 1
        } else {
            disk.free[disk.size] = size
        }

        disk.size += size
        is_file = !is_file
    }

    return disk
}

print_disk_map :: proc(disk: Disk2) {
    disk_map := make([dynamic]string, disk.size)
    defer delete(disk_map)

    for i in 0..<len(disk.free) {
        if i >= disk.size do break
        if disk.free[i] == 0 do continue

        for j := 0; j < disk.free[i]; j += 1 {
            disk_map[i + j] = "."
        }
    }
    for file in disk.files {
        for i := file.starts_at; i < file.starts_at + file.size; i += 1 {
            disk_map[i] = fmt.tprint(file.id)
        }
    }

    for char in disk_map {
        fmt.print(char)
    } fmt.print("\n")
}

part_1 :: proc(disk: Disk1) -> int {
    defer {
        delete(disk.layout)
        delete(disk.blocks)
    }

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

sort_files :: proc(l, r: File) -> bool {
    return l.starts_at < r.starts_at
}

part_2 :: proc(disk: Disk2) -> int {
    defer {
        delete(disk.free)
        delete(disk.files)
    }

    for i := len(disk.files) - 1; i >= 0; i -= 1 {
        file := &disk.files[i]

        for j := 0; j < file.starts_at; j += 1 {
            if disk.free[j] < file.size do continue

            disk.free[j] -= file.size

            if disk.free[j] != 0 {
                leftover := disk.free[j]
                disk.free[j + file.size] = leftover
                disk.free[j] = 0
            }

            free_left := 0
            for k := j - 1; k > 0; k -= 1 {
                if k + disk.free[k] == file.starts_at {
                    free_left = k
                    disk.free[k] += file.size
                    break
                }
            }

            if free_left > 0 {
                for k := j + 1; k < len(disk.free); k += 1 {
                    if k == file.starts_at + file.size {
                        disk.free[free_left] += disk.free[k]
                        disk.free[k] = 0
                        break
                    }
                }

                disk.free[file.starts_at] = 0
            } else {
                disk.free[file.starts_at] = file.size
            }

            file.starts_at = j

            break
        }
    }

    slice.sort_by(disk.files[:], sort_files)

    checksum := 0
    for i in 0..<len(disk.files) {
        for j := 0; j < disk.files[i].size; j += 1 {
            position := disk.files[i].starts_at + j
            checksum += position * disk.files[i].id
        }
    }

    return checksum
}

TEST_INPUT := #load("test_input", string)

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(parse_part_1(TEST_INPUT)) == 1928)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(parse_part_2(TEST_INPUT)) == 2858)
}
