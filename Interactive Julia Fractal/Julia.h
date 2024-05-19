#ifndef GENERATE_FRACTAL
#define GENERATE_FRACTAL
#include <stdint.h>


void GenerateFractal(uint8_t *pixels, int width, int height, double escapeRadius, double cReal, double cImag, double centerReal, double centerImag, double zoom, int *colors, int colored);

#endif 