#include <stdlib.h>
#include <string.h>
#include "general_.h"

static const char ODOMETER_DIGITS[] = "0123456789abcdefghijklmnopqrstuvwxyz";

/*
 * Initialize the odometer for all_words.
 */
void odometer_init(char *word, int n) {
    int i;
    for (i = 0; i < n; i++) {
        word[i] = '0';
    }
}

/*
 * Increment the given string by one.
 */
int odometer_increment(char *word, int n, int base) {
    int i = n - 1;
    int idx;
    while (i >= 0) {
        /* Decode current ASCII digit back to an index to ODOMETER_DIGITS. */
        idx = (word[i] <= '9') ? (word[i] - '0') : (word[i] - 'a' + 10);
        if (idx + 1 < base) {
            word[i] = ODOMETER_DIGITS[idx + 1];
            return 1; // Success.
        }
        word[i] = '0'; // Carry.
        i--;
    }
    return 0; // Overflow: all digits were at maximum.
}

/*
 * Re-layout a transition table from old_A to new_A columns. Allocates a fresh
 * table (cap rows x new_A cols), copies valid rows 0..k. Returns NULL on
 * allocation failure without touching *trans.
 */
int* ff_trans_expand_cols(int *trans, int cap, int old_A, int new_A, int k) {
    int *new_t;
    int s, ol;
    new_t = (int *)malloc((size_t)cap * new_A * sizeof(int));
    if (!new_t) return NULL;
    memset(new_t, 0xFF, (size_t)cap * new_A * sizeof(int));
    for (s = 0; s <= k; s++)
        for (ol = 0; ol < old_A; ol++)
            new_t[s * new_A + ol] = trans[s * old_A + ol];
    free(trans);
    return new_t;
}

/*
 * Extend the transition table from old_cap to new_cap rows via realloc.
 * Initialises new rows with value -1. Returns the (possibly moved) pointer, or
 * NULL on failure (old pointer valid).
 */
int* ff_trans_expand_rows(int *trans, int old_cap, int new_cap, int A) {
    int *new_t = (int *)realloc(trans, (size_t)new_cap * A * sizeof(int));
    if (!new_t) return NULL;
    memset(new_t + old_cap * A, 0xFF, (size_t)(new_cap - old_cap) * A * sizeof(int));
    return new_t;
}
