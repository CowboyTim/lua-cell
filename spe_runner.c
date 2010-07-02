#include <spu_mfcio.h>

int main(unsigned long long spe, unsigned long long argp, unsigned long long envp) {
    int i;
    while (1) {
        i = spu_read_in_mbox();
        i = i + 10;
        spu_write_out_intr_mbox(i);
    }
    return 0;
}
