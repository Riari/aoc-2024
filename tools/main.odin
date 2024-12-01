package tools

import "core:log"
import "core:os"
import "core:strings"

PATH_STUB :: "utils/init/stub"
FILENAME_MAIN :: "main.odin"
FILENAME_INPUT :: "input"

main :: proc() {
    directory_name := os.args[1]

    os.make_directory(directory_name)

    path_main := strings.join({directory_name, FILENAME_MAIN}, "/")

    if os.exists(path_main) {
        panic("Path already exists!")
    }

    main_stub_bytes, success := os.read_entire_file_from_filename(PATH_STUB)
    if !success {
        panic("Failed to read stub")
    }

    err := os.write_entire_file_or_err(path_main, main_stub_bytes)
    if err != os.ERROR_NONE {
        panic("Failed to write main file")
    }

    // TODO: add support for fetching input via AoC session
    path_input := strings.join({directory_name, FILENAME_INPUT}, "/")
    err = os.write_entire_file_or_err(path_input, {})
    if err != os.ERROR_NONE {
        panic("Failed to write input file")
    }

    log.info("Created %s", path_main)
}