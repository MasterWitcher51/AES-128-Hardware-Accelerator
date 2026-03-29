#include <string.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xil_printf.h"

// Hardware Addresses
#define AES_BASE_ADDR   XPAR_AES_AXI_CORE_0_BASEADDR
#define DMA_BASE_ADDR   XPAR_XAXIDMA_0_BASEADDR

// AES AXI-Lite Register Offsets
#define AES_REG_KEY0    0x00
#define AES_REG_KEY1    0x04
#define AES_REG_KEY2    0x08
#define AES_REG_KEY3    0x0C
#define AES_REG_CTR0    0x10
#define AES_REG_CTR1    0x14
#define AES_REG_CTR2    0x18
#define AES_REG_CTR3    0x1C

// DMA Register Offsets
#define DMA_MM2S_CR     0x00
#define DMA_MM2S_SR     0x04
#define DMA_MM2S_SA     0x18
#define DMA_MM2S_LENGTH 0x28
#define DMA_S2MM_CR     0x30
#define DMA_S2MM_SR     0x34
#define DMA_S2MM_DA     0x48
#define DMA_S2MM_LENGTH 0x58

// DDR Buffers
#define SRC_BUFFER      0x10001000
#define DST_BUFFER      0x10002000
#define IMG_BUFFER      0x10100000
#define ENC_BUFFER      0x12100000
#define DEC_BUFFER      0x14100000

// Status
#define STATUS_ADDR     0x10008000
#define IMG_SIZE_ADDR   0x10008004
#define STATUS_RUNNING  0x00000001
#define STATUS_ENC_DONE 0x00000002
#define STATUS_DEC_DONE 0x00000003
#define STATUS_DONE     0x00000004

#define BLOCK_SIZE      16

// AES Key and Nonce — NIST AES-128 CTR test values
static const u32 aes_key[4]   = {0x2b7e1516, 0x28aed2a6,
                                  0xabf71588, 0x09cf4f3c};
static const u32 aes_nonce[4] = {0xf0f1f2f3, 0xf4f5f6f7,
                                  0xf8f9fafb, 0xfcfdfeff};

// Encrypt one 16-byte block via DMA
static void hw_encrypt_block(const u8 plain[16],
                              u8 cipher[16],
                              u32 block_num)
{
    volatile u32 *src = (volatile u32 *)SRC_BUFFER;
    volatile u32 *dst = (volatile u32 *)DST_BUFFER;

    // Write key and counter
    Xil_Out32(AES_BASE_ADDR + AES_REG_KEY0, aes_key[0]);
    Xil_Out32(AES_BASE_ADDR + AES_REG_KEY1, aes_key[1]);
    Xil_Out32(AES_BASE_ADDR + AES_REG_KEY2, aes_key[2]);
    Xil_Out32(AES_BASE_ADDR + AES_REG_KEY3, aes_key[3]);
    Xil_Out32(AES_BASE_ADDR + AES_REG_CTR0, aes_nonce[0]);
    Xil_Out32(AES_BASE_ADDR + AES_REG_CTR1, aes_nonce[1]);
    Xil_Out32(AES_BASE_ADDR + AES_REG_CTR2, aes_nonce[2]);
    Xil_Out32(AES_BASE_ADDR + AES_REG_CTR3, aes_nonce[3] + block_num);

    for (volatile int i = 0; i < 1000; i++);

    // Pack bytes into 32-bit words big-endian
    for (int w = 0; w < 4; w++)
        src[w] = ((u32)plain[w*4+0] << 24) | ((u32)plain[w*4+1] << 16) |
                 ((u32)plain[w*4+2] <<  8) | ((u32)plain[w*4+3]);

    // Arm S2MM then trigger MM2S
    Xil_Out32(DMA_BASE_ADDR + DMA_S2MM_CR,     0x1);
    Xil_Out32(DMA_BASE_ADDR + DMA_S2MM_DA,     DST_BUFFER);
    Xil_Out32(DMA_BASE_ADDR + DMA_S2MM_LENGTH, BLOCK_SIZE);
    Xil_Out32(DMA_BASE_ADDR + DMA_MM2S_CR,     0x1);
    Xil_Out32(DMA_BASE_ADDR + DMA_MM2S_SA,     SRC_BUFFER);
    Xil_Out32(DMA_BASE_ADDR + DMA_MM2S_LENGTH, BLOCK_SIZE);

    // Poll for completion
    while (!(Xil_In32(DMA_BASE_ADDR + DMA_MM2S_SR) & 0x2));
    while (!(Xil_In32(DMA_BASE_ADDR + DMA_S2MM_SR) & 0x2));

    // Unpack bytes from 32-bit words big-endian
    for (int w = 0; w < 4; w++) {
        u32 word = dst[w];
        cipher[w*4+0] = (u8)(word >> 24);
        cipher[w*4+1] = (u8)(word >> 16);
        cipher[w*4+2] = (u8)(word >>  8);
        cipher[w*4+3] = (u8)(word);
    }
}

// Process full image block by block
static void hw_process_image(const u8 *in, u8 *out,
                              u32 size, const char *label)
{
    u32 blocks = size / BLOCK_SIZE;
    xil_printf("%s: %u blocks\r\n", label, (unsigned int)blocks);
    for (u32 b = 0; b < blocks; b++){
    hw_encrypt_block(in + b * BLOCK_SIZE,out + b * BLOCK_SIZE, b);
    }
    xil_printf("%s: done\r\n", label);
}

int main()
{
    Xil_Out32(STATUS_ADDR, STATUS_RUNNING);

    u32 image_size = Xil_In32(IMG_SIZE_ADDR);

    xil_printf("\r\nAES-128 CTR Hardware Encryption\r\n");
    xil_printf("Image: %u bytes\r\n", (unsigned int)image_size);

    // Encrypt
    hw_process_image((u8 *)IMG_BUFFER, (u8 *)ENC_BUFFER,image_size, "Encrypt");
    Xil_Out32(STATUS_ADDR, STATUS_ENC_DONE);

    // Decrypt
    hw_process_image((u8 *)ENC_BUFFER, (u8 *)DEC_BUFFER,image_size, "Decrypt");
    Xil_Out32(STATUS_ADDR, STATUS_DEC_DONE);

    xil_printf("Done — TCL can read ENC and DEC\r\n");
    Xil_Out32(STATUS_ADDR, STATUS_DONE);

    while(1);
}