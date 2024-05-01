package raytest

import "core:fmt"
import "core:math"
import cm "core:math/cmplx"
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

fftiter :: proc (out_fft: []$T) {
    N := len(out_fft)
    order := u64(math.ilogb_f32(f32(N)))

    reverse_bit_order(out_fft[:], order)
    n1 := 0
    n2 :=1

    // i is the depth of the butter flies in the fft, so for a vector length of 8
    // we get a depth of 3 (2^3).
    for i in 0..<order {
        n1 = n2
        n2 *= 2
        step_angle := -2.0 * math.PI / f64(n2)
        angle :f64 = 0.0

        for j in 0..<n1 {
            // j will select odd even
            factors := cm.exp_complex128(complex(0.0, angle))
            angle += step_angle

            for k:= j; k< N; k += n2 {
                tmp := out_fft[k]
                out_fft[k] += factors * out_fft[k + n1]
                out_fft[k + n1] = tmp - factors * out_fft[k + n1] // n/2 mirrored path

            }
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

@(test)
fftiter_test :: proc(t: ^testing.T ) {
    signal := [?]complex128 {
        complex(1.0, 0.0),
        complex(2.0, 0.0),
        complex(3.0, 0.0),
        complex(4.0, 0.0),
        complex(5.0, 0.0),
        complex(6.0, 0.0),
        complex(7.0, 0.0),
        complex(8.0, 0.0)
    }
    expected := [?]complex128 {
        complex(  36.0,  0.0 ),
        complex(
             -4.0,
             9.65685424949238,
        ),
        complex(  -4.0,  4.0 ),
        complex(
             -4.0,
             1.6568542494923797,
        ),
        complex(  -4.0,  0.0 ),
        complex(
             -3.9999999999999996,
             -1.6568542494923797,
        ),
            complex(
                 -3.9999999999999996,
                 -4.0,
            ),
        complex(
             -3.9999999999999987,
             -9.65685424949238,
        )
    }

    fftiter(signal[:])
    
    testing.expect(t, expected == signal, fmt.tprintf("Expected %v got %v\n", expected, signal))
}
