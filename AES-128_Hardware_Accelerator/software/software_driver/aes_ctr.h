#ifndef AES_CTR_H
#define AES_CTR_H

#include <stdint.h>
#include <stddef.h>
// AES CTR mode encryption/decryption
// This implementation is based on the AES block cipher and uses a counter (CTR) mode of operation.
// data: This is the plaintext/input
// key: This is a pointer to the AES key 
// data_len: This is the length of the plaintext/input in bytes
// nonce:  This is the counter value used for encryption/decryption. It should be unique for each encryption operation with the same key.
// output: This is a pointer to the buffer where the ciphertext will be stored.

void aes_ctr_xcrypt(uint8_t *data, size_t len, const uint8_t key[16], uint8_t nonce[16]);

#endif