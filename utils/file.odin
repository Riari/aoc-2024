package utils

import "core:os"

read_input :: proc(filename: string = "input") -> string {
    input_bytes, _ := os.read_entire_file_from_filename(filename)
    return string(input_bytes[:])
}
