#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#include "model_image.h"

unsigned char* model_image_decode_rgba(
    const unsigned char* encoded,
    size_t encoded_size,
    int* width,
    int* height
) {
    int channels = 0;
    return stbi_load_from_memory(encoded, (int)encoded_size, width, height, &channels, 4);
}

void model_image_free(unsigned char* pixels) {
    stbi_image_free(pixels);
}
