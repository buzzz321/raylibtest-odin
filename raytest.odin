package raytest

import rl "vendor:raylib"

import "core:c"
import "core:fmt"
import "core:math"
import "core:os"

cb_data : [1024]f32

music_callback ::  proc "c" (bufferData: rawptr, frames: c.uint) {
    data :[^]f32 = cast(^f32)bufferData
 
    for index in 0..<(frames*2){
        cb_data[index] = data[index]
    }
}

raylibmain :: proc()  {
  // Initialization
  //--------------------------------------------------------------------------------------
  screenWidth :i32 : 800
  screenHeight:i32: 450

  rl.InitWindow( screenWidth, screenHeight, "raylib code test")
  defer rl.CloseWindow()

  rl.InitAudioDevice()
  defer rl.CloseAudioDevice()

  music := rl.LoadSound("C64MattGraysDriller.ogg") 
  rl.SetTargetFPS(60)

  rl.PlaySound(music)
  defer rl.StopSound(music)
  
  rl.AttachAudioMixedProcessor(music_callback)
  defer rl.DetachAudioMixedProcessor(music_callback)

  for  !rl.WindowShouldClose() {
    x:i32 = 0
    rl.BeginDrawing()
            rl.ClearBackground(rl.RAYWHITE)
            rl.DrawText("move the ball with arrow keys", 10, 10, 20, rl.DARKGRAY)
            for i in 0..<len(cb_data) / 2 {
              sample := cb_data[i*2+0]
              if sample == 0 {
                continue
              }
              pixel := cast(i32)math.round_f32(sample*450.0) + screenHeight / 2
              rl.DrawPixel(x,pixel,rl.PURPLE)
              //fmt.println(sample, pixel)
              x += 1
            }
      //fmt.println("-----------------------------")
    rl.EndDrawing()
  }

}

main :: proc() {
  raylibmain()
}
