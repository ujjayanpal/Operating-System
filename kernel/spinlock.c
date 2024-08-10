// Mutual exclusion spin locks.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "proc.h"
#include "defs.h"

//struct spinlock shared_lock;
void
initlock(struct spinlock *lk, char *name)
{
  lk->name = name;
  lk->locked = 0;
  lk->cpu = 0;
  lk->priority = 1;
}

// Acquire the lock.
// Loops (spins) until the lock is acquired.
/*void
acquire(struct spinlock *lk)
{
  push_off(); // disable interrupts to avoid deadlock.
  if(holding(lk))
    panic("acquire");

  // On RISC-V, sync_lock_test_and_set turns into an atomic swap:
  //   a5 = 1
  //   s1 = &lk->locked
  //   amoswap.w.aq a5, a5, (s1)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    ;

  //lk->priority = -1;
  //getcallerpcs(&lk, lk->pcs);
  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that the critical section's memory
  // references happen strictly after the lock is acquired.
  // On RISC-V, this emits a fence instruction.
  __sync_synchronize();

  // Record info about lock acquisition for holding() and debugging.
  lk->cpu = mycpu();
}*/

void
acquire(struct spinlock *lk)
{
  push_off(); // Disable interrupts to avoid deadlock.
  if(holding(lk))
    {panic("acquire"); lk->priority = 0;}

  int priority = (myproc()->lock).priority;

  // Spinlock acquisition logic
  while (1) {
    // Read the current value of lk->locked atomically
    int old_value = __sync_val_compare_and_swap(&lk->locked, 0, 1);

    if (old_value == 0 || priority < lk->priority) {
      // Lock is acquired or current thread has higher priority
      lk->priority = priority; // Update the lock's priority
      __sync_synchronize(); // Ensure memory ordering
      break;
    } else {
      // Put the current thread to sleep
      sleep(lk, lk);
    }
  }
  //lk->priority = priority;
  // Record info about lock acquisition for holding() and debugging.
  lk->cpu = mycpu();
}

// Release the lock.
/*void
release(struct spinlock *lk)
{
  if(!holding(lk))
    panic("release");

  lk->cpu = 0;

  // Tell the C compiler and the CPU to not move loads or stores
  // past this point, to ensure that all the stores in the critical
  // section are visible to other CPUs before the lock is released,
  // and that loads in the critical section occur strictly before
  // the lock is released.
  // On RISC-V, this emits a fence instruction.
  __sync_synchronize();

  // Release the lock, equivalent to lk->locked = 0.
  // This code doesn't use a C assignment, since the C standard
  // implies that an assignment might be implemented with
  // multiple store instructions.
  // On RISC-V, sync_lock_release turns into an atomic swap:
  //   s1 = &lk->locked
  //   amoswap.w zero, zero, (s1)
  __sync_lock_release(&lk->locked);

  pop_off();
}*/

void
release(struct spinlock *lk)
{
    if (!holding(lk))
        panic("release");

    // Reset the lock's priority
    lk->priority = -1;

    // Wake up higher-priority waiters
    wakeup(lk);

    // Release the lock
    __sync_lock_release(&lk->locked);

    pop_off();
}

// Check whether this cpu is holding the lock.
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
  return r;
}

// push_off/pop_off are like intr_off()/intr_on() except that they are matched:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    mycpu()->intena = old;
  mycpu()->noff += 1;
}

void
pop_off(void)
{
  struct cpu *c = mycpu();
  if(intr_get())
    panic("pop_off - interruptible");
  if(c->noff < 1)
    panic("pop_off");
  c->noff -= 1;
  if(c->noff == 0 && c->intena)
    intr_on();
}
