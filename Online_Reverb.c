/*****************************************************************************
 * Online_Reverb.c
 *****************************************************************************/

// DMA-based in-out program for ADSPBF706

// Author: Patrick Gaydecki

// Date : 02.07.2024



#include "Online_Reverb.h"
#include <stdio.h>
#include <cdefBF706.h>
#include <defBF706.h>
#include "stdfix.h"
#include <sys/platform.h>
#include "adi_initialize.h"
#include <services/int/adi_int.h>




#define BUFFER_SIZE 2 // Size of buffer to transmit
#define OUTPUT_BUFFER_SIZE1 20001  // buffer size = number of samples delay+1 to enable wrap around
#define OUTPUT_BUFFER_SIZE2 30001
#define ROOM 200
#define SAMPLE_RATE 48000

#define	DELAY_LENGTH1  (int)((ROOM * 1) / 1000 * SAMPLE_RATE)
#define DELAY_LENGTH2  (int)((ROOM * 0.85) / 1000 * SAMPLE_RATE)
#define	DELAY_LENGTH3  (int)((ROOM * 0.81) / 1000 * SAMPLE_RATE)
#define	DELAY_LENGTH4  (int)((ROOM * 0.77) / 1000 * SAMPLE_RATE)
#define	DELAY_LENGTH5  (int)((ROOM * 0.69) / 1000 * SAMPLE_RATE)
#define	DELAY_LENGTH6  (int)((ROOM * 0.67) / 1000 * SAMPLE_RATE)





#define All_PASS_DELAY_LENGTH1 (int)(23/ 1000 * SAMPLE_RATE)
#define All_PASS_DELAY_LENGTH2 (int)(37/ 1000 * SAMPLE_RATE)
#define All_PASS_DELAY_LENGTH3 (int)(47/ 1000 * SAMPLE_RATE)



#define PIN2_MASK (1 << 2)  // Mask for Pin 2 (bit 2)




//global variables


long fract XIN[BUFFER_SIZE]; // Input buffer
long fract YOUT[BUFFER_SIZE]; // Output buffer
long fract OUT[6][BUFFER_SIZE];   //output buffers for comb filters
long fract YOUT_1[6][BUFFER_SIZE]; // = stores y(n-1)
long fract XIN_1[BUFFER_SIZE];     // =stores x(n-1)
long fract tempY[BUFFER_SIZE];  //temporary buffer after combfilter before all pass
long fract processedY[BUFFER_SIZE];  // buffer before going into yout after all pass
long fract all_pass_buffer_output_1[All_PASS_DELAY_LENGTH1];  // output buffers for all pass delays
long fract all_pass_buffer_output_2[All_PASS_DELAY_LENGTH2];
long fract all_pass_buffer_output_3[All_PASS_DELAY_LENGTH3];




//array of pointers to store output buffer arrays addresses for comb filter and input output for all pass filter



long fract* all_pass_buffer_output[3] = {all_pass_buffer_output_1, all_pass_buffer_output_2, all_pass_buffer_output_3};


long fract* all_pass_buffer_input[3] = {all_pass_buffer_output_1, all_pass_buffer_output_2, all_pass_buffer_output_3};


int delay_index[6] = {0,0,0,0,0,0};  //comb filter index
int all_pass_index[3] = {0,0,0};     //all pass filter index




//defining A and G variables
long fract G[6] = {0.8,0.8,0.8,0.8,0.8,0.8};
long fract a = 0.6 ;




//defining room size change for polling
int Room_Sizes[3]={300,400,500};

// De_bounce flag
bool room_size_changed = false;




int ALL_PASS_DELAY_LENGTHS[3] = {All_PASS_DELAY_LENGTH1,All_PASS_DELAY_LENGTH2,All_PASS_DELAY_LENGTH3};
int ALL_PASS_INPUT_OUTPUT_BUFFER_SIZES[3] = {All_PASS_DELAY_LENGTH1+1,All_PASS_DELAY_LENGTH2+1,All_PASS_DELAY_LENGTH3+1};
int DELAY_LENGTHS[6] = {DELAY_LENGTH1, DELAY_LENGTH2, DELAY_LENGTH3, DELAY_LENGTH4, DELAY_LENGTH5, DELAY_LENGTH6};
int OUTPUT_BUFFER_SIZES[6] = {DELAY_LENGTH1+1,DELAY_LENGTH2+1,DELAY_LENGTH3+1,DELAY_LENGTH4+1,DELAY_LENGTH5+1,DELAY_LENGTH6+1};


long fract delay_buffer_output_1 [DELAY_LENGTH1];             // Output buffers for delayed samples
long fract delay_buffer_output_2 [DELAY_LENGTH2];
long fract delay_buffer_output_3 [DELAY_LENGTH3];
long fract delay_buffer_output_4 [DELAY_LENGTH4];
long fract delay_buffer_output_5 [DELAY_LENGTH5];
long fract delay_buffer_output_6 [DELAY_LENGTH6];








long fract* delay_buffer_output[6] = {delay_buffer_output_1,delay_buffer_output_2,delay_buffer_output_3,
	    		 	 	 	 	 	 	 	   delay_buffer_output_4,delay_buffer_output_5,delay_buffer_output_6};




// Simple delay function
#pragma optimize_for_speed
void delaying1(long fract* y, long fract* x,long fract* x_old, long fract* y_old,long fract g,long fract* y_buff,int* buff_index, int delay_samples, int out_buffer_size) {
    fract b = 0.96 - g; // Feedback coefficient
    // Insert the input sample into the delay buffer and process the delay effect
    for (int i = 0; i < BUFFER_SIZE; i++) {
        // comb filter difference equation
    	 long fract delayed_sample = x[i] - (g * x_old[i]) + (g*y_old[i]) + (b * y_buff[(*buff_index - delay_samples + out_buffer_size ) % out_buffer_size]);


        // i-1 wrap around
        x_old[i] = x[i];
    	y_old[i]= delayed_sample ;

    	y[i] = delayed_sample;


        // Store the output sample in the delay buffer

        y_buff[*buff_index] = y[i];
    }

    // Update the delay index (circular buffer logic)
    *buff_index = (*buff_index + 1) % out_buffer_size;
}

// all pass filter function difference equation
#pragma optimize_for_speed
void allpass(long fract* y, long fract* x, long fract a, long fract* y_buff,long fract* x_buff, int* buff_index, int delay_samples, int in_out_buffer_size) {

	for (int i = 0; i < BUFFER_SIZE; i++) {


		long fract delayed_output = y_buff[(*buff_index - delay_samples+in_out_buffer_size) % in_out_buffer_size];
		long fract delayed_input = x_buff[(*buff_index - delay_samples + in_out_buffer_size) % in_out_buffer_size];


		//difference equation for all pass filter
		y[i] = a * x[i] + delayed_input - a * delayed_output;

		//store input and output samples in the delay buffers
		 y_buff[*buff_index] = y[i];
		 x_buff[*buff_index] = x[i];

    }

    *buff_index = (*buff_index + 1) % in_out_buffer_size;
}

// all pass sum in series
#pragma optimize_for_speed
void allpassSeries(long fract* y, long fract* x,long fract a,
                   long fract* y_buff, long fract* x_buff, int* buff_index,
                   int delay_samples[], int out_buffer_size[]) {


    // Process the input through each all-pass filter in series
    for (int i = 0; i < 3; i++) {

        // Call the all pass filter function for the current filter
    	allpass(tempY, tempY, a, all_pass_buffer_output[i] ,all_pass_buffer_input[i] ,&all_pass_index[i],
				ALL_PASS_DELAY_LENGTHS[i],ALL_PASS_INPUT_OUTPUT_BUFFER_SIZES[i]);


    }
    // Store the final processed output in YOUT
    for (int i = 0; i < BUFFER_SIZE; i++) {
    	YOUT[i] = tempY[i];
    	//YOUT[i]= (tempY[i]*0lr + (XIN[i]*(1lr-0lr)));


       }

}

