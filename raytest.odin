package raytest

import "core:c"
import "core:fmt"
import "core:math"
import cm "core:math/cmplx"
import "core:os"
import "core:sync"
import rl "vendor:raylib"

screenWidth: i32 : 800
screenHeight: i32 : 450

counter: i32 = 0

cb_data: [1024]f32

music_callback :: proc "c" (bufferData: rawptr, frames: c.uint) {
	data: [^]f32 = cast(^f32)bufferData

	sync.atomic_add(&counter, 1)
	for index in 0 ..< (frames * 2) {
		cb_data[index] = data[index]
	}
}

plot_wave :: proc() {
	for stride in 0 ..= 1 {
		x: i32 = 0
		for i in 0 ..< len(cb_data) / 2 {
			sample := cb_data[i * 2 + stride]
			if sample == 0 {
				continue
			}
			pixel :=
				cast(i32)math.round_f32(sample * 450.0) + screenHeight / 2 - 150 * cast(i32)stride
			if stride == 0 {
				rl.DrawPixel(x, pixel, rl.PURPLE)
			} else {
				rl.DrawPixel(x, pixel, rl.DARKPURPLE)
			}
			x += 1
		}
	}
}

plot_fft :: proc(signal: []f64) {
	x: i32 = 0
	BW: i32 : 2
	stride := len(signal) / cast(int)screenWidth
	//fmt.println(counter)

	for i := 0; i < len(signal); i += stride {
		height := cast(i32)signal[i]
		if height > 400 {
			height = 400
		}
		rl.DrawRectangle(x, (screenHeight - 20) - height, BW, height, rl.RED)
		x += BW
	}
}

raylibmain :: proc() {
	// Initialization
	//--------------------------------------------------------------------------------------

	rl.InitWindow(screenWidth, screenHeight, "raylib code test")
	defer rl.CloseWindow()

	rl.InitAudioDevice()
	defer rl.CloseAudioDevice()

	//music := rl.LoadSound("C64MattGraysDriller.ogg")
	music := rl.LoadSound("elimination.ogg")
	rl.SetTargetFPS(60)

	defer rl.StopSound(music)

	rl.AttachAudioMixedProcessor(music_callback)
	defer rl.DetachAudioMixedProcessor(music_callback)

	SPECTRUMSIZE: int : 512 * 32
	prevloop: [SPECTRUMSIZE / 2]f64
	start_play: bool = false
	for !rl.WindowShouldClose() {
		if rl.IsKeyDown(rl.KeyboardKey.P) {
			start_play = true
			rl.PlaySound(music)
		}
		cnt := sync.atomic_load(&counter)
		sync.atomic_store(&counter, 0)

		lchan: [SPECTRUMSIZE]complex128
		for i in 0 ..< (len(cb_data) / 2) {
			t := cast(f32)i / cast(f32)(len(cb_data) / 2)
			hann := 0.5 - 0.5 * math.cos_f32(2.0 * math.PI * (cast(f32)t * 2.0))

			lchan[i] = complex(cb_data[i * 2 + 0] * hann, 0.0)
		}
		fftiter(lchan[:])

		i: int = 0
		decay: f64 : 0.95
		for sample in lchan[:SPECTRUMSIZE / 2] {
			tmp := cast(f64)(math.round_f64(cm.abs(sample) * 40.0))
			if prevloop[i] > tmp {
				prevloop[i] = prevloop[i] * decay
			} else {
				prevloop[i] = tmp
			}
			i += 1
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)
		if start_play {
			plot_fft(prevloop[:])
		}
		rl.EndDrawing()
	}

}

main :: proc() {
	raylibmain()
}
