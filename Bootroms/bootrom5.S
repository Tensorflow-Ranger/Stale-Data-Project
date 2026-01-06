# Bootrom for kernel context switch. Same as boorom4 but traps delegated to S mode.
.option norvc
.section .text.start
.globl _start

_start:
    # 1) Open PMP: allow RWX everywhere
    # This acts as the "Master Permission" to ensure User Mode can see memory.
    li t0, 0x20000000      # 0x80000000 >> 2 
    csrw pmpaddr0, t0      # Set lower bound

    li t0, 0x3FFFFFFF      # 0xFFFFFFFF >> 2 (approx top of 32-bit space)
    csrw pmpaddr1, t0      # Set upper bound

    li t0, 0x0F00          # PMP1=0x0F (TOR, RWX, L=0), PMP0=0 (OFF)
    csrw pmpcfg0, t0

    # 3) satp = 0
    # Problem: The MMU might have old "translation maps" active.
    # Solution: Disabling satp ensures we are in "Bare Metal" mode.
    # Virtual Address 0x80000000 is now exactly Physical Address 0x80000000.
    csrwi satp, 0

    csrwi mstatus, 0

    csrr t0, mie
    csrr t1, mip
    csrw mie, zero

    csrr t0, mstatus
    li   t1, (1 << 11)
    or   t0, t0, t1
    csrw mstatus, t0

#    delegates it to S mode 
    li   t0, 0xB1FF
    csrw medeleg, t0
    li   t0, 0x222
    csrw mideleg, t0

    # Set kernel entry point
    # We tell the CPU where to start once we "return" from Machine Mode.
    li   t0, 0x80000000