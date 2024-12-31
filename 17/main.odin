package main

import "core:fmt"
import "core:math"
import "core:math/big"
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

Program :: [dynamic]int

CPU :: struct{
    a: int,
    b: int,
    c: int,
    program: Program,
    pointer: int,
    output: [dynamic]int
}

parse :: proc(input: string) -> CPU {
    input := input
    cpu: CPU
    cpu.pointer = 0
    i := 0
    for line in strings.split_lines_iterator(&input) {
        if len(line) == 0 do continue

        parts, err := strings.split(line, ": ")

        if err != nil {
            fmt.eprintln("Oh no :(")
            break
        }

        switch i {
        case 0: // Register A
            cpu.a = strconv.atoi(parts[1])
        case 1: // Register B
            cpu.b = strconv.atoi(parts[1])
        case 2: // Register C
            cpu.c = strconv.atoi(parts[1])
        case 3: // Program
            program: [dynamic]int
            for instruction in strings.split_iterator(&parts[1], ",") {
                append(&program, strconv.atoi(instruction))
            }
            cpu.program = program
        }

        i += 1
    }

    return cpu
}

clone_cpu :: proc(cpu: CPU) -> CPU {
    cpu_copy: CPU
    cpu_copy.a = cpu.a
    cpu_copy.b = cpu.b
    cpu_copy.c = cpu.c
    cpu_copy.program = cpu.program
    cpu_copy.pointer = cpu.pointer
    cpu_copy.output = cpu.output
    return cpu_copy
}

divide :: proc(cpu: ^CPU, opcode: int, operand: int) -> int {
    cpu := cpu
    numerator := cpu.a
    denominator := cast(int)math.pow(f32(2), cast(f32)get_combo_operand(cpu, operand))
    return numerator / denominator
}

get_combo_operand :: proc(cpu: ^CPU, operand: int) -> int {
    assert(operand < 7, "combo operand must be 0-6")

    switch operand {
    case 0: fallthrough
    case 1: fallthrough
    case 2: fallthrough
    case 3: return operand
    case 4: return cpu.a
    case 5: return cpu.b
    case 6: return cpu.c
    }

    return 0
}

run :: proc(cpu_original: CPU) -> []int {
    cpu := clone_cpu(cpu_original)
    defer delete(cpu.output)

    for {
        if cpu.pointer >= len(cpu.program) do break

        opcode := cpu.program[cpu.pointer]
        operand := cpu.program[cpu.pointer + 1]

        cpu.pointer += 2

        switch opcode {
        case 0: // adv
            cpu.a = divide(&cpu, opcode, operand)
        case 1: // bxl
            cpu.b = cpu.b ~ operand
        case 2: // bst
            cpu.b = get_combo_operand(&cpu, operand) % 8
        case 3: // jnz
            if cpu.a == 0 do continue
            cpu.pointer = operand
        case 4: // bxc
            cpu.b = cpu.b ~ cpu.c
        case 5: // out
            append(&cpu.output, get_combo_operand(&cpu, operand) % 8)
        case 6: // bdv
            cpu.b = divide(&cpu, opcode, operand)
        case 7: // cdv
            cpu.c = divide(&cpu, opcode, operand)
        }
    }

    output := make([]int, len(cpu.output))
    for i in 0..<len(output) {
        output[i] = cpu.output[i]
    }

    return output
}

part_1 :: proc(cpu: CPU) -> string {
    output := run(cpu)

    out_strings := make([]string, len(output))
    defer delete(out_strings)
    for i in 0..<len(output) {
        out_strings[i] = fmt.aprintf("%d", output[i])
    }

    return strings.join(out_strings[:], ",")
}

part_2 :: proc(cpu: CPU) -> string {
    cpu := cpu
    loop_outer: for i in 0..<max(int) {
        fmt.printfln("Executing with A = %d...", i)
        cpu_copy := clone_cpu(cpu)
        cpu_copy.a = i
        result := run(cpu_copy)

        if len(result) < len(cpu.program) do continue

        for j in 0..<len(result) {
            if result[j] != cpu.program[j] do continue loop_outer
        }

        fmt.printfln("Result: %v", result)
        fmt.printfln("Program: %v", cpu.program)

        return fmt.aprintf("%d", i)
    }

    return ":("
}

TEST_INPUT := parse(#load("test_input", string))

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT) == "4,6,3,5,6,3,5,2,1,0")
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT) == "")
}
