`timescale 1ns / 1ps

module tron (
        Clk, SCEN, Reset, Start, Ack,
        q_I, q_Straight, q_Turn, q_Collision,
        BtnL, BtnU, BtnD, BtnR,            // the Left, Up, Down, and the Right buttons BtnL, BtnR,
		BtnC,                              // the center button (this is our reset in most of our designs)
		Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0, // 8 LEDs
		An3, An2, An1, An0,			       // 4 anodes
		An7, An6, An5, An4,                // another 4 anodes which are not used
		Ca, Cb, Cc, Cd, Ce, Cf, Cg,        // 7 cathodes
		Dp,                                 // Dot Point Cathode on SSDs
        hSync, vSync, vgaR, vgaG, vgaB
	);

    input   Clk, SCEN, Reset, Start, Ack;

    output hSync, vSync,
	output [3:0] vgaR, vgaG, vgaB,

    // LEDs
	output 	Ld0, Ld1, Ld2, Ld3, Ld4, Ld5, Ld6, Ld7;
	// SSD Outputs
	output 	Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp;
	output 	An0, An1, An2, An3;	
	output 	An4, An5, An6, An7;	

    output q_I, q_Straight, q_Turn, q_Collision;
    reg[3:0] state;
    assign {q_I, q_Straight, q_Turn, q_Collision} = state;

    localparam 	
	I = 4'b0001, STRAIGHT = 4'b0010, TURN = 4'b0100, COLLISION = 4'b1000, UNK = 4'bXXXX;

    wire[7:0] keyboard_input;
	reg[7:0] keyboard_buffer;

    // keyboard input handler
    always @(posedge /*something*/)
    begin 
        keyboard_buffer <= keyboard_input;
        start <= 1'b0;

        if(q_I)
        begin
            p1_dir = RIGHT;
            p2_dir = LEFT;
        end

        case (keyboard_buffer)
            // P1 WASD Key Inputs:
            16'h1D://W
				p1_dir <= UP;
			16'h1B://S
				p1_dir <= DOWN;
			16'h1C://A
				p1_dir <= LEFT;
			16'h23://D
				p1_dir <= RIGHT;
			
            // P2 Arrow Key Inputs:
            16'h75://UP
				p2_dir <= UP;
			16'h72://DOWN
				p2_dir <= DOWN;
			16'h6B://LEFT
				p2_dir <= LEFT;
			16'h74://RIGHT
				p2_dir <= RIGHT;
			16'h29://space
				start <= 1'b1;
        endcase
    end

    
    reg [1:0] p1_dir;
	reg [1:0] p2_dir;

    reg [3:0] p1_score;
    reg [3:0] p2_score;

    // Local variables to loop through the grid during processing
	integer i, j;

	// Game State Machine
	always @(posedge DIV_CLK[23])
    begin
        if (reset)
        begin
            state <= I;
            p1_score = 0;
            p2_score = 0;
        end

        else
            case (state)
                I:
                begin
                    if (start)
                        state <= DRIVING;
                    
                    // reset player start positions

                    // reset boolean path array
                end

                DRIVING:
                begin
                    if (collision)
                        begin
                            state <= COLLISION;
                            if (p1_crash)
                                p2_score <= p2_score + 1;
                            if (p2_crash)
                                p1_score <= p1_score + 1;
                        end

                    else
                        begin
                            // mark current p1, p2 positions as visited

                            case (p1_dir)
                                // update p1_position
                                UP:
                                    p1_y <= p1_y + 1;
                                DOWN:
                                    p1_y <= p1_y - 1;
                                LEFT:
                                    p1_x <= p1_x - 1;
                                RIGHT:
                                    p1_x <= p1_x + 1;
                            endcase

                            case (p2_dir)
                                // update p2_position
                                UP:
                                    p2_y <= p2_y + 1;
                                DOWN:
                                    p2_y <= p2_y - 1;
                                LEFT:
                                    p2_x <= p2_x - 1;
                                RIGHT:
                                    p2_x <= p2_x + 1;
                            endcase
                        end

                end

                COLLISION:
                begin
                    if (start) state <= DONE;
                end

                DONE:
                begin
                    if (start) state <= I;
                end



    end
