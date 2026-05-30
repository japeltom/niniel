#ifndef G_GENERAL
#define G_GENERAL

void odometer_init(char *word, int n);
int odometer_increment(char *word, int n, int base);
int* ff_trans_expand_cols(int *trans, int cap, int old_A, int new_A, int k);
int* ff_trans_expand_rows(int *trans, int old_cap, int new_cap, int A);
#endif

