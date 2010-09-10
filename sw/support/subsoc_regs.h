#ifndef __subsoc_regs_h__
#define __subsoc_regs_h__

/**
 * BASE Address Mapping: refer to APP_ADDR_* at subsoc_defines.v
 *******************************************************************************
 * @registers for SFIFO (SYNC FIFO Interface)
 *******************************************************************************
 * SFIFO_BASE           0x9D000000
 *******************************************************************************
 * REG_NAME             ADDR_OFFSET   ACCESS  DESCRIPTION
 * SFIFO_BP_TICK        0x0000.0      Rrst    Base period tick signal. It's set
 *                                            by external BP generator at
 *                                            every base period tick(0.66ms);
 *                                            reset by SW after reading
 *                                            this register when its value
 *                                            is 1.
 * SFIFO_CTRL   [31: 0] 0x0004
 *    SFIFO_EMPTY       0x0004.0      R       set to 1 if SFIFO is empty
 *    ?removed? SSIF_EN           0x0004.1      R       Servo/Stepper Interface Enable
 *
 * SFIFO_DI             0x0008        R       SFIFO data input
 *                        ~                   - read this address to fetch a word from SFIFO
 *                      0x0009                - read get blocked if SFIFO is empty
 *    NAME        OP_CODE[15:14]  OPERAND[13:0]   Description
 *    SYNC_JNT    2'b00           {DIR_W, POS_W}  DIR_W[13]:    Direction, (positive(1), negative(0))
 *                                                POS_W[12:0]:  Relative Angle Distance (0 ~ 8191)
 *    NAME        OP_CODE[15:12]  OPERAND[11:0]   Description
 *    SYNC_DOUT   4'b0100         {ID, VAL}       ID[11:6]: Output PIN ID
 *                                                VAL[0]:   ON(1), OFF(0)
 *    SYNC_DIN    4'b0101         {ID, TYPE}      ID[11:6]: Input PIN ID
 *                                                TYPE[1:0]: LOW(00), HIGH(01), FALL(10), RISE(11)
 *    SYNC_AIO    4'b011.         ... TODO
 *    NUM_JNT                     ... TODO    Number of joints of this machine
 *    Write 2nd byte of SYNC_CMD[] will push it into SFIFO. 
 *    The WB_WRITE got stalled if SFIFO is full. 
 *  
 *  pseudo code:
 *    + subsoc fetch commands from SFIFO
 *    + subsoc process SYNC commands
 *    + subsoc process SYNC_JNT commands
 *    + subsoc do position/velocity compensation (PID, etc...)
 *    + subsoc wait for SFIFO_BP_TICK
 *    + subsoc write commands to SSIF
 *
 *******************************************************************************
 * @REGISTERS FOR SSIF (Servo/Stepper InterFace)
 *******************************************************************************
 * SSIF_BASE            0X0080
 * BP: Base Period register updating
 *******************************************************************************
 * REG_NAME             ADDR_OFFSET   ACCESS  DESCRIPTION
 * SSIF_PULSE_POS       0X0000        R(BP)   (0X00 ~ 0X0F) JNT_0 ~ JNT_3, PULSE-Position to Driver
 * SSIF_ENC_POS         0X0010        R(BP)   (0X10 ~ 0X1F) JNT_0 ~ JNT_3, ENCODER-POSITION FROM SERVO DRIVER
 * SSIF_SWITCH_IN       0X0020        R(BP)   (0X20 ~ 0X21) 16 INPUT SWITCHES FOR HOME, CCWL, AND CWL
 * RESERVED             0x0022~0x002A
 * SSIF_LOAD_POS        0x002B        W       (0x2B) load SWITCH & INDEX with PULSE(stepper) or ENC(servo) 
 *                                                   positions for homing
 *                                            [i] set to 1 by SW to load SWITCH and INDEX position
 *                                                reset to 0 by HW one cycle after resetting
 * SSIF_RST_POS         0x002C        W       (0x2C) reset PULSE/ENC/SWITCH/INDEX positions for homing
 *                                            [i] set to 1 by SW to clear positions 
 *                                                reset to 0 by HW one cycle after resetting
 * SSIF_SWITCH_EN[3:0]  0x002D        RW(BP)  (0x2D) update and lock SWITCH_POS when home switch is toggled
 *                                            [i] set to 1 by SW to update SWITCH_POS[i]
 *                                                reset to 0 by HW when home switch of JNT[i] is toggled
 * SSIF_INDEX_EN[3:0]   0x002E        RW(BP)  (0x2E) update and lock INDEX_POS when motor index switch is toggled
 *                                            [i] set to 1 by SW to update INDEX_POS[i]
 *                                                reset to 0 by SW after detecting INDEX_LOCK[i]
 * SSIF_INDEX_LOCK[3:0] 0x002F        R(BP)   (0x2F) lock INDEX_POS at posedge of motor index switch
 *                                            [i] set to 1 at posedge of motor index switch 
 *                                                update INDEX_POS when ((INDEX_LOCK == 0) && (posedge of INDEX))
 *                                                reset to 0 when INDEX_EN[i] is 0
 * SSIF_SWITCH_POS      0X0030        R(BP)   (0X30 ~ 0X3F) JNT_0 ~ JNT_3, HOME-SWITCH-POSITION 
 *                                                          servo: based on ENC_POS
 *                                                          stepper: based on PULSE_POS
 * SSIF_INDEX_POS       0X0040        R(BP)   (0X40 ~ 0X4F) JNT_0 ~ JNT_3, MOTOR-INDEX-POSITION
 *                                                          servo: based on ENC_POS
 *                                                          stepper: based on PULSE_POS
 * RESERVED             0x0050~0x007B
 * SSIF_MAX_PWM         0x007C~0x007F W       (0x7C ~ 0x7F) JNT_0 ~ JNT_3, 8-bits, Max PWM Ratio (Stepper Current Limit)
 *******************************************************************************
 * for 華谷：
 * JNT_0 ~ JNT_2: current limit: 2.12A/phase (DST56EX43A)
 *                set SSIF_MAX_PWM as 180
 * JNT_3:         current limit: 3.0A/phase (DST86EM82A)
 *                set SSIF_MAX_PWM as 255
 *******************************************************************************
 *******************************************************************************
 * @REGISTERS FOR GPIO (Servo/Stepper InterFace)
 *******************************************************************************
 **/

/**
 * refer to stdint.h:
 * The ISO C99 standard specifies that in C++ implementations these
 * macros should only be defined if explicitly requested.
 * the following checking is for C only
 **/
#if !defined __cplusplus
#if !defined(UINT8_MAX) || !defined(UINT16_MAX) || !defined(INT32_MAX)
#error "Must include <inttypes.h> or <stdint.h> before any customized header."
#endif
#endif

// SFIFO register space:
#define SFIFO_BASE        0x9D000000
// offset to SFIFO registers
#define SFIFO_BP_TICK         0x0000  // base period tick
#define SFIFO_CTRL            0x0004  // SFIFO ctrl register
#define SFIFO_DI              0x0008  // SFIFO data input
// masks to SFIFO registers
#define SFIFO_EMPTY_MASK  0x00000001  // 0x0004.0: set to 1 if SFIFO is empty

#endif // __subsoc_regs_h__
