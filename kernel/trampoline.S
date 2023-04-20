	#
        # code to switch between user and kernel space.
        #
        # this code is mapped at the same virtual address
        # (TRAMPOLINE) in user and kernel space so that
        # it continues to work when it switches page tables.
	#
	# kernel.ld causes this to be aligned
        # to a page boundary.
        #
	.section trampsec
.globl trampoline
trampoline:
.align 4
.globl uservec
uservec:
	#
        // 来自用户空间的trap的处理路径 uservec
        # trap.c sets stvec to point here, so
        # traps from user space start here,
        # in supervisor mode, but with a
        # user page table.
        #
        # sscratch points to where the process's p->trapframe is
        # mapped into user space, at TRAPFRAME.
        #
        
	# swap a0 and sscratch
        # so that a0 is TRAPFRAME
        // sscratch寄存器存放处理程序开始时可以使用的值,现在进行和a0交换,也就是a0保存了这个值
        csrrw a0, sscratch, a0

        # save the user registers in TRAPFRAME
        sd ra, 40(a0)
        sd sp, 48(a0)
        sd gp, 56(a0)
        sd tp, 64(a0)
        sd t0, 72(a0)
        sd t1, 80(a0)
        sd t2, 88(a0)
        sd s0, 96(a0)
        sd s1, 104(a0)
        sd a1, 120(a0)
        sd a2, 128(a0)
        sd a3, 136(a0)
        sd a4, 144(a0)
        sd a5, 152(a0)
        sd a6, 160(a0)
        sd a7, 168(a0)
        sd s2, 176(a0)
        sd s3, 184(a0)
        sd s4, 192(a0)
        sd s5, 200(a0)
        sd s6, 208(a0)
        sd s7, 216(a0)
        sd s8, 224(a0)
        sd s9, 232(a0)
        sd s10, 240(a0)
        sd s11, 248(a0)
        sd t3, 256(a0)
        sd t4, 264(a0)
        sd t5, 272(a0)
        sd t6, 280(a0)

	# save the user a0 in p->trapframe->a0
        csrr t0, sscratch
        sd t0, 112(a0)

        # restore kernel stack pointer from p->trapframe->kernel_sp
        ld sp, 8(a0)

        // tp是保存了现在是使用cpu第几个核的数字
        # make tp hold the current hartid, from p->trapframe->kernel_hartid
        ld tp, 32(a0)
        // t0保存处理用户trap的函数的地址，也就是usertrap
        # load the address of usertrap(), p->trapframe->kernel_trap
        ld t0, 16(a0)

        # restore kernel page table from p->trapframe->kernel_satp
        // 向t1寄存器写入内核页表的地址
        // satp切换到内核页表,刷新TLB
 8        ld t1, 0(a0)
        csrw satp, t1
        sfence.vma zero, zero

        # a0 is no longer valid, since the kernel page
        # table does not specially map p->tf.
        // 跳转到t0寄存器的地址，t0寄存器在上面保存了usertrap函数的地址，所以开始执行这个函数。
        # jump to usertrap(), which does not return
        jr t0

.globl userret
userret:
        // 用户空间trap的过程 trampoline.S(16:uservec) -> usertrap(kernel/trap.c:37) -> userret
        # userret(TRAPFRAME, pagetable)
        # switch from kernel to user.
        # usertrapret() calls here.
        # a0: TRAPFRAME, in user page table.
        # a1: user page table, for satp.

        # switch to the user page table.
        // 切换位用户页表
        csrw satp, a1
        // 刷新TLB
        sfence.vma zero, zero

        # put the saved user a0 in sscratch, so we
        # can swap it with our a0 (TRAPFRAME) in the last step.
        // 交换a0核sscratch寄存器，sscratch又保存回trampoline的地址了
        //
        ld t0, 112(a0)
        csrw sscratch, t0

        # restore all but a0 from TRAPFRAME
        ld ra, 40(a0)
        ld sp, 48(a0)
        ld gp, 56(a0)
        ld tp, 64(a0)
        ld t0, 72(a0)
        ld t1, 80(a0)
        ld t2, 88(a0)
        ld s0, 96(a0)
        ld s1, 104(a0)
        ld a1, 120(a0)
        ld a2, 128(a0)
        ld a3, 136(a0)
        ld a4, 144(a0)
        ld a5, 152(a0)
        ld a6, 160(a0)
        ld a7, 168(a0)
        ld s2, 176(a0)
        ld s3, 184(a0)
        ld s4, 192(a0)
        ld s5, 200(a0)
        ld s6, 208(a0)
        ld s7, 216(a0)
        ld s8, 224(a0)
        ld s9, 232(a0)
        ld s10, 240(a0)
        ld s11, 248(a0)
        ld t3, 256(a0)
        ld t4, 264(a0)
        ld t5, 272(a0)
        ld t6, 280(a0)

    // 每次返回前会将trapframe page的地址存放回sscratch地址，下次中断又会把地址交换到a0
	# restore user a0, and save TRAPFRAME in sscratch
    // 交换之后a0的值是系统调用的返回值，sscratch是之前的trampoline的地址。
        csrrw a0, sscratch, a0
        
        # return to user mode and user pc.
        # usertrapret() set up sstatus and sepc.
        // return user sapce
        // 程序切换回user mode
        // sepc寄存器的数值会还原给pc，sepc是之前保存user进入中断的地址
        // 打开中断，等待下一次中断。
        //在sh.asm中可以看到，这指令是ret指令
        sret
