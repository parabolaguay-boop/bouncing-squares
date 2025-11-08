/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_bouncing_squares(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;
  wire sound;


  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  reg[8:0] width = 80;

  reg moving_y_state [3:0] ;
  reg moving_x_state [3:0];
  reg signed [9:0] y_pos [3:0];
  reg signed [10:0] x_pos [3:0];

  initial begin
    moving_x_state[0] = 1'b0;
    moving_x_state[1] = 1'b1;
    moving_x_state[2] = 1'b1;
    moving_x_state[3] = 1'b1;
    moving_x_state[4] = 1'b0;
    moving_y_state[0] = 1'b1;
    moving_y_state[1] = 1'b0;
    moving_y_state[2] = 1'b1;
    moving_y_state[3] = 1'b1;
    moving_y_state[4] = 1'b1;

    y_pos[0] = 300;
    y_pos[1] = 300;
    y_pos[2] = 400;
    y_pos[3] = 200;
    y_pos[4] = 50;
    x_pos[0] = 0;
    x_pos[1] = 120;
    x_pos[2] = 100;
    x_pos[3] = 40;
    x_pos[4] = 40;
  end

  wire signed [9:0] y3width = y_pos[3] + width;
  wire signed [10:0] x3width = x_pos[3] + width;

  assign G = video_active && 
    (pix_y >= y_pos[0] && pix_y < y_pos[0] + width) &&   
    (pix_x >= x_pos[0] && pix_x < x_pos[0] + width) ||
    (pix_y >= y_pos[3] && pix_y < y3width) &&  
    (pix_x >= x_pos[3] && pix_x < x3width)
     ? 2'b11: 2'b00;         
  assign R = video_active && (pix_y >= y_pos[1] && pix_y < y_pos[1] + width) &&   
    (pix_x >= x_pos[1] && pix_x < x_pos[1] + width) ||
    (pix_y >= y_pos[3] && pix_y < y3width) &&   
    (pix_x >= x_pos[3] && pix_x < x3width)        
    ? 2'b11 : 2'b00;
  assign B = video_active && (pix_y >= y_pos[2] && pix_y < y_pos[2] + width) &&  
    (pix_x >= x_pos[2] && pix_x < x_pos[2] + width)        
    ? 2'b11 : 2'b00;


  integer i;
  always @(posedge vsync) begin
    width <= (x_pos[0] + y_pos[1]) >> 2;
    for (i = 0; i < 5; i = i + 1) begin
      if (moving_y_state[i]) begin
        y_pos[i] <= y_pos[i] + 6 + i;
      end
      else begin
        y_pos[i] <= y_pos[i] - 10 - i;
      end
      if (y_pos[i] <= 0) begin
        moving_y_state[i] <= 1'b1;
      end
      else if (y_pos[i] >= 480-width) begin
        moving_y_state[i] <= 1'b0;
      end
    end
    for (i = 0; i < 5; i = i + 1) begin
      if (moving_x_state[i]) begin
        x_pos[i] <= x_pos[i] + 7 + i;
      end 
      else begin
        x_pos[i] <= x_pos[i] - 3 - i;
      end
      if (x_pos[i] <= 0) begin
        moving_x_state[i] <= 1'b1;
      end
      else if (x_pos[i] >= 640-width) begin
        moving_x_state[i] <= 1'b0;
      end
    end
  end
  
endmodule