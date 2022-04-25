// Author: John Bush, Sam Guzik
// Created: 04/24/2022
// File: tron_top.v

module tron_top
        (
            BtnL, BtnU, BtnD, BtnR,            // the Left, Up, Down, and the Right buttons BtnL, BtnR,
            BtnC,                              // the center button (this is our reset in most of our designs)
            Sw0,                                // Switch to reset
            Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0, // 8 LEDs
            An3, An2, An1, An0,			       // 4 anodes
            An7, An6, An5, An4,                // another 4 anodes which are not used
            Ca, Cb, Cc, Cd, Ce, Cf, Cg,        // 7 cathodes
            Dp,
        );
    
    /*  INPUTS  */
    // Clocks & Reset I/O
    input   ClkPort;

    // Buttons
    input   BtnL, BtnU, BtnD, BtnR, BtnC;

    // Switches
    input Sw0;

    /*  OUTPUTS */
    // LEDS
    output  Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0;

    // SSD Outputs
    output  Ca, Cb, Cc, Cd, Ce, Cf, Cg,  // 7 cathodes
            Dp;                          // Dotpoint
    output  An3, An2, An1, An0;		    // Anodes [0:3]
    output  An7, An6, An5, An4;          // Anodes [4:7]

    /*  LOCAL SIGNALS   */
    wire        Reset, ClkPort;
    wire        board_clk, sys_clk;
    wire[1:0]   ssdscan_clk;
    reg [26:0]  DIV_CLK;

    BUF BUF2(Reset, Sw0);

    wire Start_Ack_Pulse;
	wire in_AB_Pulse, CEN_Pulse, BtnR_Pulse, BtnU_Pulse;
	wire q_I, q_Driving, q_Collision, q_Done;

    reg [3:0]	SSD;
	wire [3:0]	SSD3, SSD2, SSD1, SSD0;
	reg [7:0]   SSD_CATHODES;

// CLOCK DIVISION

	// The clock division circuitary works like this:
	//
	// ClkPort ---> [BUFGP2] ---> board_clk
	// board_clk ---> [clock dividing counter] ---> DIV_CLK
	// DIV_CLK ---> [constant assignment] ---> sys_clk;
	
	BUFGP BUFGP1 (board_clk, ClkPort); 	

// As the ClkPort signal travels throughout our design,
// it is necessary to provide global routing to this signal. 
// The BUFGPs buffer these input ports and connect them to the global 
// routing resources in the FPGA.

	assign Reset = BtnC;
	
//------------
	// Our clock is too fast (100MHz) for SSD scanning
	// create a series of slower "divided" clocks
	// each successive bit is 1/2 frequency
  always @(posedge board_clk, posedge Reset) 	
    begin							
        if (Reset)
		DIV_CLK <= 0;
        else
		DIV_CLK <= DIV_CLK + 1'b1;
    end
//-------------------	
	// In this design, we run the core design at full 100MHz clock!
	assign	sys_clk = board_clk;
	// assign	sys_clk = DIV_CLK[25];


// *INPUT: SWITCHES & BUTTONS
// !NEED TO UPDATE ACCORDING TO INPUT TYPE (KEYBOARD OR BUTTONS)
	// BtnC is used as both Start and Acknowledge. 
	// To make this possible, we need a single clock producing  circuit.
debouncer #(.N_dc(28)) start_debouncer 
        (.CLK(sys_clk), .RESET(Reset), .PB(BtnC), .DPB( ), 
		.SCEN(Start_Ack_Pulse), .MCEN( ), .CCEN( ));

//=======================================
// State Machine Module

    tron tron1 (.Clk(sys_clk), .SCEN(CEN_Pulse), .Reset(Reset), .Start(Start_Ack_Pulse), .Ack(Start_Ack_Pulse),
                .q_I(q_I), .q_Driving(q_Driving), .q_Collision(q_Collision), .q_Done(q_Done));




//=======================================
// OUTPUT: LEDS
    assign {Ld7, Ld6, Ld5, Ld4} = {q_Done, q_Collision, q_Driving, q_I};
    assign {Ld3, Ld2, Ld1, Ld0} = {0, reset, start, DIV_CLK[25]};

//=======================================
// SSD Control
    localparam
    P1 = 8'b11100001, P2 = 8'b11100010;

    assign SSD7 = P1[7:4];
    assign SSD6 = P1[3:0];
    assign SSD5 = 4'b1111;
    assign SSD4 = p1_score;

    assign SSD3 = P2[7:4];
    assign SSD2 = P2[3:0];
    assign SSD1 = 4'b1111;
    assign SSD0 = p2_score;



    assign ssdscan_clk = DIV_CLK[19:17];
	assign An0	= ~(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 000
	assign An1	= ~(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 001
	assign An2	= ~(~(ssdscan_clk[2]) &&  (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 010
	assign An3	= ~(~(ssdscan_clk[2]) &&  (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 011
	assign An4	= ~( (ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 100
	assign An5	= ~( (ssdscan_clk[2]) && ~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 101
	assign An6	= ~( (ssdscan_clk[2]) &&  (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 110
	assign An7	= ~( (ssdscan_clk[2]) &&  (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 111
	
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3, SSD4, SSD5, SSD6, SSD7)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
				  3'b000: SSD = SSD0;
				  3'b001: SSD = SSD1;
				  3'b010: SSD = SSD2;
				  3'b011: SSD = SSD3;
				  3'b100: SSD = SSD4;
				  3'b101: SSD = SSD5;
				  3'b110: SSD = SSD6;
				  3'b111: SSD = SSD7;
		endcase 
	end

    // Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD) // in this solution file the dot points are made to glow by making Dp = 0
		    //                                                                abc1efg,Dp
			4'b0000: SSD_CATHODES = 8'b00000011; // 0
			4'b0001: SSD_CATHODES = 8'b10011111; // 1
			4'b0010: SSD_CATHODES = 8'b00100101; // 2
			4'b0011: SSD_CATHODES = 8'b00001101; // 3
			4'b0100: SSD_CATHODES = 8'b10011001; // 4
			4'b0101: SSD_CATHODES = 8'b01001001; // 5
			4'b0110: SSD_CATHODES = 8'b01000001; // 6
			4'b0111: SSD_CATHODES = 8'b00011111; // 7
			4'b1000: SSD_CATHODES = 8'b00000001; // 8
			4'b1001: SSD_CATHODES = 8'b00001001; // 9
			4'b1010: SSD_CATHODES = 8'b00010001; // A
			4'b1011: SSD_CATHODES = 8'b11000001; // B
			4'b1100: SSD_CATHODES = 8'b01100011; // C
			4'b1101: SSD_CATHODES = 8'b10000101; // D
			4'b1110: SSD_CATHODES = 8'b00110001; // !P
			4'b1111: SSD_CATHODES = 8'b11111111; // !OFF   
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end