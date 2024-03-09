`timescale 1ns / 1ps
module a51(input clk, rst, keybit, startloading,
           output reg bitout, output reg doneloading);

reg [18:0] lfsr_1;
reg [21:0] lfsr_2;
reg [22:0] lfsr_3;

reg [1:0] state;
reg [6:0] counter;
reg [2:0] phase;

wire hi_1, hi_2, hi_3;
assign hi_1 = lfsr_1[18];
assign hi_2 = lfsr_2[21];
assign hi_3 = lfsr_3[22];

wire mid1, mid2, mid3;
assign mid1 = lfsr_1[8];  
assign mid2 = lfsr_2[10];  
assign mid3 = lfsr_3[10];  

wire maj; 
assign maj = majority(mid1, mid2, mid3);

wire newbit1, newbit2, newbit3;
assign newbit1 = ( lfsr_1[13] ^ lfsr_1[16] ^ lfsr_1[17] ^ lfsr_1[18] );
assign newbit2 = ( lfsr_2[20] ^ lfsr_2[21] ) ;
assign newbit3 = ( lfsr_3[7]  ^ lfsr_3[20] ^ lfsr_3[21] ^ lfsr_3[22] );

parameter IDLE=0, KEYING=1, RUNNING=2;

always @(posedge clk or negedge rst) begin
    if (!rst) begin: resetting
        $display("A5/1 Reset");
        doneloading <=0;
        bitout <=0;
        {lfsr_1, lfsr_2, lfsr_3} <= 64'h0;
        {state, counter, phase} <=0;
        end
    else begin
        case (state)
            IDLE: begin: reset_but_no_key
                if (startloading) begin: startloadingkey
                    $display("Loading key starts at %0d ", $time);
                    state <= KEYING; 
                    {lfsr_1, lfsr_2, lfsr_3} <= 64'h0;
                    phase <=0; counter<=0;
                    end
                end
            KEYING: begin
                case (phase)
                    0: begin: load64andclock
                        clockallwithkey;
                        $display("Loading key bit %0b  %0d at %0d   %0x", keybit, counter, $time, lfsr_1);
                        if (counter == 63) begin
                            counter <= 0; 
                            phase <= phase + 1; 
                            $display(" ");
                        end
                        else counter <= counter + 1; 
                    end
                    1: begin: load22andclock
                        $display("Loading frame bit %0b at %0d %0d   %0x", keybit, counter, $time, lfsr_1);
                        clockallwithkey;
                        if (counter == 21) begin
                            counter <= 0; 
                            phase <= phase + 1; 
                        end
                        else counter <= counter + 1;  
                    end
                    2: begin: clock100
                        majclock;
                        if (counter == 100) begin
                            $display("Done keying, now running %0d\n", $time);
                            state <= RUNNING; 
                        end
                        else counter <= counter + 1; 
                    end
                endcase
            end
            RUNNING: begin
                doneloading <= 1;
                bitout <= hi_1 ^ hi_2 ^ hi_3; 
                majclock;
            end
        endcase
    end
end

function majority(input a,b,c); begin
    case({a,b,c})
        3'b000: majority=0;
        3'b001: majority=0;
        3'b010: majority=0;
        3'b011: majority=1;
        3'b100: majority=0;
        3'b101: majority=1;
        3'b110: majority=1;
        3'b111: majority=1;
    endcase
end
endfunction

task clock1; begin
    lfsr_1 <= ( lfsr_1 << 1 ) | newbit1; 
end
endtask

task clock2; begin
    lfsr_2 <= (lfsr_2 << 1) | newbit2; 
end
endtask

task clock3; begin
    lfsr_3 <= (lfsr_3 << 1) | newbit3; 
end
endtask

task clockall; begin
    clock1;
    clock2; 
    clock3;
end
endtask

task clockallwithkey; begin
    lfsr_1 <= ( lfsr_1 << 1 ) |  newbit1 ^ keybit; 
    lfsr_2 <= ( lfsr_2 << 1 ) |  newbit2 ^ keybit; 
    lfsr_3 <= ( lfsr_3 << 1 ) |  newbit3 ^ keybit; 
end
endtask

task majclock; begin
    if (mid1 == maj) clock1;
    if (mid2 == maj) clock2;
    if (mid3 == maj) clock3;
end
endtask
endmodule
