package main

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:thread"

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

TaskPayload :: struct{
    trail_map: ^[]string,
    calculate_rating: bool,
    start_at: ^Vector2i,
    destinations: ^[dynamic]Vector2i,
    score: int
}

DIRECTIONS := [4]Vector2i{
    {0, -1},    // N
    {1, 0},     // E
    {0, 1},     // S
    {-1, 0}     // W
}

is_valid_step :: proc(trail_map: ^[]string, width: int, height: int, from: Vector2i, to: Vector2i) -> bool {
    if to.x < 0 || to.y < 0 || to.x >= width || to.y >= height do return false
    return trail_map[to.y][to.x] == trail_map[from.y][from.x] + 1
}

step :: proc(trail_map: ^[]string, width: int, height: int, position: Vector2i, destination: Vector2i) -> int {
    valid := 0
    for i in 0..<len(DIRECTIONS) {
        direction := DIRECTIONS[i]
        next := Vector2i{position.x + direction.x, position.y + direction.y}

        if !is_valid_step(trail_map, width, height, position, next) do continue

        valid += step(trail_map, width, height, next, destination)
    }

    return valid + cast(int)(position == destination)
}

get_score :: proc(trail_map: ^[]string, position: Vector2i, destination: Vector2i) -> int {
    position := position

    width := len(trail_map[0])
    height := len(trail_map) - 1

    return step(trail_map, width, height, position, destination)
}

process_trails_task: thread.Task_Proc : proc(task: thread.Task) {
    payload := cast(^TaskPayload)task.data
    payload.score = 0

    for i in 0..<len(payload.destinations) {
        destination := payload.destinations[i]
        score := get_score(payload.trail_map, payload.start_at^, destination)
        payload.score += payload.calculate_rating ? score : score > 0
    }
}

solve :: proc(trail_map: []string, calculate_ratings: bool) -> int {
    trail_map := trail_map

    zeros: [dynamic]Vector2i
    nines: [dynamic]Vector2i
    defer {
        delete(zeros)
        delete(nines)
    }

    width := len(trail_map[0])
    height := len(trail_map) - 1

    for y in 0..<height {
        for x in 0..<width {
            if trail_map[y][x] == '0' do append(&zeros, Vector2i{x, y})
            else if trail_map[y][x] == '9' do append(&nines, Vector2i{x, y})
        }
    }

    pool: thread.Pool
    thread_count :: 4
    thread.pool_init(&pool, context.allocator, thread_count)

    task_payloads := make([dynamic]TaskPayload, len(zeros))
    defer delete(task_payloads)

    for i in 0..<len(zeros) {
        payload: TaskPayload
        payload.trail_map = &trail_map
        payload.calculate_rating = calculate_ratings
        payload.start_at = &zeros[i]
        payload.destinations = &nines
        task_payloads[i] = payload
        thread.pool_add_task(&pool, context.allocator, process_trails_task, &task_payloads[i])
    }

    thread.pool_start(&pool)
    thread.pool_finish(&pool)
    thread.pool_destroy(&pool)

    total := 0

    for payload in task_payloads {
        total += payload.score
    }

    return total
}

part_1 :: proc(trail_map: []string) -> int {
    return solve(trail_map, false)
}

part_2 :: proc(trail_map: []string) -> int {
    return solve(trail_map, true)
}

TEST_INPUT := parse(#load("test_input", string))

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT) == 36)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT) == 81)
}
