/* Test basic c functionality.  */

#define DEBUG 1 
#define DBGFINE 0

// #include "../support/support.h"

#include "string.h"
//#include "pid.h"
#define NOP_REPORT      0x0002      /* Simple report */

/* print long */
void report(unsigned long value)
{
  asm("l.addi\tr3,%0,0": :"r" (value));
  asm("l.nop %0": :"K" (NOP_REPORT));
}

unsigned char enable = 0;
unsigned long period = 655360;
unsigned long command =	10000; // This would be see as command value
unsigned long feedback = 0; // feedback from ADC
unsigned long error = 0; // always equal to REFV - feedback in each loop
unsigned long deadband = 100;	 // error value to be ignored
unsigned long maxerror = 3000;
unsigned long maxerror_i = 6000;
unsigned long maxerror_d =  100;
unsigned long maxcmd_d = 0;  // Since our command(REFV is a constant)
unsigned long maxcmd_dd = 0; //
unsigned long error_i = 0;
unsigned long error_d = 0;
unsigned long prev_error = 0;
unsigned long prev_cmd = 0;
unsigned long limit_state = 0;
unsigned long cmd_d = 0;
unsigned long cmd_dd = 0;
unsigned long bias = 0;
unsigned long pgain = 0;
unsigned long igain = 0;
unsigned long dgain = 0;
unsigned long ff0gain = 0;
unsigned long ff1gain = 0;
unsigned long ff2gain = 0;
unsigned long output = 0;
unsigned long maxoutput = 0;
unsigned long periodfp;
unsigned long periodrecip;
unsigned long tmp1;
unsigned long tmp2;
unsigned long prev_ie = 0;
unsigned char index_enable = 0;
unsigned char saturated = 0 ;
unsigned long saturated_s = 0;
unsigned long saturated_count = 0;
int main()
{	
	while(1) {
		/* read enable bit*/
		/*TODO:enable should be read from register*/
		enable = 1;
		/* read feedback value */
		feedback = 12344;
		tmp1 = command - feedback;
		/* store error to error */
		error = tmp1;
		/* apply error limits */
		/* TODO:error should be configured in init*/
		maxerror = 400000;
		if (maxerror != 0) {
			if (tmp1 > maxerror) {
				tmp1 = maxerror;
			} else if (tmp1 < -maxerror) {
				tmp1 = -maxerror;
			}
		}
		/* apply the deadband */
		/*TODO:deadband would be configurable*/
		deadband = 100;
		if (tmp1 > deadband) {
		tmp1 -= deadband;
		} else if (tmp1 < -deadband) {
		tmp1 += deadband;
		} else {
		tmp1 = 0;
		}
		/* do integrator calcs only if enabled */

		if (enable != 0) {
		/* if output is in limit, don't let integrator wind up */
		if ( ( tmp1 * limit_state ) <= 0 ) {
			/* compute integral term */
			error_i += tmp1 * periodfp;
		}
		/* apply integrator limits */
		/* TODO: maxerror_i should be configured */
		maxerror_i = 0;
		if (maxerror_i != 0) {
			if (error_i > maxerror_i) {
				error_i = maxerror_i;
			} else if (error_i < -maxerror_i) {
				error_i = -maxerror_i;
			}
		}
		} else {
		/* not enabled, reset integrator */
			error_i = 0;
		}
		/* calculate derivative term */
		error_d = (tmp1 - prev_error) * periodrecip;
		prev_error = tmp1;
		/* apply derivative limits */
		/* TODO:maxerror_d should be configured */
		maxerror_d = 0;
		if (maxerror_d != 0) {
		if (error_d > maxerror_d) {
			error_d = maxerror_d;
		} else if (error_d < -maxerror_d) {
			error_d = -maxerror_d;
		}
		}
		/* calculate derivative of command */
		/* save old value for 2nd derivative calc later */
		tmp2 = cmd_d;
		/*TODO:index_enalbe should be read from register*/
		index_enable = 0;
		if(!(prev_ie && !index_enable)) {
			// not falling edge of index_enable: the normal case
			cmd_d =  command - prev_cmd * periodrecip;
		}
		// else: leave cmd_d alone and use last period's.  prev_cmd
		// shouldn't be trusted because index homing has caused us to have
		// a step in position.  Using the previous period's derivative is
		// probably a decent approximation since index search is usually a
		// slow steady speed.

		// save ie for next time
		prev_ie = index_enable;

		prev_cmd = command;
		/* apply derivative limits */
		/* TODO:max_cmd should be configured*/
		maxcmd_d = 0;
		if (maxcmd_d != 0) {
		if (cmd_d > maxcmd_d) {
			cmd_d = maxcmd_d;
		} else if (cmd_d < -maxcmd_d) {
		   cmd_d = -maxcmd_d;
		}
		}
		/* calculate 2nd derivative of command */
		cmd_dd = (cmd_d - tmp2) * periodrecip;
		/* apply 2nd derivative limits */
		/*TODO:maxcmd_dd should be configured*/
		maxcmd_dd = 0;
		if (maxcmd_dd != 0) {
		if (cmd_dd > maxcmd_dd) {
			cmd_dd = maxcmd_dd;
		} else if (cmd_dd < -maxcmd_dd) {
			cmd_dd = -maxcmd_dd;
		}
		}
		/* do output calcs only if enabled */
		if (enable != 0) {
		/* calculate the output value */
		tmp1 =
			bias + pgain * tmp1 + igain * error_i +
			dgain * error_d;
		tmp1 += command * ff0gain + cmd_d * ff1gain +
			cmd_dd * ff2gain;
		/* apply output limits */
		/*TODO:maxoutput should be configured*/
		maxoutput = 0;
		if ( maxoutput != 0) {
			if (tmp1 > maxoutput) {
			tmp1 = maxoutput;
			limit_state = 1;
			} else if (tmp1 < -maxoutput) {
			tmp1 = -maxoutput;
			limit_state = -1;
			} else {
			limit_state = 0;
			}
		}
		} else {
		/* not enabled, force output to zero */
		tmp1 = 0;
		limit_state = 0;
		}
		/* write final output value to output pin */
		output = tmp1;

		/* set 'saturated' outputs */
		if(limit_state) {
			saturated= 1;
			/*saturated_s += period * 1e-9;*/
			if(saturated_count!= 2147483647)
				saturated_count ++;
		} else {
			saturated = 0;
	//        *(pid->saturated_s) = 0;
			saturated_count = 0;
		}
	#if DEBUG
		printf("output  %u\n", output);
	#endif
	}
    /* done */
     return 0;
}



