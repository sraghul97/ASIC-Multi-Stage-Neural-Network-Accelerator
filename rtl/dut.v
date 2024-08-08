module MyDesign (
//---------------------------------------------------------------------------
//Control signals
  input   wire dut_run                    , 
  output  reg dut_busy                   ,
  input   wire reset_b                    ,  
  input   wire clk                        ,
 
//---------------------------------------------------------------------------
//Input SRAM interface
  output reg        input_sram_write_enable    ,
  output reg [11:0] input_sram_write_addresss  ,
  output reg [15:0] input_sram_write_data      ,
  output reg [11:0] input_sram_read_address    ,
  input wire [15:0] input_sram_read_data       ,

//---------------------------------------------------------------------------
//Output SRAM interface
  output reg        output_sram_write_enable    ,
  output reg [11:0] output_sram_write_addresss  ,
  output reg [15:0] output_sram_write_data      ,
  output reg [11:0] output_sram_read_address    ,
  input wire [15:0] output_sram_read_data       ,

//---------------------------------------------------------------------------
//Scratchpad SRAM interface
  output reg        scratchpad_sram_write_enable    ,
  output reg [11:0] scratchpad_sram_write_addresss  ,
  output reg [15:0] scratchpad_sram_write_data      ,
  output reg [11:0] scratchpad_sram_read_address    ,
  input wire [15:0] scratchpad_sram_read_data       ,

//---------------------------------------------------------------------------
//Weights SRAM interface                                                       
  output reg        weights_sram_write_enable    ,
  output reg [11:0] weights_sram_write_addresss  ,
  output reg [15:0] weights_sram_write_data      ,
  output reg [11:0] weights_sram_read_address    ,
  input wire [15:0] weights_sram_read_data       

);

  //Parameters
  localparam s0 = 4'b0000;	//Reset State
  localparam s1 = 4'b0001;	//State 1
  localparam s2 = 4'b0010;	//State 2
  localparam s3 = 4'b0011;	//State 3
  localparam s4 = 4'b0100;	//State 4
  localparam s5 = 4'b0101;	//State 5
  localparam s6 = 4'b0110;	//State 6
  localparam s7 = 4'b0111;	//State 7
  localparam s8 = 4'b1000;	//State 8
  localparam s9 = 4'b1001;	//State 9
  localparam s10 = 4'b1010;	//State 10
  localparam s11 = 4'b1011;	//State 11
  localparam s12 = 4'b1100;	//State 12
  localparam s13 = 4'b1101;	//State 13
  localparam s14 = 4'b1110;	//State 14
  localparam s15 = 4'b1111;	//State 15
  localparam s16 = 5'b10000;//State 16
  localparam s17 = 5'b10001;//State 17
  localparam s18 = 5'b10010;//State 18
  localparam s19 = 5'b10011;//State 19
  localparam s20 = 5'b10100;//State 20
  localparam s21 = 5'b10101;//State 21
  localparam s22 = 5'b10110;//State 22
  localparam s23 = 5'b10111;//State 23
  localparam s24 = 5'b11000;//State 24
  localparam s25 = 5'b11001;//State 25
  localparam s26 = 5'b11010;//State 26
  
  reg [4:0] current_state;
  reg [4:0] next_state;
  reg [6:0] Nvalue;
  reg [15:0] NvalueAddress;
  reg [6:0] NvalueCounter;
  reg [5:0] CurrentRowCounter;
  reg [5:0] CurrentColumnCounter;
  reg OutputSramSlotFlag;
  reg OutputSramSlotControl;
  
  reg [2:0] InputReadAddressel;
  reg [1:0] WeightReadAddressSel;
  reg [1:0] OutputReadAddressSel;
  
 
  reg [15:0] NextInputData;
  reg signed [7:0] W1,W2,W3,W4,W5,W6,W7,W8,W9;
  reg signed [7:0] R1a,R1b,R2a,R2b,R3a,R3b,R4a,R4b,R5a,R5b,R6a,R6b,R7a,R7b,R8a,R8b;  
  reg signed [19:0] MAC1,MAC2,MAC3,MAC4;
  reg signed [7:0] ResMAC12,ResMAC34,MaxPoolResult;
  
  
 always@(posedge clk)
  begin
	if (InputReadAddressel == 3'b000)
		input_sram_read_address <= 0;
	else if (InputReadAddressel == 3'b001)
		input_sram_read_address <= input_sram_read_address +1;
	else if (InputReadAddressel == 3'b010)
		input_sram_read_address <= input_sram_read_address ;
	else if (InputReadAddressel == 3'b011)
		input_sram_read_address <=(NvalueAddress+1)+((Nvalue>>1) * (2*CurrentRowCounter)) + CurrentColumnCounter;			//Row 1 of 4x4 Sub Matrix
	else if (InputReadAddressel == 3'b100)
		input_sram_read_address <= (NvalueAddress+1)+((Nvalue>>1) * ((2*CurrentRowCounter)+1)) + CurrentColumnCounter;		//Row 2 of 4x4 Sub MAtrix
	else if (InputReadAddressel == 3'b101)
		input_sram_read_address <= (NvalueAddress+1)+((Nvalue>>1) * ((2*CurrentRowCounter)+2)) + CurrentColumnCounter;		//Row 3 of 4x4 Sub MAtrix
	else if (InputReadAddressel == 3'b110)
		input_sram_read_address <= (NvalueAddress+1)+((Nvalue>>1) * ((2*CurrentRowCounter)+3)) + CurrentColumnCounter;		//Row 4 of 4x4 Sub MAtrix
	else if (InputReadAddressel == 3'b111)
		input_sram_read_address <= NvalueAddress;
		
  
	if (OutputReadAddressSel == 2'b00)
		output_sram_read_address <= 0;
	else if (OutputReadAddressSel == 2'b01)
		output_sram_read_address <= output_sram_read_address +1;
	else if (OutputReadAddressSel == 2'b10)
		output_sram_read_address <= output_sram_read_address;
  
  
	if (WeightReadAddressSel == 2'b00)
		weights_sram_read_address <= 0 ;
	else if (WeightReadAddressSel == 2'b01)
		weights_sram_read_address <= weights_sram_read_address +1;
	else if (WeightReadAddressSel == 2'b10)
		weights_sram_read_address <= weights_sram_read_address;
  end
  
  
  always@(posedge clk)
  begin
  if (reset_b)
  current_state <= next_state;
  else
  current_state <= s0;
  end
 
  always @ (*)
  begin
  casex (current_state)
  s0:
	begin//W1,W2,N
		InputReadAddressel = 3'b000;
		OutputReadAddressSel = 2'b00;
		WeightReadAddressSel = 2'b00;
		OutputSramSlotControl = 0;
		if (dut_run == 1'b1)
			next_state = s1;
		else
			next_state = s0;
	end
  
  s1://W3,W4,R1a,R1b
	begin
		InputReadAddressel = 3'b011;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b01;
		OutputSramSlotControl = 0;
		next_state = s2;
	end
	
  s2://W5,W6,R2a,R2b
	begin
		InputReadAddressel = 3'b001;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b01;
		OutputSramSlotControl = 0;
		next_state = s3;
	end
 	
  s3://W7,W8,R3a,R3b
	begin
		InputReadAddressel = 3'b100;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b01;
		OutputSramSlotControl = 0;
		next_state = s4;
	end 

  s4://W9,R4a,R4b
	begin
		InputReadAddressel = 3'b001;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b01;
		OutputSramSlotControl = 0;
		next_state = s5;
	end 	
  
  s5://R5a,R5b
	begin
		InputReadAddressel = 3'b101;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b00;
		OutputSramSlotControl = 0;
		next_state = s6;
	end

  s6://R6a,R6b
	begin
		InputReadAddressel = 3'b001;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b00;
		OutputSramSlotControl = 0;
		next_state = s7;
	end
	
  s7://R7a,R7b
	begin
		InputReadAddressel = 3'b110;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b00;
		OutputSramSlotControl = 0;
		next_state = s8;
	end

  s8://R8a,R8b
	begin
		InputReadAddressel = 3'b001;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b00;
		OutputSramSlotControl = 0;
		next_state = s9;
	end
	
  s9://Wait Cycle to Complete MACs. NextInputData from Input SRAM
	begin
		InputReadAddressel = 3'b001;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b00;
		OutputSramSlotControl = 0;
		next_state = s10;
	end

  s10://Wait Cycle to Complete MACs
	begin
		InputReadAddressel = 3'b010;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b00;
		OutputSramSlotControl = 0;
		next_state = s11;
	end
	
  s11://Wait Cycle to Complete MACs. ReLu for MAC 1 and 2
	begin
		InputReadAddressel = 3'b010;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b00;
		//input_sram_read_address = (NvalueAddress+1)+((Nvalue>>1) * ((2*CurrentRowCounter)+2)) + CurrentColumnCounter;
		OutputSramSlotControl = 0;
		next_state = s12;
	end

  s12://Wait Cycle to Complete MACs. ReLu for MAC 3 and 4
	begin
		InputReadAddressel = 3'b010;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b00;
		OutputSramSlotControl = 0;
		next_state = s13;
	end
	
  s13://Max Pooling
	begin
		InputReadAddressel = 3'b010;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b00;
		//input_sram_read_address = input_sram_read_address + 1;
		OutputSramSlotControl = 0;
		if (OutputSramSlotFlag == 1)
		begin
			if ((~((CurrentColumnCounter == 0) & (CurrentRowCounter == 0))) || (~(NvalueAddress == 0)))
			begin
				//output_sram_read_address = output_sram_read_address + 1 ;
				OutputReadAddressSel = 2'b01;
			end
		end
		next_state = s14;
	end

  s14://Update Output SRAM
	begin
		InputReadAddressel = 3'b010;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b00;
		OutputSramSlotControl = 0;
		
		next_state = s15;
	end
	
	s15:
	begin
		InputReadAddressel = 3'b010;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b10;
		//input_sram_read_address = (NvalueAddress+1)+((Nvalue>>1) * ((2*CurrentRowCounter)+3)) + CurrentColumnCounter;
		OutputSramSlotControl = 0;
		next_state = s16;
	end

  s16:
	begin
		InputReadAddressel = 3'b010;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b10;
		OutputSramSlotControl = 0;
		next_state = s17;
	end
	
 s17:
	begin
		InputReadAddressel = 3'b010;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b10;
		//input_sram_read_address = input_sram_read_address + 1;
		OutputSramSlotControl = 0;
		if (NextInputData == 16'hFFFF)
			next_state = s0;
		else
			next_state = s18;
	end

  s18:
	begin
		InputReadAddressel = 3'b010;
		OutputReadAddressSel = 2'b10;
		WeightReadAddressSel = 2'b10;
		OutputSramSlotControl = 0;
		if (~((CurrentColumnCounter == 0) & (CurrentRowCounter == 0)))
		begin
			//input_sram_read_address = NvalueAddress;
			InputReadAddressel = 3'b111;
		end
		else
			OutputSramSlotControl = 1;		
		next_state = s1;
	end
	
	default:
	begin
		InputReadAddressel = 3'b000;
		OutputReadAddressSel = 2'b00;
		WeightReadAddressSel = 2'b00;
		//output_sram_read_address = 0;
		//input_sram_read_address = 0;
		OutputSramSlotControl = 0;
		next_state = s0;
	end
	endcase
end	



always@ (posedge clk)
begin
	if (current_state == s0)
	begin
		dut_busy <= 0;
		MAC1 <=0;
		MAC2 <= 0;
		MAC3 <= 0;
		MAC4 <= 0;
		ResMAC12 =0;
		ResMAC34 =0;
		MaxPoolResult = 0;
		NextInputData <= 0;
		CurrentRowCounter = 0;
		CurrentColumnCounter = 0;
		input_sram_write_enable <= 1'b0;
		weights_sram_write_enable <= 1'b0;
		output_sram_write_enable <=1'b0;
		OutputSramSlotFlag <= 1;
		//Nvalue <=0;
		NvalueAddress <= input_sram_read_address;
		//Nvalue <= input_sram_read_data[5:0];
		//NvalueCounter <= (input_sram_read_data[5:0] - 2) >> 1;
		Nvalue <= input_sram_read_data[6:0];
		NvalueCounter <= (input_sram_read_data[6:0] - 2) >> 1;
	end
	else if (current_state == s1)
	begin
		dut_busy <= 1;
		output_sram_write_enable <=0;
	
	end
	else if (current_state == s2)
	begin
		W1 <= weights_sram_read_data[15:8];
		W2 <= weights_sram_read_data[7:0];
			
	end
	else if (current_state == s3)
	begin
		W3 <= weights_sram_read_data[15:8];
		W4 <= weights_sram_read_data[7:0];
		R1a <= input_sram_read_data[15:8];
		R1b <= input_sram_read_data[7:0];
	end
	else if (current_state == s4)
	begin
		W5 <= weights_sram_read_data[15:8];
		W6 <= weights_sram_read_data[7:0];
		R2a <= input_sram_read_data[15:8];
		R2b <= input_sram_read_data[7:0];	
		
		MAC1 <= (R1a * W1) + MAC1;
		MAC2 <= (R1b * W1) + MAC2;
	end
	else if (current_state == s5)
	begin
		W7 <= weights_sram_read_data[15:8];
		W8 <= weights_sram_read_data[7:0];
		R3a <= input_sram_read_data[15:8];
		R3b <= input_sram_read_data[7:0];
	
		MAC1 <= (R1b * W2) + MAC1;
		MAC2 <= (R2a * W2) + MAC2;
	end
	else if (current_state == s6)
	begin
		W9 <= weights_sram_read_data[15:8];
		R4a <= input_sram_read_data[15:8];
		R4b <= input_sram_read_data[7:0];
		
		MAC1 <= (R2a * W3) + MAC1;
		MAC2 <= (R2b * W3) + MAC2;	
		MAC3 <= (R3a * W1)+ MAC3;
		MAC4 <= (R3b * W1)+ MAC4;
	end
	else if (current_state == s7)
	begin
		R5a <= input_sram_read_data[15:8];
		R5b <= input_sram_read_data[7:0];
		
		MAC1 <= (R3a * W4)+ MAC1;
		MAC2 <= (R3b * W4)+ MAC2;
		MAC3 <= (R3b * W2) + MAC3;	
		MAC4 <= (R4a * W2)+ MAC4;
	end
	else if (current_state == s8)
	begin
		R6a <= input_sram_read_data[15:8];
		R6b <= input_sram_read_data[7:0];
		
		MAC1 <= (R3b * W5) + MAC1;
		MAC2 <= (R4a * W5)+ MAC2;
		MAC3 <= (R4a * W3)+ MAC3;
		MAC4 <= (R4b * W3) + MAC4;
	end
	else if (current_state == s9)
	begin
		R7a <= input_sram_read_data[15:8];
		R7b <= input_sram_read_data[7:0];
		
		MAC1 <= (R4a * W6)+ MAC1;
		MAC2 <= (R4b * W6) + MAC2;
		MAC3 <= (R5a * W4)+ MAC3;
		MAC4 <= (R5b * W4)+ MAC4;

	end
	else if (current_state == s10)
	begin
		R8a <= input_sram_read_data[15:8];
		R8b <= input_sram_read_data[7:0];
		
		MAC1 <= (R5a * W7)+ MAC1;
		MAC2 <= (R5b * W7)+ MAC2;
		MAC3 <= (R5b * W5) + MAC3;
		MAC4 <= (R6a * W5)+ MAC4;	
	end
	else if (current_state == s11)
	begin
		NextInputData <= input_sram_read_data;
	
		MAC1 <= (R5b * W8) + MAC1;
		MAC2 <= (R6a * W8)+ MAC2;
		MAC3 <= (R6a * W6)+ MAC3;
		MAC4 <= (R6b * W6) + MAC4;
	end
	else if (current_state == s12)
	begin
		MAC1 <= (R6a * W9)+ MAC1;
		MAC2 <= (R6b * W9) + MAC2;
		MAC3 <= (R7a * W7)+ MAC3;
		MAC4 <= (R7b * W7)+ MAC4;		
	end
	else if (current_state == s13)		//ReLu Function for MAC1 and MAC2
	begin
		if (MAC1[19] == 1)
			MAC1 <= 1'b0;
		else if (MAC1 > 7'b1111111)
			MAC1 <= 7'b1111111;
			
		if (MAC2[19] == 1)
			MAC2 <= 1'b0;
		else if (MAC2 > 7'b1111111)
			MAC2 <= 7'b1111111;
		
		MAC3 <= (R7b * W8)+ MAC3;
		MAC4 <= (R8a * W8)+ MAC4;
				
	end
	else if (current_state == s14)
	begin
		MAC3 <= (R8a * W9)+ MAC3;
		MAC4 <= (R8b * W9) + MAC4;	
	end
	else if (current_state == s15)		//ReLu Function for MAC3 and MAC4
	begin
		if (MAC3[19] == 1)
			MAC3 <= 1'b0;
		else if (MAC3 > 7'b1111111)
			MAC3 <= 7'b1111111;
			
		if (MAC4[19] == 1)
			MAC4 <= 1'b0;
		else if (MAC4 > 7'b1111111)
			MAC4 <= 7'b1111111;
		output_sram_write_data <=output_sram_read_data;
		OutputSramSlotFlag <= ~OutputSramSlotFlag;
		CurrentColumnCounter = CurrentColumnCounter +1;		//Move 4x4 Input sub matrix 
	end
	else if (current_state == s16)		//MAX Pooling
	begin
		if (MAC1 > MAC2)
			ResMAC12 = MAC1[7:0];
		else
			ResMAC12 = MAC2[7:0];
		
		if (MAC3 > MAC4)
			ResMAC34 = MAC3[7:0];
		else
			ResMAC34 = MAC4[7:0];
			
		if (ResMAC12 > ResMAC34)
			MaxPoolResult = ResMAC12;
		else
			MaxPoolResult = ResMAC34;
		
		if (CurrentColumnCounter == NvalueCounter)			//Check if 4x4 Input sub matrix reached end of Input Matrix Column, so as to move down left most
		begin
			CurrentRowCounter = CurrentRowCounter + 1;
			CurrentColumnCounter = 0;
		end
	end
	else if (current_state == s17)			//Write to Output SRAM
	begin
		output_sram_write_addresss = output_sram_read_address;
		if (OutputSramSlotFlag)
			output_sram_write_data <= {output_sram_read_data[15:8],MaxPoolResult};
		else
			output_sram_write_data <= {MaxPoolResult,8'b00000000};
		output_sram_write_enable <=1;
		
		MAC1 <=0;
		MAC2 <= 0;
		MAC3 <= 0;
		MAC4 <= 0;
		ResMAC12 =0;
		ResMAC34 =0;
		MaxPoolResult = 0;	
		
		if (CurrentRowCounter == NvalueCounter)		//Check if 4x4 Input sub matrix reached end of Input Marix
		begin
			CurrentRowCounter = 0;
			CurrentColumnCounter =0;	
			NvalueAddress <= input_sram_read_address;
			Nvalue <= input_sram_read_data[6:0];
			NvalueCounter <= (input_sram_read_data[6:0] - 2) >> 1;
		end				
	end
	else if (current_state == s18)
	begin
		if (OutputSramSlotControl)
			OutputSramSlotFlag <=1;
	end
end

endmodule

