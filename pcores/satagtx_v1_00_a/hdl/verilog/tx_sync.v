///////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /
// \   \   \/     Vendor: Xilinx
//  \   \         Version : 1.6
//  /   /         Application : RocketIO GTX Transceiver Wizard
// /___/   /\     Filename : tx_sync.v
// \   \  /  \
//  \___\/\___\
//
//
// Module TX_SYNC
// Generated by Xilinx RocketIO GTX Transceiver Wizard
// 
// 
// (c) Copyright 2008 - 2009 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of,
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES. 


`timescale 1ns / 1ps
`define DLY #1

module TX_SYNC #
(
    parameter       PLL_DIVSEL_OUT  =   1,
    parameter       TILE_SIM_GTXRESET_SPEEDUP = 1
)
(
    output          TXENPMAPHASEALIGN,
    output          TXPMASETPHASE,
    output          SYNC_DONE,
    input           USER_CLK,
    input           RESET

);

// synthesis attribute X_CORE_INFO of TX_SYNC is "gtxwizard_v1_6, Coregen v11.2";

//*******************************Register Declarations************************

    reg            begin_r;
    reg            phase_align_r;
    reg            ready_r;
    reg   [15:0]   sync_counter_r;
    reg   [9:0]    wait_before_sync_r;
    reg            wait_stable_r;
    
//*******************************Wire Declarations****************************
    
    wire           count_setphase_complete_r;
    wire           count_512_complete_r;
    wire           next_phase_align_c;
    wire           next_ready_c;
    wire           next_wait_stable_c;

//*******************************Main Body of Code****************************

    //________________________________ State machine __________________________    
    // This state machine manages the phase alingment procedure of the GTX.
    // The module is held in reset till the usrclk source is stable.In the 
    // case of buffer bypass where the refclkout is used to clock the usrclks,
    // the usrclk stable indication is given the pll_locked signal.
    // Once the pll_lock is asserted, state machine goes into the wait_stable_r
    // for 512 cycles to allow some time to ensure the pll is stable. After this, 
    // it goes into the phase_align_r state where the phase alignment procedure is 
    // executed. This involves asserting the TXENPHASEALIGN and TXPMASETPHASE for 
    // 8192 clock cycles.
    
    // State registers
    always @(posedge USER_CLK)
        if(RESET)
            {begin_r,wait_stable_r,phase_align_r,ready_r}  <=  `DLY    4'b1000;
        else
        begin
            begin_r                <=  `DLY    1'b0;
            wait_stable_r          <=  `DLY    next_wait_stable_c;
            phase_align_r          <=  `DLY    next_phase_align_c;
            ready_r                <=  `DLY    next_ready_c;
        end

    // Next state logic
    assign  next_wait_stable_c      =   begin_r |
                                        (wait_stable_r & !count_512_complete_r);
                                        
    assign  next_phase_align_c      =   (wait_stable_r & count_512_complete_r) |
                                        (phase_align_r & !count_setphase_complete_r);
                                        

    assign  next_ready_c            =   (phase_align_r & count_setphase_complete_r) |
                                        ready_r;


        //_________ Counter for to wait for pll to be stable before sync __________
    always @(posedge USER_CLK)
    begin
        if (!wait_stable_r)
            wait_before_sync_r <= `DLY  10'b0000000000;
        else
            wait_before_sync_r <= `DLY  wait_before_sync_r + 1'b1;
    end

    assign count_512_complete_r = wait_before_sync_r[9];

    //_______________ Counter for holding SYNC for SYNC_CYCLES ________________
    always @(posedge USER_CLK)
    begin
        if (!phase_align_r)
            sync_counter_r <= `DLY  16'h0000;
        else
            sync_counter_r <= `DLY  sync_counter_r + 1'b1;
    end

generate
if (PLL_DIVSEL_OUT==1)
begin : pll_divsel_out_equals_1 
// 8192 cycles of setphase for output divider of 1
    assign count_setphase_complete_r = TILE_SIM_GTXRESET_SPEEDUP ? sync_counter_r[2] : sync_counter_r[13];
end
else if (PLL_DIVSEL_OUT==2)
begin :pll_divsel_out_equals_2
// 16384 cycles of setphase for output divider of 2
    assign count_setphase_complete_r = TILE_SIM_GTXRESET_SPEEDUP ? sync_counter_r[2] : sync_counter_r[14];
end
else 
begin :pll_divsel_out_equals_4
// 32768 cycles of setphase for output divider of 4
    assign count_setphase_complete_r = TILE_SIM_GTXRESET_SPEEDUP ? sync_counter_r[2] : sync_counter_r[15];
end
endgenerate

    //_______________ Assign the phase align ports into the GTX _______________

    assign TXENPMAPHASEALIGN = !begin_r;
    assign TXPMASETPHASE     = phase_align_r;

    //_______________________ Assign the sync_done port _______________________
    
    assign SYNC_DONE = ready_r;
    
    
endmodule
