// Mutual exclusion lock.
//extern struct spinlock shared_lock;
struct spinlock {
  uint locked;       // Is the lock held?
  int priority;
  // For debugging:
  char *name;        // Name of lock.
  struct cpu *cpu;   // The cpu holding the lock.
};

