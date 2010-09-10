#include <stdint.h>
#include "subsoc.h"
#include "subsoc_regs.h"

uint8_t sfifo_bp_tick (void)
{
    return REG8(SFIFO_BASE + SFIFO_BP_TICK);
}

// vim:sw=4:sts=4:et:
