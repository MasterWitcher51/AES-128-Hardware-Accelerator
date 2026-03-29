"""
This is a python implementation of the AES-128 Algorithm before doing it in hardware
"""
from PIL import Image
import io
import time

S_BOX = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
]

RCON = [0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x1B,0x36]


## Main Steps
def sub_bytes(state):
    for i in range(4):
        for j in range(4):
           state[i][j] = S_BOX[state[i][j]]


def shift_rows(state):
    state[1][0], state[1][1], state[1][2], state[1][3] = state[1][1], state[1][2], state[1][3], state[1][0] # Shift by 1
    state[2][0], state[2][1], state[2][2], state[2][3] = state[2][2], state[2][3], state[2][0], state[2][1] # Shift by 2
    state[3][0], state[3][1], state[3][2], state[3][3] = state[3][3], state[3][0], state[3][1], state[3][2] # shift by 3

def xtime(a):
    return ((a << 1) ^ 0x1B) & 0xFF if (a & 0x80) else (a << 1)
 
def mix_single_column(a):
    t = a[0] ^ a[1] ^ a[2] ^ a[3]
    u = a[0]
    a[0] ^= t ^ xtime(a[0] ^ a[1])
    a[1] ^= t ^ xtime(a[1] ^ a[2])
    a[2] ^= t ^ xtime(a[2] ^ a[3])
    a[3] ^= t ^ xtime(a[3] ^ u)

def mix_all_columns(state):
     for j in range(4):
          column = [state[0][j], state[1][j], state[2][j],state[3][j]]
          mix_single_column(column)
          for i in range(4):
              state[i][j] = column[i]

def add_round_key(state,k):
    for i in range(4):
        for j in range(4):
            state[i][j]^=k[i][j]

def rot_word(word):
    return word[1:] + word[:1]

def sub_word(word):
    return [S_BOX[b] for b in word]

def key_expansion(key_bytes):
    # key_bytes: 16-byte list
    w = [key_bytes[i:i+4] for i in range(0, 16, 4)]  # initial 4 words

    for i in range(4, 44):  # 44 words total
        temp = w[i-1][:]
        if i % 4 == 0:
            temp = sub_word(rot_word(temp))
            temp[0] ^= RCON[(i//4) - 1]
        new_word = [w[i-4][j] ^ temp[j] for j in range(4)]
        w.append(new_word)

    # group into round keys (each is 4x4 matrix)
    round_keys = []
    for i in range(0, 44, 4):
        round_key = [[w[i][j], w[i+1][j], w[i+2][j], w[i+3][j]] for j in range(4)]
        round_keys.append(round_key)
    return round_keys
        
def aes_encrypt(plaintext_bytes, key_bytes):
    # Convert plaintext to 4x4 state matrix
    state = [[plaintext_bytes[r + 4*c] for c in range(4)] for r in range(4)]

    # Generate round keys
    round_keys = key_expansion(key_bytes)

    # Initial AddRoundKey
    add_round_key(state, round_keys[0])

    # 9 main rounds
    for round in range(1, 10):
        sub_bytes(state)
        shift_rows(state)
        mix_all_columns(state)
        add_round_key(state, round_keys[round])
        if round == 10:
             # Final round (without MixColumns)
             sub_bytes(state)
             shift_rows(state)
             add_round_key(state, round_keys[10])



    # Flatten state matrix to list
    ciphertext = [state[r][c] for c in range(4) for r in range(4)]
    return ciphertext

def time_function(func, *args):
    start_time = time.time()
    result = func(*args)
    end_time = time.time()
    elapsed_time = end_time - start_time
    return result, elapsed_time
def increment_counter(counter):
    for i in range(15, -1, -1):
        if counter[i] < 0xFF:
            counter[i] += 1
            break
        else:
            counter[i] = 0

def aes_ctr_transform(data, key, nonce):
    counter = list(nonce)
    result = []
    
    for i in range(0, len(data), 16):
        # 1. Encrypt the counter block
        keystream_block = aes_encrypt(counter, key)
        
        # 2. XOR data with keystream
        chunk = data[i : i + 16]
        for j in range(len(chunk)):
            result.append(chunk[j] ^ keystream_block[j])
        
        # 3. Increment counter for the next 16-byte block
        increment_counter(counter)
        
    return result

def process_image_aes(image_path, key, nonce, output_path):
    # 1. Load the image
    img = Image.open(image_path)
    img = img.convert("RGB")  # Ensure consistent color format
    width, height = img.size
    
    # 2. Convert pixels to a flat list of bytes
    # Each pixel has 3 bytes (R, G, B)
    raw_data = list(img.tobytes())
    print(f"Image loaded: {width}x{height} ({len(raw_data)} bytes)")

    # 3. Encrypt/Decrypt using your CTR transform
    print("Processing AES CTR Transform...")
    start_time = time.time()
    processed_data = aes_ctr_transform(raw_data, key, nonce)
    end_time = time.time()
    
    print(f"Processing Time: {end_time - start_time:.2f} seconds")

    # 4. Convert bytes back to an image
    # Note: processed_data must be converted back to 'bytes' type for Pillow
    output_img = Image.frombytes("RGB", (width, height), bytes(processed_data))
    output_img.save(output_path)
    print(f"Saved result to: {output_path}")

# --- Execution for Images ---

if __name__ == "__main__":
    # Standard AES-128 Key and Nonce
    key = [0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c]
    nonce = [0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff]
    
    # Path to your image
    input_image = "Proclamation-1916.jpg"    # Change filename for different images
    encrypted_image = "encrypted.png"
    decrypted_image = "decrypted.png"

    try:
        # ENCRYPT the image
        print("--- Encryption Phase ---")
        process_image_aes(input_image, key, nonce, encrypted_image)

        # DECRYPT the image 
        print("\n--- Decryption Phase ---")
        process_image_aes(encrypted_image, key, nonce, decrypted_image)
        
        print("\nImage processing complete. Check your folder for results.")
        
    except FileNotFoundError:
        print(f"Error: Could not find '{input_image}'. Please ensure the image exists.")