//sum delay lines in parallel
#pragma optimize_for_speed
void sumdelays() {

	// Reset YOUT and processedY in a single loop
    for (int i = 0; i < BUFFER_SIZE; i++) {
        YOUT[i] = 0;
        processedY[i] = 0;
        tempY[i] = 0;
    }

    // Process each comb filter and accumulate left and right channels in a single loop
    for (int i = 0; i < 6; i++) {
        // Call comb filter function for each of the 6 filters
        delaying1(OUT[i], XIN, XIN_1, YOUT_1[i], G[i], delay_buffer_output[i],
                  &delay_index[i], DELAY_LENGTHS[i], OUTPUT_BUFFER_SIZES[i]);

        // Accumulate left and right channels into tempY in a single loop
        for (int j = 0; j < BUFFER_SIZE; j++) {
            tempY[j] += (long fract) OUT[i][j];  // Sum both left and right channels into tempY directly
        }
    }

    // Apply all pass filters
    allpassSeries(tempY,tempY , a, all_pass_buffer_output, all_pass_buffer_input,
                  &all_pass_index, ALL_PASS_DELAY_LENGTHS, ALL_PASS_INPUT_OUTPUT_BUFFER_SIZES);


}


void TWI_write(uint16_t, uint8_t);

void codec_configure(void);

void sport_configure(void);

void init_SPORT_DMA(void);

void SPORT0_RX_interrupt_handler(uint32_t iid, void *handlerArg);

void sumdelays(void);


// Subroutine DMA_init initialises the SPORT0 DMA0 and DMA1 in auto-buffer mode, p19–39 and p19–49, BHRM.


void init_SPORT_DMA()

{

*pREG_DMA0_ADDRSTART = YOUT; // points to start of SPORT0_A buffer

*pREG_DMA0_XCNT = BUFFER_SIZE; // no. of words to transmit

*pREG_DMA0_XMOD = 4; // Word length, increment to find next word

*pREG_DMA1_ADDRSTART = XIN; // points to start of SPORT0_B buffer

*pREG_DMA1_XCNT = BUFFER_SIZE; // no. of words to receive

*pREG_DMA1_XMOD = 4; // Word length, increment to find the next word

*pREG_DMA0_CFG = 0x00001221; // SPORT0 TX, FLOW = autobuffer, MSIZE = PSIZE = 4

*pREG_DMA1_CFG = 0x00101223; // SPORT0 RX, DMA interrupt when x count expires

}


// Function SPORT0_RX_interrupt_handler is called when left and right audio samples have been received.

// The inputs are held in XIN[0]and XIN[1] the outputs are sent to YIN[0] and YIN[1].

#pragma optimize_off
void SPORT0_RX_interrupt_handler(uint32_t iid, void *handlerArg)

{


*pREG_DMA1_STAT = 0x1; // Clear interrupt

//YOUT[0]=XIN[0]; // Insert your code between XIN[0] and YOUT[0]
//delaying1(OUT[i],XIN,XIN_1,YOUT_1, g,delay_buffer_output, &delay_index, DELAY_LENGTH);
//YOUT[1]=XIN[1]; // Insert your code between XIN[1] and YOUT[1]

sumdelays();


}


// Function sport_configure initialises the SPORT0. Refer to pages 26-59, 26-67,

// 26-75 and 26-76 of the ADSP-BF70x Blackfin+ Processor Hardware Reference manual.

#pragma optimize_off
void sport_configure()

