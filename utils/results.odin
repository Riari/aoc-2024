package utils

import "core:fmt"
import "core:time"

Step :: enum {
    Parse,
    Part1,
    Part2
}

Measurements :: struct {
    parse_time_ms: f64,
    part_1_time_ms: f64,
    part_2_time_ms: f64,
    total: f64
}

stopwatch: time.Stopwatch
current_step: Step
measurements: Measurements

start_measure :: proc(step: Step) {
    current_step = step
    time.stopwatch_reset(&stopwatch)
    time.stopwatch_start(&stopwatch)
}

end_measure :: proc() {
    time.stopwatch_stop(&stopwatch)
    duration := time.stopwatch_duration(stopwatch)
    duration_ms := time.duration_milliseconds(duration)
    measurements.total += duration_ms

    switch current_step {
    case .Parse: measurements.parse_time_ms = duration_ms
    case .Part1: measurements.part_1_time_ms = duration_ms
    case .Part2: measurements.part_2_time_ms = duration_ms
    }
}

print_results_string :: proc(part_1_result: string, part_2_result: string) {
    fmt.printfln("Parsed input in %f ms", measurements.parse_time_ms)
    fmt.printfln("Part 1: %s (took %f ms)", part_1_result, measurements.part_1_time_ms)
    fmt.printfln("Part 2: %s (took %f ms)", part_2_result, measurements.part_2_time_ms)
    fmt.printfln("Total time: %f ms", measurements.total)
}

print_results_int :: proc(part_1_result: int, part_2_result: int) {
    print_results_string(fmt.aprintf("%d", part_1_result), fmt.aprintf("%d", part_2_result))
}

print_results_f32 :: proc(part_1_result: f32, part_2_result: f32) {
    print_results_string(fmt.aprintf("%f", part_1_result), fmt.aprintf("%f", part_2_result))
}

print_results :: proc{print_results_string, print_results_int, print_results_f32}
