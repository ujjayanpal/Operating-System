
#include <stdio.h>
#include <pthread.h>
#include <string.h>
int n = 1;
int N = 50;
typedef struct __node_t {
    int         key;
    struct __node_t     *next;
} node_t;

typedef struct __list_t {
    node_t      *head;
} list_t;

void List_Init(list_t *L) {
    L->head = NULL;
}

void List_Insert(list_t *L, int key) {
    node_t *new = malloc(sizeof(node_t));
    if (new == NULL) { perror("malloc"); return; }
    new->key  = key;    
    new->next = L->head;
    L->head   = new;
}

int List_Lookup(list_t *L, int key) {
    node_t *tmp = L->head;
    while (tmp) {
    if (tmp->key == key)
        return 1;
    tmp = tmp->next;
    }
    return 0;
}

void List_Print(list_t *L) {
    node_t *tmp = L->head;
    while (tmp) {
    printf("%d ", tmp->key);
    tmp = tmp->next;
    }
    printf("\n");
}
#define FREE        0x0
#define RUNNING     0x1
#define RUNNABLE    0x2

#define STACK_SIZE  8192
#define MAX_THREAD  4
list_t* L;
struct context{
  int ra;
  int sp;

  // callee-saved
  int s0;
  int s1;
  int s2;
  int s3;
  int s4;
  int s5;
  int s6;
  int s7;
  int s8;
  int s9;
  int s10;
  int s11;
};


struct thread {
  char       stack[STACK_SIZE]; /* the thread's stack */
  int        state;             /* FREE, RUNNING, RUNNABLE */
  struct context cntx;
};

struct thread all_thread[MAX_THREAD];
struct thread *current_thread;
//extern void thread_switch(int, int);
              
void 
thread_init(void)
{
  // main() is thread 0, which will make the first invocation to
  // thread_schedule().  it needs a stack so that the first thread_switch() can
  // save thread 0's state.  thread_schedule() won't run the main thread ever
  // again, because its state is set to RUNNING, and thread_schedule() selects
  // a RUNNABLE thread.
  current_thread = &all_thread[0];
  current_thread->state = RUNNING;
  List_Init(L);
}

void 
thread_schedule(void)
{
  struct thread *t, *next_thread;

  /* Find another runnable thread. */
  next_thread = 0;
  t = current_thread + 1;
  for(int i = 0; i < MAX_THREAD; i++){
    if(t >= all_thread + MAX_THREAD)
      t = all_thread;
    if(t->state == RUNNABLE) {
      next_thread = t;
      break;
    }
    t = t + 1;
  }

  if (next_thread == 0) {
    
    //printf("thread_schedule: no runnable threads\n");
  /*for (int ii=0; ii<3; ii++)
  {
    for (int jj=0; jj<3; jj++)
    {
      printf("%d ", C[ii][jj]);
    }
    printf("\n");
  }*/
  List_Print(L);
    exit(-1);
  }

  if (current_thread != next_thread) {         /* switch threads?  */
    next_thread->state = RUNNING;
    t = current_thread;
    current_thread = next_thread;
    /* YOUR CODE HERE
     * Invoke thread_switch to switch from t to next_thread:
     * thread_switch(??, ??);
     */
    //printf("here5\n");
    thread_switch((int)&(t->cntx), (int)&(next_thread->cntx));

  } else
    next_thread = 0;
}

void 
thread_create(void (*func)())
{
  struct thread *t;

  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
    if (t->state == FREE) break;
  }
  t->state = RUNNABLE;
  // YOUR CODE HERE

  memset(&t->cntx, 0, sizeof(t->cntx));
  t->cntx.ra = (int)func;
  t->cntx.sp = (int)(t->stack + STACK_SIZE);
  //printf("here1\n");
  int sp = (int)t->stack + STACK_SIZE;

  sp -= 8;
  *((int*)sp) = (int)func;

  //printf("here2\n");

  sp -= 8;
  *((int*)sp) = 0;

  // t->stack = (char*)sp;
  //printf("here3\n");
  t->stack[STACK_SIZE - 1] = (char)sp;

  //printf("here4\n");
}

void 
thread_yield(void)
{
  current_thread->state = RUNNABLE;
  thread_schedule();
}

volatile int a_started, b_started, c_started;
volatile int a_n, b_n, c_n;

void 
thread_a(void)
{
  int i;
  printf("thread_a started\n");
  a_started = 1;
  while(b_started == 0 || c_started == 0)
    thread_yield();
  
  /*for (i = 0; i < 100; i++) {
    printf("thread_a %d\n", i);
    a_n += 1;
    thread_yield();
  }
  for (i = 0; i < 3; i ++)
  {
    printf("thread a %d\n", A[0][0]*B[0][i] + A[0][1]*B[1][i] + A[0][2]*B[2][i]);
    C[0][i] = A[0][0]*B[0][i] + A[0][1]*B[1][i] + A[0][2]*B[2][i];
    a_n += 1;
    thread_yield();
  }*/
  //printf("thread_a: exit after %d\n", a_n);
  for (i = 1; i <= N; i ++)
  {
     List_Insert(L, i);
  }

  current_thread->state = FREE;
  thread_schedule();
}

void 
thread_b(void)
{
  int i;
  printf("thread_b started\n");
  b_started = 1;
  while(a_started == 0 || c_started == 0)
    thread_yield();
  
  /*for (i = 0; i < 100; i++) {
    printf("thread_b %d\n", i);
    b_n += 1;
    thread_yield();
  }
  for (i = 0; i < 3; i ++)
  {
    printf("thread b %d\n", A[1][0]*B[0][i] + A[1][1]*B[1][i] + A[1][2]*B[2][i]);
    C[1][i] = A[1][0]*B[0][i] + A[1][1]*B[1][i] + A[1][2]*B[2][i];
    b_n += 1;
    thread_yield();
  }*/
  //printf("thread_b: exit after %d\n", b_n);
  for (i = N+1; i <= 2*N; i ++)
  {
     List_Insert(L, i);
  }

  current_thread->state = FREE;
  thread_schedule();
}

/*void 
thread_c(void)
{
  int i;
  printf("thread_c started\n");
  c_started = 1;
  while(a_started == 0 || b_started == 0)
    thread_yield();
  
  /*for (i = 0; i < 100; i++) {
    printf("thread_c %d\n", i);
    c_n += 1;
    thread_yield();
  }
  for (i = 0; i < 3; i ++)
  {
    printf("thread c %d\n", A[2][0]*B[0][i] + A[2][1]*B[1][i] + A[2][2]*B[2][i]);
    C[2][i] = A[2][0]*B[0][i] + A[2][1]*B[1][i] + A[2][2]*B[2][i];
    c_n += 1;
    thread_yield();
  }*/
  //printf("thread_c: exit after %d\n", c_n);

  //current_thread->state = FREE;
  //thread_schedule();
//}*/

int 
main(int argc, char *argv[]) 
{
  a_started = b_started = c_started = 0;
  a_n = b_n = c_n = 0;

  thread_init();
  thread_create(thread_a);
  thread_create(thread_b);
  //thread_create(thread_c);
  thread_schedule();
  /*for (int ii=0; ii<3; ii++)
  {
    for (int jj=0; jj<3; jj++)
    {
      printf("%d", C[ii][jj]);
    }
    printf("\n");
  }*/
return 0;
}
