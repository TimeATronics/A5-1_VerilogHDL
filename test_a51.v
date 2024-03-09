`timescale 1ns / 1ps
module test_a51();
reg clk, rst, keybit, startloading;
wire bitout;
wire doneloading;
reg [0:7] key [7:0]; 
reg [22:0] frame; 
a51 CKT1 (clk, rst, keybit, startloading, bitout, doneloading);
integer i,j;
initial begin #5
    key[0]= 8'h12;
    key[1]= 8'h23;
    key[2]= 8'h45;
    key[3]= 8'h67;
    key[4]= 8'h89;
    key[5]= 8'hAB;
    key[6]= 8'hCD; 
    key[7]= 8'hEF;
    frame <= 22'h134;
    clk <= 0; rst <= 1; startloading <= 0;
    keybit <= 0;   
    #10 rst <= 0; #10 rst <= 1; #100
    startloading <= 1; $display("Starting to key %0d", $time); 
    for (i = 0; i < 8; i = i + 1) begin
        for (j = 0; j < 8; j = j + 1) begin
            #10 startloading <= 0; 
            keybit <= key[i] >> j;
            end
    end
    for (i = 0; i < 22; i = i + 1) begin
        #10 keybit <= frame[i];
    end
    wait(doneloading); $display("Done keying %0d", $time);
    $write("\nBits out: \n"); 
    repeat (32) #10 $write("%b", bitout);
    $display("\nKnown value = \n%b", 32'h534EAA58);    
    #1000 $display("\nSim done."); $finish;
end
always @(clk) #5 clk <= ~clk;
endmodule
