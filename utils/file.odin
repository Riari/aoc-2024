package utils

import "core:os"

read_input :: proc() -> string {
    input_bytes, _ := os.read_entire_file_from_filename("input")
    return string(input_bytes[:])
}