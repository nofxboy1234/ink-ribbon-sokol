#ifndef MODEL_IMAGE_H
#define MODEL_IMAGE_H

#include <stddef.h>

unsigned char* model_image_decode_rgba(
    const unsigned char* encoded,
    size_t encoded_size,
    int* width,
    int* height
);
void model_image_free(unsigned char* pixels);

#endif
