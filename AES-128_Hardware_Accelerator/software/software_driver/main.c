#include <string.h>
#include "aes_ctr.h"
#include "xil_printf.h"
#include "platform.h"
#include "xparameters.h"
#include "xil_io.h"
#include "xtmrctr.h"

#define TIMER_DEVICE_ID 0
#define FREQ_MHZ        100U

#define IMG_BUFFER      0x10100000
#define ENC_BUFFER      0x12100000
#define DEC_BUFFER      0x14100000
#define STATUS_ADDR     0x10008000
#define IMG_SIZE_ADDR   0x10008004

#define STATUS_RUNNING  0x00000001
#define STATUS_ENC_DONE 0x00000002
#define STATUS_DEC_DONE 0x00000003
#define STATUS_DONE     0x00000004

static const uint8_t KEY[16] = {
    0x2b,0x7e,0x15,0x16, 0x28,0xae,0xd2,0xa6,
    0xab,0xf7,0x15,0x88, 0x09,0xcf,0x4f,0x3c
};
static const uint8_t COUNTER[16] = {
    0xf0,0xf1,0xf2,0xf3, 0xf4,0xf5,0xf6,0xf7,
    0xf8,0xf9,0xfa,0xfb, 0xfc,0xfd,0xfe,0xff
};

static void print_timing(const char *label, uint32_t cycles)
{
    uint32_t us  = cycles / FREQ_MHZ;
    uint32_t ms  = us / 1000U;
    uint32_t ms_f = us % 1000U;
    xil_printf("  %-24s %u cycles = %u.%03u ms\r\n",
               label, cycles, ms, ms_f);
}

int main()
{
    init_platform();

    XTmrCtr timer;
    Xil_Out32(STATUS_ADDR, STATUS_RUNNING);

    uint32_t img_size = Xil_In32(IMG_SIZE_ADDR);

    xil_printf("\r\nAES-128 CTR Software Encryption\r\n");
    xil_printf("Image: %u bytes\r\n", img_size);

    XTmrCtr_Initialize(&timer, TIMER_DEVICE_ID);

    uint8_t *img = (uint8_t *)IMG_BUFFER;
    uint8_t *enc = (uint8_t *)ENC_BUFFER;
    uint8_t *dec = (uint8_t *)DEC_BUFFER;

    // Encrypt
    xil_printf("Encrypting...\r\n");
    memcpy(enc, img, img_size);
    uint8_t enc_nonce[16];
    memcpy(enc_nonce, COUNTER, 16);

    XTmrCtr_Reset(&timer, 0);
    XTmrCtr_Start(&timer, 0);
    uint32_t enc_start = XTmrCtr_GetValue(&timer, 0);
    aes_ctr_xcrypt(enc, img_size, (uint8_t *)KEY, enc_nonce);
    uint32_t enc_cycles = XTmrCtr_GetValue(&timer, 0) - enc_start;
    XTmrCtr_Stop(&timer, 0);
    Xil_Out32(STATUS_ADDR, STATUS_ENC_DONE);
    print_timing("Encryption:", enc_cycles);

    // Decrypt
    xil_printf("Decrypting...\r\n");
    memcpy(dec, enc, img_size);
    uint8_t dec_nonce[16];
    memcpy(dec_nonce, COUNTER, 16);

    XTmrCtr_Reset(&timer, 0);
    XTmrCtr_Start(&timer, 0);
    uint32_t dec_start = XTmrCtr_GetValue(&timer, 0);
    aes_ctr_xcrypt(dec, img_size, (uint8_t *)KEY, dec_nonce);
    uint32_t dec_cycles = XTmrCtr_GetValue(&timer, 0) - dec_start;
    XTmrCtr_Stop(&timer, 0);
    Xil_Out32(STATUS_ADDR, STATUS_DEC_DONE);
    print_timing("Decryption:", dec_cycles);

    // Throughput
    uint32_t enc_us = enc_cycles / FREQ_MHZ;
    if (enc_us > 0U)
        xil_printf("  Throughput: %u KB/s\r\n",
                   (img_size / 1024U * 1000U) / enc_us);
    xil_printf("  Cycles/byte:  %u\r\n", enc_cycles / img_size);
    xil_printf("  Cycles/block: %u\r\n", enc_cycles / (img_size / 16U));

    xil_printf("Done\r\n");
    Xil_Out32(STATUS_ADDR, STATUS_DONE);

    cleanup_platform();
    return 0;
}