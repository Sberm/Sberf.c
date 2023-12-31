/*-*- coding:utf-8                                                          -*-│
│vi: set net ft=c ts=2 sts=2 sw=2 fenc=utf-8                                :vi│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2023 Howard Chu                                                    │
│                                                                              │
│ Permission to use, copy, modify, and/or distribute this software for         │
│ any purpose with or without fee is hereby granted, provided that the         │
│ above copyright notice and this permission notice appear in all copies.      │
│                                                                              │
│ THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL                │
│ WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED                │
│ WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE             │
│ AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL         │
│ DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR        │
│ PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER               │
│ TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR             │
│ PERFORMANCE OF THIS SOFTWARE.                                                │
╚─────────────────────────────────────────────────────────────────────────────*/

#include <linux/bpf.h>
#include <linux/bpf_common.h>
#include <bpf/bpf_helpers.h>

char LICENSE[] SEC("license") = "Dual BSD/GPL";

int my_pid = 0;
const int size = 1024;
char buf[size];

/** @brief
 *  
 *  This is a function that does...
 *  
 *  @param void* ctx
 *  The context of eBPF program.
 *  
 *  @return int
 */

SEC("tp/syscalls/sys_enter_write")
int handle_tp(void *ctx)
{
    int pid = bpf_get_current_pid_tgid() >> 32;
	int debug = bpf_get_current_pid_tgid() & -1;

	if (pid != my_pid)
		return 0;

	bpf_printk("BPF triggered from PID %d.\n, debug merry lunar new year!! %d", pid, debug);

	int r = bpf_get_stack(ctx, &buf, size, BPF_F_USER_STACK);
	bpf_printk("this is suppose to be stack traces, length of %d: ", r);
	bpf_printk("%s\n", buf);
	return 0;
}
