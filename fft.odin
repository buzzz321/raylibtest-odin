package raytest

import "core:fmt"
import "core:math"
import "core:os"
import "core:testing"

//bit reverse algo from https://www.katjaas.nl/bitreversal/bitreversal.html
bit_reverse :: proc(n: u64, bit_width: u64 ) -> u64 {
    reverse := n
    mask : u64 = 1 << bit_width
    input := n

    for i in 1..< bit_width {
        input >>= 1
        reverse <<= 1
        reverse |= input & 1
    }
    reverse &= mask -1
    return reverse
}

@(test)
bit_reverse_test :: proc(t: ^testing.T) {
    result := bit_reverse(4,3)
    testing.expect(t, result == 1, fmt.tprintf("Execpted %v got %v\n",1,result))
}

