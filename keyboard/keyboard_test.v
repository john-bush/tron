module keyboard_top (
        MemOE, MemWR, RamCS, QuadSpiFlashCS,
        ClkPort,                           // the 100 MHz incoming clock signal
		Sw0,
        An3, An2, An1, An0,			       // 4 anodes
		An7, An6, An5, An4,                // another 4 anodes which are not used
		Ca, Cb, Cc, Cd, Ce, Cf, Cg,        // 7 cathodes
		Dp                                 // Dot Point Cathode on SSDs
	  );

    input ClkPort;
    input Sw0;
    output 	MemOE, MemWR, RamCS, QuadSpiFlashCS;
    // SSD Outputs
	output 	Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp;
	output 	An0, An1, An2, An3;	
	output 	An4, An5, An6, An7;	

/*  LOCAL SIGNALS */
	wire ClkPort, board_clk;
	reg start;
	wire reset;
	BUF BUF2(reset, Sw0);
	reg [26:0]	DIV_CLK;
    

	wire[7:0] keyboard_input;
	reg[7:0] keyboard_buffer;
	// Keyboard SM Transition Codes:
	//	start and ack mapped to space (= 29)
	//	reset mapped to escape (= 76)
	wire read;
	wire scan_ready;
	wire CLOCK_50;
	assign CLOCK_50 = DIV_CLK[0];
	
    assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;

	pulse_gen pulser(
		.pulse_out(read),
		.trigger_in(scan_ready),
		.clk(CLOCK_50)
	);
	
	keyboard kb(
		.keyboard_clk(PS2_CLK),
		.keyboard_data(PS2_DAT),
		.clock50(CLOCK_50),
		.reset(reset),
		.read(read),
		.scan_ready(scan_ready),
		.scan_code(keyboard_input)
	);
	
	/* Handle keyboard input */
	always @(posedge scan_ready)
        begin
            keyboard_buffer <= keyboard_input;
        end
    


    BUF BUF1 (board_clk, ClkPort);
	reg [24:0]	DIV_CLK;
	initial DIV_CLK = 0;
	// Generate the DIV_CLK signal
	always @ (posedge board_clk)  
	begin : CLOCK_DIVIDER
		if (reset)
			DIV_CLK <= 0;
		else
			DIV_CLK <= DIV_CLK + 1'b1;
	end

// SSD (Seven Segment Display)
	wire [2:0] 	ssdscan_clk;
    reg [3:0]	SSD;
	wire [7:0]	SSD7, SSD6, SSD5, SSD4, SSD3, SSD2, SSD1, SSD0;
	reg [7:0]  	SSD_CATHODES;
	//SSDs show Ain and Bin in initial state, A and B in subtract state, and GCD and i_count in multiply and done states.
	
	
	assign SSD3 = keyboard_buffer[7:4];
	assign SSD2 = keyboard_buffer[3:0];
    assign SSD1 = 4'b0001;
    assign SSD0 = 4'b0010;


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

	
	// and finally convert SSD_num to ssd
	// We convert the output of our 4-bit 4x1 mux

	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};

	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD) // in this solution file the dot points are made to glow by making Dp = 0
		    //                                                                abcdefg,Dp
			// ****** TODO  in Part 2 ******
			// Revise the code below so that the dot points do not glow for your design.
			4'b0001: SSD_CATHODES = 8'b10011111; // 1
			4'b0000: SSD_CATHODES = 8'b00000011; // 0
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
			4'b1110: SSD_CATHODES = 8'b01100001; // E
			4'b1111: SSD_CATHODES = 8'b01110001; // F    
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end	
	
endmodule