{

*pREG_PORTC_FER=0x0003F0; // Set up Port C in peripheral mode

*pREG_PORTC_FER_SET=0x0003F0; // Set up Port C in peripheral mode

*pREG_SPORT0_CTL_A=0x2001973; // Set up SPORT0 (A) as TX to codec, 24 bits

*pREG_SPORT0_DIV_A=0x400001; // 64 bits per frame, clock divisor of 1

*pREG_SPORT0_CTL_B=0x0001973; // Set up SPORT0 (B) as RX from codec, 24 bits

*pREG_SPORT0_DIV_B=0x400001; // 64 bits per frame, clock divisor of 1

}


// Function TWI_write is a simple driver for the TWI. Refer to page 24-15 onwards

// of the ADSP-BF70x Blackfin+ Processor Hardware Reference manual.


void TWI_write(uint16_t reg_add, uint8_t reg_data)

{

int n;

reg_add=(reg_add<<8)|(reg_add>>8); // Reverse low order and high order bytes

*pREG_TWI0_CLKDIV=0x3232; // Set duty cycle

*pREG_TWI0_CTL=0x8c; // Set prescale and enable TWI

*pREG_TWI0_MSTRADDR=0x38; // Address of codec

*pREG_TWI0_TXDATA16=reg_add; // Address of register to set, LSB then MSB

*pREG_TWI0_MSTRCTL=0xc1; // Command to send three bytes and enable transmit

for(n=0;n<8000;n++){} // Delay since codec must respond

*pREG_TWI0_TXDATA8=reg_data; // Data to write

for(n=0;n<10000;n++){} // Delay

*pREG_TWI0_ISTAT=0x050; // Clear TXERV interrupt

for(n=0;n<10000;n++){} // Delay

*pREG_TWI0_ISTAT=0x010; // Clear MCOMP interrupt

}


// Function codec_configure initialises the ADAU1761 codec. Refer to the control register

// descriptions, page 51 onwards of the ADAU1761 data sheet.


void codec_configure()

{

TWI_write(0x4000, 0x01); // Enable master clock, disable PLL

TWI_write(0x40F9, 0x7f); // Enable all clocks

TWI_write(0x40Fa, 0x03); // Enable all clocks

TWI_write(0x4015, 0x01); // Set serial port master mode

TWI_write(0x4019, 0x13); // Set ADC to on, both channels

TWI_write(0x401c, 0x21); // Enable left channel mixer

TWI_write(0x401e, 0x41); // Enable right channel mixer

TWI_write(0x4029, 0x03); // Turn on power, both channels

TWI_write(0x402A, 0x03); // Set both DACs on

TWI_write(0x40f2, 0x01); // DAC gets L, R input from serial port

TWI_write(0x40f3, 0x01); // ADC sends L, R input to serial port

TWI_write(0x400a, 0x0b); // Set left line-in gain to 0 dB

TWI_write(0x400c, 0x0b); // Set right line-in gain to 0 dB

TWI_write(0x4023, 0xe7); // Set left headphone volume to 0 dB

TWI_write(0x4024, 0xe7); // Set right headphone volume to 0 dB

TWI_write(0x4017, 0x00); // Set codec default sample rate, 48 kHz

}


int main(void)

{

bool my_audio = true;

codec_configure(); // Enable codec, sport and DMA

sport_configure();

init_SPORT_DMA();

*pREG_PORTC_MUX &= ~(0b11 << 4);


adi_int_InstallHandler(INTR_SPORT0_B_DMA, SPORT0_RX_interrupt_handler, 0, true);



// Configure Port C as input

 /*     *pREG_PORTC_INEN=0xf;

      while(1)

      {

    	  printf("Push_Button is %d\n", (*pREG_PORTC_DATA & PIN2_MASK) ? 1 : 0);


        printf("\n");

      }


*/




*pREG_SEC0_GCTL = 1; // Enable the System Event Controller (SEC)

*pREG_SEC0_CCTL0 = 1; // Enable SEC Core Interface (SCI)

while(my_audio){

	//check_button_and_update_room_size();
}



}





