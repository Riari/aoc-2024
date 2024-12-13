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

print_results :: proc(part_1_result: $T1, part_2_result: $T2) {
    fmt.printfln("Parsed input in %f ms", measurements.parse_time_ms)
    fmt.printfln("Part 1: %s (took %f ms)", fmt.aprintf("%d", part_1_result), measurements.part_1_time_ms)
    fmt.printfln("Part 2: %s (took %f ms)", fmt.aprintf("%d", part_2_result), measurements.part_2_time_ms)
    fmt.printfln("Total time: %f ms", measurements.total)
}

