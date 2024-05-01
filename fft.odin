package raytest

import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
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

reverse_bit_order :: proc(signal : []$T, bits: u64) {
   for i:= 0; i <len(signal); i +=1 {
       j := int(bit_reverse(u64(i), bits))
    if i < j {
        slice.swap(signal, i, j)
    }
   }
}

@(test)
bit_reverse_test :: proc(t: ^testing.T) {
    result := bit_reverse(4,3)
    testing.expect(t, result == 1, fmt.tprintf("Execpted %v got %v\n",1,result))
}

@(test)
reverse_bit_order_test :: proc(t: ^testing.T) {
    signal := [?]i64{1,2,3,4,5,6,7,8}
    expected : = [?]i64{1,5,3,7,2,6,4,8}
    order := u64(math.ilogb_f64(f64(len(signal))))

    reverse_bit_order(signal[:], order)

    testing.expect(t, expected == signal, fmt.tprintf("Expected %v got %v\n", expected, signal))
}
