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
    input := input
    parsed: [dynamic]string
    for line in strings.split_lines_iterator(&input) {
        if len(line) == 0 do continue
        append(&parsed, line)
    }

    return parsed[:]
}

Vector2i :: struct{
    x: int,
    y: int
}

N := Vector2i{0, -1}
E := Vector2i{1, 0}
S := Vector2i{0, 1}
W := Vector2i{-1, 0}

DIRECTIONS := [4]Vector2i{N, E, S, W}

Step :: struct{
    position: Vector2i,
    direction: Vector2i
}

Path :: [dynamic]Step

Node :: struct{
    position: Vector2i,
    direction_index: int,
    score: int
}

Branch :: struct{
    direction_index: int,
    score: int
}

clone_path :: proc(path: [dynamic]Step) -> [dynamic]Step {
    new_path: [dynamic]Step
    for step in path do append(&new_path, step)
    return new_path
}

go :: proc(input: []string, starting_nodes: []Node, scores: ^[dynamic][dynamic]int, best_tiles_mode: bool) -> int {
    queue := make([dynamic]Node)
    defer delete(queue)

    for node in starting_nodes {
        append(&queue, node)
    }

    visited: map[Vector2i]bool
    defer delete(visited)
    best_tiles := 1

    branches: [3]Branch
    for {
        if len(queue) == 0 do break

        current := queue[0]
        ordered_remove(&queue, 0)

        left := current.direction_index - 1 < 0 ? 3 : current.direction_index - 1
        right := current.direction_index + 1 > 3 ? 0 : current.direction_index + 1

        modifier_forwards := best_tiles_mode ? -1 : 1
        modifier_turn := best_tiles_mode ? -1001 : 1001

        branches[0] = Branch{current.direction_index, current.score + modifier_forwards}
        branches[1] = Branch{left, current.score + modifier_turn}
        branches[2] = Branch{right, current.score + modifier_turn}

        for branch in branches {
            direction := DIRECTIONS[branch.direction_index]
            next := Vector2i{current.position.x + direction.x, current.position.y + direction.y}
            score := scores[next.y][next.x]

            if best_tiles_mode {
                is_visited := next in visited
                if (score == branch.score || score == branch.score - 1000) && !is_visited {
                    best_tiles += 1
                    node: Node
                    node.position = next
                    node.direction_index = branch.direction_index
                    node.score = branch.score
                    append(&queue, node)
                    visited[next] = true
                }

                continue
            }

            if input[next.y][next.x] == '#' do continue

            if score > branch.score {
                scores[next.y][next.x] = branch.score
                node: Node
                node.position = next
                node.direction_index = branch.direction_index
                node.score = branch.score
                append(&queue, node)
            }
        }
    }

    if best_tiles_mode do return best_tiles + 1

    return scores[1][len(input[0]) - 2]
}

solve :: proc(input: []string, best_tiles_mode: bool) -> int {
    scores: [dynamic][dynamic]int

    defer {
        for i in 0..<len(scores) {
            delete(scores[i])
        }

        delete(scores)
    }

    resize(&scores, len(input))
    for y in 0..<len(scores) {
        scores_x: [dynamic]int
        resize(&scores_x, len(input[0]))

        for x in 0..<len(scores_x) {
            scores_x[x] = max(int)
        }

        scores[y] = scores_x
    }

    start: Node
    start.position = Vector2i{1, len(input) -2}
    start.direction_index = 1 // East
    start.score = 0

    starting_nodes: [dynamic]Node
    defer delete(starting_nodes)
    append(&starting_nodes, start)

    end_score := go(input, starting_nodes[:], &scores, false)

    if best_tiles_mode {
        end_position := Vector2i{len(input[0]) - 2, 1}
        start_1: Node
        start_1.position = end_position
        start_1.direction_index = 2 // South
        start_1.score = end_score
        start_2: Node
        start_2.position = end_position
        start_2.direction_index = 3 // West
        start_2.score = end_score

        starting_nodes[0] = start_1
        append(&starting_nodes, start_2)

        return go(input, starting_nodes[:], &scores, true)
    }

    return end_score
}

part_1 :: proc(input: []string) -> int {
    return solve(input, false)
}

part_2 :: proc(input: []string) -> int {
    return solve(input, true)
}

TEST_INPUT := parse(#load("test_input", string))

@(test)
test_part_1 :: proc(t: ^testing.T) {
    assert(part_1(TEST_INPUT) == 7036)
}

@(test)
test_part_2 :: proc(t: ^testing.T) {
    assert(part_2(TEST_INPUT) == 45)
}
