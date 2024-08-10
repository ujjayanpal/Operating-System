#include "types.h"
#include "stat.h"
#include "user.h"
#include "spinlock.h"

// Number of times each contender will try to acquire the lock
#define NUM_ACQUIRE_ATTEMPTS 3

void contender(int id) {
    int priority = 100 - id; // Initial priority

    for (int i = 0; i < NUM_ACQUIRE_ATTEMPTS; i++) {
        printf(1, "Contender %d trying to acquire with priority %d\n", id, priority);
        acquire_priority(&shared_lock, priority);

        // Simulate some work
        for (volatile int j = 0; j < 1000000; j++) ;

        // Release the lock
        release(&shared_lock);

        priority--; // Decrease priority
    }

    exit(0);
}

int main() {
    // Initialize the shared lock
    initlock(&shared_lock, "shared_lock");

    for (int i = 0; i < 7; i++) {
        int pid = fork();
        if (pid == 0) {
            contender(i);
        }
    }

    for (int i = 0; i < 7; i++) {
        wait(0);
    }

    printf(1, "All contenders have finished\n");

    exit(0);
}